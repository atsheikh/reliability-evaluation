#! /usr/bin/perl 
use List::Util qw(shuffle);

#************************************************************************
#                                                                       *
#   Perl file to execute the spice file after faults injection          *
#											                            *
#																		*
#	August 31, 2014                                                       *
#   Author: Ahmad Tariq Sheikh (KFUPM)									*
#************************************************************************

my $USAGE = <<EOU;
USAGE: $0 input
      Executes the SPICE model file after fault injection and creates *_f.out file:
      - input_exec.sp   : file containng the module to be simulated 
      - faults : number of faults to be injected
	  - nt: number of mosfets	  
EOU

die $USAGE unless scalar @ARGV;

$circuit=$ARGV[0];
$faults=$ARGV[1];
$nt=$ARGV[2];
$area=$ARGV[3];

$vdd = 1.3;

open(IN,"$circuit"."_exec.sp") || die " Cannot open input file $circuit".".sp \n";
open(OUT,">$circuit"."f_exec.sp") || die " Cannot open output file $circuit"."f_exec.sp \n";

$fileName = $circuit."f.DEBUG";
open(OUT2,">>$fileName") || die " Cannot open input file $circuit"."f.debug \n";


#################################################################
#	Function to compute current injection from a given charge	#
#	value using the double exponential current calculation 		#
#	formula.
#################################################################
sub computeCurrent {
	my $charge = $_[0]; # charge value
	
	my $tau_f	=	0.2e-9; 
	my $tau_r	=	0.05e-9; 
	my $pwl = ();
	my $Q = 0;
	
	
	# Scale the charge values
	if($charge =~ m/pC/) { #scale pico by multiplying by 10^-12
		( $temp ) = $charge =~ m{(\d+\.\d+)};
		$Q = $temp*1e-12; 		
	}
	elsif($charge =~ m/fC/) { #scale femto by multiplying by 10^-15
		( $temp ) = $charge =~ m{(\d+\.\d+)};
		$Q = $temp*1e-15;
	}
		
	my $T = $tau_f - $tau_r;	
	my @time = ();
	my @current_I = ();
	
	# open (NUM, ">num.txt") or die $!;
	
	for ($i = 0; $i <= 2.01; $i += 0.01) {
		my $temp = (int(($i * 100.0) + 0.5) / 100.0);
		push @time, $temp;		
	}
	
	# print "Time = @time \n";
		
	foreach $time1 (@time) {
		my $temp = $Q/$T * (exp(-($time1*1e-9)/$tau_f) - exp(-($time1*1e-9)/$tau_r));
		# my $temp = $Q/$tau_f * sqrt(($time1*1e-9)/$tau_f) * exp(-$time1*1e-9/$tau_r);
		push @current_I, $temp;		
	}	
	
	$pwl = "pwl(";
	for ($i = 0; $i <= scalar @current_I; $i += 4) {
		$pwl .= ($time[$i]+2)."n,".(int(($current_I[$i] * 1000000000.0) + 0.5) / 1000000.0)."m "; 		
		
		# print NUM (int(($current_I[$i] * 1000000000.0) + 0.5) / 1000000.0),"\n";
		
	}
	$pwl .= ")";
	
	
	# close(NUM);
	return $pwl;
}

##########################################################################
# generate n fault injection sites										 #
##########################################################################
print "---Computing $faults Random locations for fault injection..\n";

#################################################
# Fault injection based on roulette wheel		#
# algorithm. Trans. is selected based on its	#
# drain area.									#
#################################################

# read the area file
@area_cdf = ();
open(IN_AREA,"tranarea.DAT") || die " Cannot open input file tranarea.DAT \n";
while(<IN_AREA>) {
	@row = split(" ", $_);
	push @area_cdf, $row[1];
}
close(IN_AREA);

for ($i=1; $i <= $faults; $i++) {

	do {
		$rn =  rand(1)*$area;
		( $index )= grep { $area_cdf[$_] >= $rn } 0..$#area_cdf;
		$index++;				
	}while(grep $_ eq $index, @randLocations);
	
	push @randLocations, $index;		
	# print "RN = $rn, Index = $index, @randLocations\n"; 
}
@randLocations = sort {$a <=> $b} @randLocations;
# print "Rand Locations: @randLocations\nArea = $area\n";

#####################################################
# Random fault injection							#
#####################################################
# my @randLocations  = qw(11 12);
# @randLocations= shuffle shuffle @randLocations;
# @randLocations = @randLocations[0..$faults - 1];

# # sort numerically ascending
# @randLocations = sort {$a <=> $b} @randLocations;
# @randLocations  = (20);
$charge = "0.3pC";
# print "---Rand Locations = @randLocations\n";	

#----------------------------------------
#   Reading the _exec.sp spice file and
#	injecting the faults.
#---------------------------------------
$errorCount = 0;
$mosfetCount = 0;
@outputs = ();


while(<IN>){	
	
	# Matching Outputs
	if (/OUTPUTS/) {
		@outputs = split(" ", $_);
		shift(@outputs);		
		print OUT $_;
     }	
	elsif (/\*N/) {
		
		# @gateList = ($_ =~ m/(\w+\d)/g);			#Read All the Gates
		# @gateName = ($_ =~ m/(\w+)\(/i);	 #Read the gate Name i.e. NAND	
		
		my @gateList = ($_ =~ m/(\w+)/g);				
		$gateName[0] = $gateList[1];			
		@gateList = ($gateList[0], @gateList[2..$#gateList]);	
		
		print OUT $_;
		# print "Gatename = $gateName[0], GL = @gateList\n";
	}
	#Read each MOSFET row and injecting the errors.
	elsif (/M_/) {	
		@row = split(" ", $_);
		$mosfetCount++;
		
		# print "R = $row[4] \n";
		
		#if there are still faults to be injected
		if ($errorCount < scalar @randLocations) {					
			
			#inject the fault now.
			if ($mosfetCount==$randLocations[$errorCount]) {			
				
				#nmos case
				if ($row[4] =~ m/GND/) {
					$row[4] = "err_".$errorCount;
					$errorVoltage = "V_$row[4] $row[4] 0 dc 0\n";
					
					#Check if fault injected at N1, N2, ....
					@nmosNumber = ($row[0] =~ m/(\d)/g);
					# print "Row 0: $row[0], N-Type: @nmosNumber\n";
					
					if ($gateName[0] =~ /NOT11|NOT12|NAND21|NAND22|NAND23|NAND24|NAND31|NAND32|NAND33|NAND34|NAND35|NAND36|NAND41|NAND42|NAND43|NAND44|NAND45|NAND46|NAND47|NAND48/i) {
						$inputs = scalar @gateList - 2;
					}
					else {
						$inputs = scalar @gateList - 1;
					}
				
					my $pwl = computeCurrent($charge);					
					$currentStrike = "I_$row[4] $row[1] $row[4] $pwl *Q=$charge\n"; 										
									
					print OUT2 "Fault injected at transistor# ".$mosfetCount." with sa0.\n";
					
					#print the output statements.
					print OUT "@row *$mosfetCount\n";
					print OUT $errorVoltage;
					print OUT $currentStrike;
					$errorCount++;
				}
				#pmos case
				elsif ($row[4] =~ m/VDD/) {
					$row[4] = "err_".$errorCount;
					$errorVoltage = "V_$row[4] $row[4] 0 dc $vdd\n";
					
					#Check if fault injected at P1, P2, ....
					@pmosNumber = ($row[0] =~ m/(\d)/g);
					# print "Row 0: $row[0], N-Type: @pmosNumber\n";					
					
					if ($gateName[0] =~ /NOR21|NOR22|NOR23|NOR24|NOR31|NOR32|NOR33|NOR34|NOR35|NOR36|NOR41|NOR42|NOR43|NOR44|NOR45|NOR46|NOR47|NOR48/i) {
						$inputs = scalar @gateList - 2;
					}
					else {
						$inputs = scalar @gateList - 1;
					}					
					
					my $pwl = computeCurrent($charge);						
					$currentStrike = "I_$row[4] $row[4] $row[1] $pwl *Q=$charge\n";					
				
					print OUT2 "Fault injected at transistor# ".$mosfetCount." with sa1. \n";
					
					#print the output statements.
					print OUT "@row *$mosfetCount\n";
					print OUT $errorVoltage;
					print OUT $currentStrike;
					$errorCount++;
				}	
				else {
					print OUT "@row *$mosfetCount\n";
				}
			}
			else {
				print OUT "@row *$mosfetCount\n";
			}			
		}
		else {
			print OUT "@row *$mosfetCount\n";
		}
	}
	else {
		print OUT $_;
	}	
}

close(IN);  
close(OUT);  
#! /usr/bin/perl -w

use warnings;
use Cwd;
use File::Basename;
use Data::Dumper qw(Dumper);
use Storable qw(retrieve nstore);
use List::Util qw(shuffle);
srand(time ^ $$);

###############################################################
#                                                             #
# Description: A perl script to inject faults on a randomly   #
#              selected gate.					              #
#                                                             #
#															  #		
# Created by: Ahmad Tariq Sheikh (KFUPM)    				  # 	
#															  #		
# Date: November 7, 2014.		                              #     
#                                                             #
###############################################################
		
###############################################################
sub getFaultInjectionTypeUsingGateLevel  {
	my $currentGate = $_[0];		
	my $errType = 0;
		
	my $cdf_probFailures = $sa0_inj_prob{$currentGate} + $sa1_inj_prob{$currentGate};
	$rn = rand($cdf_probFailures);
	
	# print "CG = $currentGate, $sa0_inj_prob{$currentGate}, $sa1_inj_prob{$currentGate}\n"; $cin=getc(STDIN);
	
	if ($cdf_probFailures==0) { $cdf_probFailures = 1; }
	
	if ($rn <= ($sa0_inj_prob{$currentGate}/$cdf_probFailures)) { #potential stuck-at-0 fault
		$rn1 = rand(1);
		if ($rn1 <= $sa0_inj_prob{$currentGate}) {
			$errType = "sa0";
		}
		else {
		$errType = "-1";
		}
	}
	else { #potential stuck-at-1 fault
		$rn1 = rand(1);
		if ($rn1 <= $sa1_inj_prob{$currentGate}) {
			$errType = "sa1";
		}
		else {
		$errType = "-1";
		}
	}		
	
	# print "Gate Name = $currentGate, CDF = $cdf_probFailures, $sa0_inj_prob{$currentGate}, $sa1_inj_prob{$currentGate}\n";
	# print "RN = $rn, ErrType = $errType\n";	
	# $cin = getc(STDIN);
	
	return $errType;
}
######################################################################################


#************************************************************************
#                                                                       *
#    Main Program                                                       *
#                                                                       *
#************************************************************************

$start = time;

$circuit=$ARGV[0]; 	# circuit name
$faults=$ARGV[1];	# number of faults to be injected
$flag = $ARGV[2]; 	# fault inject flag

%fanoutsReplaced = (); #Hash to hold gate outputs whose name has been changed due to fault injection.

#Load the sa0 and sa1 injection probabilities of current circuit.
%sa0_inj_prob = %{retrieve($circuit."_sa0.inj")};
%sa1_inj_prob = %{retrieve($circuit."_sa1.inj")};

open(IN,"$circuit".".v") || die " Cannot open input file $circuit".".v \n";
open(OUT,">$circuit"."f.v") || die " Cannot open input file $circuit"."f.v \n";

$fileName = $circuit."f.debug";

if ($flag eq 0) {
	open(OUT2,">$fileName") || die " Cannot open input file $circuit"."f.debug \n";
}
else {
	open(OUT2,">>$fileName") || die " Cannot open input file $circuit"."f.debug \n";
}

##########################################################################
# generate n fault injection sites										 #
##########################################################################
print "---Computing $faults Random locations for fault injection..\n";
# read the area file
@area_cdf = ();
$ng=0;
open(IN_AREA,"circarea.DAT") || die " Cannot open input file tranarea.DAT \n";
while(<IN_AREA>) {
	@row = split(" ", $_);
	$ng++;
	push @area_cdf, $row[2];
}
close(IN_AREA);

#################################################
# Fault injection based on roulette wheel		#
# algorithm. Trans. is selected based on its	#
# drain area.									#
#################################################

$area = $area_cdf[$#area_cdf];

for ($i=1; $i <= $faults; $i++) {
	$rn =  rand(1)*$area;	
	
	do {
		$rn =  rand(1)*$area;
		( $index ) = grep { $area_cdf[$_] >= $rn } 0..$#area_cdf;
		$index++;				
	}while(grep $_ eq $index, @randLocations);
	
	push @randLocations, $index;		
	# print "---RN = $rn, Index = $index, @randLocations\n"; 
}
@randLocations = sort {$a <=> $b} @randLocations;
print OUT2 "---Rand Locations: @randLocations\n---Area = $area, Gates = $ng\n";

#####################################
# generate n locations of faults	#
#####################################
# my @randLocations=();
# for ($i=1; $i <= $faults; $i++) {
	# $rn =  int(rand($ng)) + 1;
	
	# while(grep $_ eq $rn, @randLocations) {
		# $rn =  int(rand($ng)) + 1;
	# }
	# push @randLocations, $rn;
# }
# # sort numerically ascending
# @randLocations = sort {$a <=> $b} @randLocations;
# @rn = shuffle shuffle 3..4;
# @rn1 = shuffle shuffle 5..6;
# @randLocations  = $rn1[0];
# print OUT2 "---Rand Locations: @randLocations\n---Area = $area, Gates = $ng\n";
# print "---Rand Locations = @randLocations \n";	

#############################################
# Main Program Start here					#
#############################################
$currentGateNo = 0;
$gateNumberPlaced = 0;
$rLoc = 0;
$faultsInserted=0;
@area_cdf = ();
@primaryOutputs = ();
@primaryInputs = ();

# $orCounter = 0;

while(<IN>){
 
	#Matching endmodule Statement
	if (/endmodule/) {               
    }

	#Matching Module Statement
	elsif (/module (.*) \((.*)/) {          
		print OUT "module ".$1."f ($2 \n";		           
    }

	#Matching Inputs   
	elsif (/input/) { 
		print OUT $_;	
		chomp;
		$_ =~ s/;//;
		@primaryInputs = split(", ", $_);
		@row = split(" ", $primaryInputs[0]);
		$primaryInputs[0] = $row[1];		
    }

	#Matching Outputs
	elsif (/output/) {
		print OUT $_;		
		@primaryOutputs = ($_ =~ m/(\w+)/g);		 					
    }

	#Printing Supply statements
	elsif (/supply/) {
		print OUT $_;		           
    }	
	
	#Matching all gates
	elsif ($_ =~ m/NOT|NAND|NOR|OR/i) {
	
		#Read the gate IOs
		my @gateList = ($_ =~ m/(\w+\d+)/g);	
		my @gateType = ($_ =~ m/(\w+)/);	
		
		@gateList = ($_ =~ m/(\w+)/g);				
		# $gateName[0] = $gateList[1];			
		@gateList = ($gateList[1], @gateList[2..$#gateList]);	
		
		# @gateName = split('_', $gateList[0]);
		
		$currentGate = $gateList[1];
		$currentGateNo++;
		
		# print the current row to the output.
		if (!(grep $_ eq $gateList[1], @primaryOutputs)) {			
			print OUT "$gateType[0] $gateList[0](";
			for ($j=1; $j < scalar @gateList; $j++){
				
				# check if the gate input name has been replaced
				# due to the fault injection gate.
				if (exists($fanoutsReplaced{$gateList[$j]})) {
					$gateList[$j] = $fanoutsReplaced{$gateList[$j]};					
				}
				if ($j == scalar @gateList - 1){				
					print OUT $gateList[$j].");\n";
				} else {
					print OUT $gateList[$j].", ";
				}
			}		
		}
				
		#First time
		if ($gateNumberPlaced <= scalar @randLocations - 1) {
			$rLoc = $randLocations[$gateNumberPlaced];					
		}
		
		# Check if the current gate no. is the one in rLoc
		if ($currentGateNo==$rLoc) { # and $gateName[0] !~ m/\bQNOT|QNAND|QNOR\b/i) {
			
			$faultType = getFaultInjectionTypeUsingGateLevel($currentGate);			
			
			if ($faultType eq 'sa1') { #insert sa1 fault by inserting an OR gate with one input as "1"	 				
				
				if (grep $_ eq $gateList[1], @primaryOutputs) {
					
					print OUT "$gateType[0] $gateList[0]($gateList[1]"."_sa1, ";
					for ($j=2; $j < scalar @gateList; $j++){				
						
						#check if the gate input name has been replaced
						#due to the fault injection gate.
						if (exists($fanoutsReplaced{$gateList[$j]})) {
							$gateList[$j] = $fanoutsReplaced{$gateList[$j]};					
						}
						
						if ($j == scalar @gateList - 1){				
							print OUT $gateList[$j].");\n";
						} else {
							print OUT $gateList[$j].", ";
						}
					}				
					
					print OUT "or err_sa1".$faultsInserted."($gateList[1], $gateList[1]_sa1, errCntrl1);\n";					
				}
				else {
					print OUT "or err_sa1".$faultsInserted."($gateList[1]_sa1, $gateList[1], errCntrl1);\n";					
				}				
				print OUT2 "Fault injected at Gate $rLoc ($gateList[0]) with sa1.\n";
				
				$gateNumberPlaced++;
				$faultsInserted++;
						
				#Update the gate rename;
				$fanoutsReplaced{$gateList[1]} = "$gateList[1]_sa1";
			}
			elsif ($faultType eq 'sa0') {	#insert sa0 fault by inserting an AND gate with one input as "0"
				if (grep $_ eq $gateList[1], @primaryOutputs) {
					
					print OUT "$gateType[0] $gateList[0]($gateList[1]"."_sa0, ";
					for ($j=2; $j < scalar @gateList; $j++){				
						
						#check if the gate input name has been replaced
						#due to the fault injection gate.
						if (exists($fanoutsReplaced{$gateList[$j]})) {
							$gateList[$j] = $fanoutsReplaced{$gateList[$j]};					
						}
						
						if ($j == scalar @gateList - 1){				
							print OUT $gateList[$j].");\n";
						} else {
							print OUT $gateList[$j].", ";
						}
					}					
					print OUT "not err_sa0_NOT".$faultsInserted."(ECNO_".$faultsInserted.", errCntrl1);\n";					
					print OUT "and err_sa0".$faultsInserted."($gateList[1], $gateList[1]_sa0, ECNO_".$faultsInserted.");\n";					
				}
				else {
					print OUT "not err_sa0_NOT".$faultsInserted."(ECNO_".$faultsInserted.", errCntrl1); \n";
					print OUT "and err_sa0".$faultsInserted."($gateList[1]_sa0, $gateList[1], ECNO_".$faultsInserted.");\n";					
				}
				print OUT2 "Fault injected at Gate $rLoc ($gateList[0]) with sa0.\n";
				
				$gateNumberPlaced++;
				$faultsInserted++;
					
				#Update the gate rename;
				$fanoutsReplaced{$gateList[1]} = "$gateList[1]_sa0";
			}

			# The case when primary output(s) is selected for fault injection but 
			# the fault is not injected.
			elsif (grep $_ eq $gateList[1], @primaryOutputs and $faultType eq "-1") { 
				print OUT "$gateType[0] $gateList[0]($gateList[1], ";				
				for ($j=2; $j < scalar @gateList; $j++){			
				
					#check if the gate input name has been replaced
					#due to the fault injection gate.
					if (exists($fanoutsReplaced{$gateList[$j]})) {
						$gateList[$j] = $fanoutsReplaced{$gateList[$j]};					
					}				
					
					if ($j == scalar @gateList - 1){				
						print OUT $gateList[$j].");\n";
					} else {
						print OUT $gateList[$j].", ";
					}
				}					
				print OUT2 "No Fault injected at Gate $rLoc ($gateList[0]).\n";
				$gateNumberPlaced++;
				$faultsInserted++;
			}
			# The case when fault is not injected for all gates except the primary outputs(s).
			elsif ($faultType eq "-1") { 							
				print OUT2 "No Fault injected at Gate $rLoc ($gateList[0]).\n";
				$gateNumberPlaced++;
				$faultsInserted++;
			}				
		}
		# The case when primary output(s) is not selected for fault injection.
		elsif (grep $_ eq $gateList[1], @primaryOutputs) {					
			print OUT "$gateType[0] $gateList[0]($gateList[1], ";
			for ($j=2; $j < scalar @gateList; $j++){

				#check if the gate input name has been replaced
				#due to the fault injection gate.
				if (exists($fanoutsReplaced{$gateList[$j]})) {
					$gateList[$j] = $fanoutsReplaced{$gateList[$j]};					
				}
				
				if ($j == scalar @gateList - 1){				
					print OUT $gateList[$j].");\n";
				} else {
					print OUT $gateList[$j].", ";
				}
			}						
		}
	}	
}

# Printing endmodule statement
print OUT "\n";
print OUT "endmodule";

close(IN);
close(OUT);
close(OUT2);

############################################################
#	Generating the final Bench file
############################################################
open(FINAL_BENCH, ">$circuit"."f.bench") or die $!;

print FINAL_BENCH "\n";
foreach $k (@primaryInputs) {
	print FINAL_BENCH "INPUT($k)\n";
}
print FINAL_BENCH "\n";

foreach $k (@primaryOutputs) {
	if ($k ne "output") {
		print FINAL_BENCH "OUTPUT($k)\n";
	}
}
print FINAL_BENCH "\n";

open(IN,"$circuit"."f.v") or die $!;
while(<IN>) {
	if ($_ =~ m/\bNOT\b|\bNAND\b|\bNOR\b|\bAND\b|\bOR\b/i) {
		
		# my @gateList = ($_ =~ m/(\w+\d+)/g);	
		
		my @gateList = ($_ =~ m/(\w+)/g);				
		@gateList = ($gateList[0], @gateList[2..$#gateList]);	
		
		@row = split (" ", $_);
		$gateType = uc $row[0];		
				
		print FINAL_BENCH "$gateList[1] = $gateType(";
		for ($j=2; $j < scalar @gateList; $j++){
				
			if ($j == scalar @gateList - 1){				
				print FINAL_BENCH $gateList[$j].")\n";
			} else {
				print FINAL_BENCH $gateList[$j].", "
			}
		}			
	}	
}
print FINAL_BENCH "\nEND\n";
close(FINAL_BENCH);
system("dos2unix $circuit"."f.bench");
############################################################

$end=time;
$diff = $end - $start;

print "---Number of injected faults is $faults \n";
print "---Execution time to inject faults is $diff seconds \n";
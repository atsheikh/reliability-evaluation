#! /usr/bin/perl 


#************************************************************************
#                                                                       *
#   Perl file to execute the spice file.					            *
#     - .bench file containng the module to be simulated                *
#     - .vec file containing the test vectors                           *
#																		*
#	May 18, 2014.                                                       *
#   Ahmad Tariq Sheikh (KFUPM)											*
#************************************************************************

my $USAGE = <<EOU;
USAGE: $0 input
      Generates the testbench file input_stim.v from two files:
      - input.bench   : file containng the module to be simulated 
      - input.vec : file containing the test vectors          
EOU

die $USAGE unless scalar @ARGV;

$circuit=$ARGV[0];
@inputs=();
%inputHash=();
@outputs=();
$in_vec = 0; #number of inputs per vector
$vec = 0; #number of vectors

open(IN,"$circuit".".sp") || die " Cannot open input file $circuit".".sp \n";
open(IN2,"$circuit".".vec") || die " Cannot open input file $circuit".".vec \n";
open(OUT,">$circuit"."_exec.sp") || die " Cannot open input file $circuit"."_exec.sp \n";


#-----------------------------------
#    Reading the test vectors
#-----------------------------------
while(<IN2>) {	
	# Read the first line of the .vec file and get the number of inputs
	if ($in_vec == 0) {
		my $line = $_;
		$line =~ s/[ \n]//gs; # clear any spaces
		$in_vec = $line;
	}
	elsif (/(1|0){$in_vec}/) {                 
		$VECTORS[$vec]=$_;	
		$vec++;	           
    }	
}
# print "--vec: $VECTORS[0] \n";

#-----------------------------------
#   Reading the spice file and
#	making connections to the 
#	inputs.
#-----------------------------------

while(<IN>){
   
	# Reading Inputs   
	if (/INPUTS/) {          	
		@inputs = split(" ", $_);
		shift(@inputs);
		foreach $i (0..scalar @inputs - 1) {
			$inputHash{$inputs[$i]} = substr $VECTORS[0], $i, 1;
		}	
		
		print OUT "*INPUTS  ";
		for ($i=0; $i < length($VECTORS[0]) - 1; $i++){
			$temp = substr $VECTORS[0], $i, 1;
			print OUT "$inputs[$i]=$temp ";			
		}
		print OUT "\n";
	}

	# Matching Outputs
	elsif (/OUTPUTS/) {
		@outputs = split(" ", $_);
		shift(@outputs);
		# print "O = @outputs \n";
		print OUT $_;
     }
	
	#Read each MOSFET row and make connections to the input ports to either VDD 
	#or GND depending upon the value in @VECTORS.
	elsif (/M_/) {	
		@row = split(" ", $_);
		$index = 0;		
		if ( (grep {$_ eq $row[2]} @inputs) ) {
			
			#replace input with VDD
			if ($inputHash{$row[2]}==1) {
				$row[2] = VDD;
			}
			#replace input with GND
			elsif ($inputHash{$row[2]}==0) {
				$row[2] = GND;				
			}
		}
		
		if ( (grep {$_ eq $row[3]} @inputs) ) {
			
			#replace input with VDD
			if ($inputHash{$row[3]}==1) {
				$row[3] = VDD;
			}
			#replace input with GND
			elsif ($inputHash{$row[3]}==0) {
				$row[3] = GND;				
			}
		}
		print OUT "@row \n";
	}
	else {
		print OUT $_;
	}	
}

close(IN);  
close(OUT);  
close(OUT2);  


#-- Simulating the SPICE model.
# print "\n---Running test vectors $circuit\.vec on $circuit\.sp\n\n";
# system ("hspice $circuit"."_exec.sp -o $circuit");


srand(time ^ $$);

sub getOutputsFromOutFile {		
	
	$file = $_[0];
	my @outputs = ();
	
	print "\tReading $file file ... \n";
		
	open (IN, "$file") or die $!;		

	while (<IN>) {
		chomp;
		if ($_ =~ m/\*/) {			
			last;			
		}		
		else {
			@row = split(" ", $_);
			if ($row[0] =~ m/test/) {					
				push @outputs, $row[3];
			}
		}		
	}
	close(IN);		
	
	return @outputs;
}


@AREA_ORIG_MAJ_PHASE_130nm = qw (	
									1994.46
									2532.66
									1313.52
									1452.36
									535.86
									4219.02
									363.48
									302.64
									883.74
									475.8
									991.38
									1106.04
									1040.52

								); 
			
# @AREA_ORIG_MAJ_PHASE_45nm	=	 qw (	494.91
									# 1593.00
									# 211.14
									# 1047.33
									# 1583.82
									# 42.12
									# 129.06
									# 83.43
									# 338.31
									# 52.92
									# 79.92
									# 653.13
									# 171.72
									# 1720.71
									# 35.10
									# 1203.12
									# 1223.91
									# 86.94
								# ); 

# @AREA_ORIG_MAJ_PHASE_130nm	=	 qw (	1429.74
										# 4602.00
										# 609.96
										# 3025.62
										# 4575.48
										# 121.68
										# 372.84
										# 241.02
										# 977.34
										# 152.88
										# 230.88
										# 1886.82
										# 496.08
										# 4970.94
										# 101.40
										# 3475.68
										# 3535.74
										# 251.16
								# ); 								

			

#************************************************************************
#                                                                       *
#    Main Program                                                       *
#                                                                       *
#************************************************************************

$start = time;

@nfaults = qw (1 2 5);

$circuit = $ARGV[0] || die "No circuit name specified";
$N = $ARGV[1] || die "Fault injection Rate";
$S = $ARGV[2] || die "Number of simulations need to be specified";
$circ = $ARGV[3] || die $!;

open(IN,"$circuit".".bench") || die " Cannot open input file $circuit"." line 107\n";
$out = 0; #number of outputs
$in = 0; #number of inputs
while(<IN>){
      
	if (/OUTPUT/) {          
	    $out++;		           
         }
	if (/INPUT/) {          
	    $in++;		           
         }
}
close(IN);

#-- Generating the fault free circuit
print "\n---Executing bench_to_tr_gate on $circuit \n\n";
system ("perl bench_to_gate_130nm.pl $circuit 1");
print "\n---Initial fault free circuit created $circuit\.v\n\n";


open(IN,"trans.temp") || die " Cannot open input file $circuit".".v \n";
$nt=0;	# No. of transistors
$ng=0;  # No. of gates
while(<IN>){
	@n = split(" ",$_);
	$nt = $n[0];
	$ng = $n[1];
}
close(IN);
#delete the temporary area file.
system ("del trans.temp");

open(IN,"area.sp") || die " Cannot open input file area.sp \n";
$area=0;	# area of circuit
while(<IN>){
	$area = $_;
}
close(IN);
system ("del area.sp");

print "Circuit ====> $circuit\n";
print "Number of transistors = $nt \n";
print "Number of gates = $ng \n";

open(OUT,">>$circuit.dat") or die "cannot open $circuit.dat";
# print OUT "HOPE Simulation \n";
# print OUT "===============================\n";
# print OUT "Number of gates = $ng \n";
# print OUT "Number of transistors = $nt \n";
# print OUT "Area = $area \n";
# print OUT "Number of inputs = $in \n";
# print OUT "Number of outputs = $out \n\n";
# print OUT "Faults\tSims.\tFailures\tFailure Rate\tReliability\n";

$fault_inject_flag = 0;
$length = $in-1;
$vcount = 1;
@vecs = ();
@values = ();

$OH = sprintf("%0.2f",$area/$AREA_ORIG_MAJ_PHASE_130nm[$circ-1]);

for ($h=0; $h <= $N; $h++){
	
	$F = $OH*$nfaults[$h]; # Max. Number of faults to be injected.   		
	$F1=$nfaults[$h];	
			
	if ($F > 0) {
		@values = (int($F), int($F) + 1);	
	}
	else {
		@values = (0, 0);
	}
	print "-------Faults = $F Values = @values\n";	
	
	@k = (0, 0);    # number of failed simulation		
	
	foreach $q (0..scalar @values - 1) { #simulate each iteration twice.		
		if ($values[$q] > 0) {	
			for ($i=0; $i < $S; $i++) {			
			
				$bin1 = ();
				$bin2 = ();
				
				#-- Generating first random vector
				print "\n---Generating random vector $circuit\.vec\n";
				$test1 = $circuit."Err0.test";
				$test2 = $circuit."Err1.test";
				open(TEST1, ">$test1") or die $!;
				open(TEST2, ">$test2") or die $!;
				for ($m = 1; $m <= $vcount; $m++) {
					$bin = ();
					for ($n = 1; $n <= $length; $n++) {
						$rn = rand(1);
						if ($rn > 0.5) {
							$bin .= 1;
						}
						else {
							$bin .= 0;
						}
					}
					push @vecs, $bin;
					print TEST1 "$m: $bin"."0\n";
					print TEST2 "$m: $bin"."1\n";
				}				
				
				# Inject F number of faults
				print "\n---Injecting $values[$q] faults in $circuit"."f.v\n\n";
				system ("perl fault_inject_gate_rwheel.pl $circuit $values[$q] $fault_inject_flag");
				$fault_inject_flag = 1;
				
				#########################################################################
				#	Simulating the bench file with HOPE
				##########################################################################
				open(DUMMY, ">none.fault") or die $!;
				close(DUMMY);
				system("hope -t $circuit"."Err0.test -f none.fault $circuit"."f.bench -l $circuit"."f0.OUT");
				system("hope -t $circuit"."Err1.test -f none.fault $circuit"."f.bench -l $circuit"."f1.OUT");
				##########################################################################
								
				@trueOutput = getOutputsFromOutFile($circuit."f0.OUT");
				@falseOutput = getOutputsFromOutFile($circuit."f1.OUT");	
							
				open(DEBUG,">>$circuit"."f.debug") or die $!;
				foreach $j (0..scalar @trueOutput - 1)  {
					print DEBUG "V = $bin\n";
					print DEBUG "R = $trueOutput[$j]\n";
					print DEBUG "F = $falseOutput[$j]\n";		
				
					if ($trueOutput[$j] ne $falseOutput[$j]) {
						$k[$q] = $k[$q] + 1;				
						print DEBUG "---Simulation $i with $values[$q] faults failed.\n\n";								
					} 
					else {						
						print DEBUG "---Simulation $i with $values[$q] faults successfull.\n\n";								
					}				
				}
				close(DEBUG);				
			}
		}
		elsif ($values[$q] <= 0) {
			$k[$q] = 0;			
		}
	}
	$fr1 = $k[0]/$S;
	$fr2 = $k[1]/$S;	
	$failureRate = ($values[1] - $F) * $fr1 + (1 - ($values[1] - $F)) * $fr2;
	$reliability = (1 - $failureRate) * 100;
		
	print OUT "$F($values[0],$values[1])\t$S\t\t($k[0],$k[1])\t\t\t$failureRate\t\t\t$reliability%\n";
	print "--Simulation_output-- $F\t$k\t$p\n";
		
	if ($fr2==1) {
		last;
	}
}	


print "--- Simulation Results saved in $circuit.dat";
$end=time;
$diff = $end - $start;
print OUT "---Execution time is $diff seconds \n";
close(OUT);
close(TEST1);
close(TEST2);

system("del *f.bench");
system("del *.OUT");
system("del *.TEST");
system("del *.TEMP");
system("del *.v");








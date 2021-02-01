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

open(IN,"$circuit".".bench") || die " Cannot open input file $circuit".".bench \n";
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

open(OUT,">$circuit.dat") or die "cannot open $circuit.dat";
print OUT "HOPE Simulation \n";
print OUT "===============================\n";
print OUT "Number of gates = $ng \n";
print OUT "Number of transistors = $nt \n";
print OUT "Area = $area \n";
print OUT "Number of inputs = $in \n";
print OUT "Number of outputs = $out \n\n";
print OUT "Faults %\t# Faults\t# Vectors\tFailures\tFailure Rate\tReliability\n";

$fault_inject_flag = 0;
$length = $in-1;
$vcount = 1;
@vecs = ();

for ($h=0; $h <= 0; $h++){
	
	# $F = int(($nt*$nfaults[$h]/100)+1); # Max. Number of faults to be injected.   		
	$F1=$nfaults[$h];	
	$F=$F1;
	
	$k = 0;    # number of failed simulation	
	
	if ($F > 0) {	
	
		$k = 0;    # number of failed simulation	
		
		for ($i=0; $i < $S; $i++){			
		
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
			print "\n---Injecting $F faults in $circuit"."f.v\n\n";
			system ("perl fault_inject_gate_rwheel.pl $circuit $F $fault_inject_flag");
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
					$k += 1;				
					print DEBUG "---Simulation $i failed \n\n";								
				} 
				else {						
					print DEBUG "---Simulation $i successfull \n\n";								
				}				
			}
			close(DEBUG);			
		}
			
		$p = $k / ($S*$vcount);
		$rr = (1 - $p)*100;
		print OUT "$F1%\t\t\t$F\t\t\t$S x $vcount\t\t$k\t\t$p\t\t$rr%\n";
		print "--Simulation_output-- $F\t$k\t$p\n";
			
		if ($rr <= 0) {
			last;
		}
	}
	elsif ($F <= 0) {
		print OUT "$F1%\t\t\t$F\t\t\t$S x $vcount\t\t\t\t0\t\t\t0\t\t\t100%\n";
		print "--Simulation_output-- $F\t$k\t$p\n";
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
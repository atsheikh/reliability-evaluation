use List::MoreUtils qw/ uniq /;

srand(time ^ $$);


@bin4 = qw	(	00
				01
				10
				11				
			);

@bin8 = qw	(	000
				001
				010
				011
				100
				101
				110
				111				
			);

@bin16 = qw	(	0000
				0001
				0010
				0011
				0100
				0101
				0110
				0111
				1000
				1001
				1010
				1011
				1100
				1101
				1110
				1111
			);

@AREA_ORIG_MAJ_PHASE	=	 qw (	42.12
								); 			

#************************************************************************
#                                                                       *
#    Main Program                                                       *
#                                                                       *
#************************************************************************

$start = time;

@nfaults = qw (1 2 5);

$vdd = 1.3;

$circuit = $ARGV[0] || die "No circuit name specified";
$N = $ARGV[1] || die "Number of faults";
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
print "\n---Executing bench_to_spice on $circuit\n\n";
system ("perl bench_to_spice_130nm.pl $circuit 1");
print "\n---Initial fault free SPICE model $circuit\.sp created\n\n";


open(IN,"$circuit.sp") || die " Cannot open input file $circuit".".v \n";
$nt=0;	# No. of transistors
while(<IN>){
	if (/M_/) {
		$nt++;
	}	
}
close(IN);

open(IN,"area.sp") || die " Cannot open input file area.sp \n";
$area=0;	# area of circuit
while(<IN>){
	$area = $_;
}
close(IN);
system ("del area.sp");

print "---Circuit ====> $circuit\n";
print "---Number of transistors = $nt \n";
print "---Area = $area \n";


open(OUT,">$circuit.dat") or die "cannot open $circuit.dat";
print OUT "SPICE-Level Simulation \n";
print OUT "===============================\n";
print OUT "Number of transistors = $nt \n";
print OUT "Area = $area \n";
print OUT "Number of inputs = $in \n";
print OUT "Number of outputs = $out \n\n";
print OUT "Faults\t\tSims.\tFailures\tFailure Rate\tReliability\n";


$outFile = $circuit."f.DEBUG";

#---Saving the outputs in the DEBUG file
print "\n---Saving the outputs in $circuit"."f_exec.out file\n";
open(OUT2,">$outFile") || die " Cannot open input file $circuit"."f.debug \n";
print OUT2 "*$circuit SPICE outputs\n";
print OUT2 "*Number of transistors = $nt \n";
print OUT2 "*Area (summation of nmos and pmos drains) = $area \n";
print OUT2 "*--------------------------------\n";
close (OUT2);

$OH = sprintf("%0.2f",$area/$AREA_ORIG_MAJ_PHASE[$circ-1]);

for ($h=0; $h <= 0; $h++){
	
	# $F = $OH*$nfaults[$h]; # Max. Number of faults to be injected.   		
	$F1=$nfaults[$h];	
	$F=$F1;
	
	$k = 0;    # number of failed simulation	
	
	if ($F > 0) {	
	
		for ($i=0; $i < $S; $i++){			
		
			$bin = ();		
				
			#-- Generating random vector
			print "\n---Generating random vector $circuit\.vec\n";
			for ($m = 0; $m < $in; $m++) {
				$rn = rand(1);
				if ($rn > 0.5) {
				$bin .= 1;
				}
				else {
					$bin .= 0;
				}
			}	
		
			# $bin = "01";
			# $bin = $bin4[$i];
			open(OUT1,">$circuit.vec") or die "cannot open $circuit.vec";
			print OUT1 "$in\n";
			print OUT1 "$bin\n";
			print OUT1 "END";
			close(OUT1);	
			
			open(OUT2,">>$outFile") || die " Cannot open input file $circuit"."f.debug \n";
			print OUT2 "Run = $i; Faults = $F Faults% = $F1%\n";	
			print OUT2 "Input = $bin\n";
			
			#---Connect inputs to the SPICE model created.
			print "\n---Creating fault free HSPICE $circuit.sp model\n\n";
			system ("perl fault_free_execute_spice.pl $circuit");			
			print "\n---Fault free $circuit"."_exec.sp SPICE model with inputs applied\n";
			
			#---Injecting Faults and then simulating the spice file.
			print "\n---Generating $circuit"."f_exec.sp HSPICE model for fault injection\n\n";
			system ("perl fault_inject_spice.pl $circuit $F $nt $area");
			print "\n---Faulty model $circuit"."f_exec.sp generated\n";			
			
			print "\n---Simulating the faulty SPICE model $circuit"."f_exec.sp\n";
			system ("hspice $circuit"."f_exec.sp -o $circuit"."f");
			print "\n---Faulty SPICE model $circuit"."f_exec.sp simulated\n\n";		
						
			$prev_out_flag = 0;
			@true_output = ();
			$failure = 0;
			$timer = 0;
			@whichOutputFailed = ();
			$offset = 0; 
			$errThreshold = 0;
			
			#---Reading the .LIS file to read the outputs
			print "\n---Reading $circuit"."f.lis file\n";
			open(IN, "$circuit"."f.lis");			
			$flag = 0;
			while(<IN>) {
				if ($_ eq '') { # if current line is a blank line, skip it and read next line
					next;					
				}				
				@temp = split(" ", $_);
				if ($_ =~ /^x/i) { #start of outputs in the .LIS file					
					$flag = 1;
				}
				elsif ($_ =~ /concluded/i) { #end of outputs in the .LIS file				
					close(IN);
					$flag=0;
					last;
				}
				elsif($flag==1){ 
					print OUT2 $_;						
					@out = split(" ", $_);
					if ($out[0] =~ m/^\d/) {	#first output starts here
						# print "\n@out \n";
						# $cin = getc(STDIN);
						
						$timer++;						
						if ($timer==21) {
							$prev_out_flag = 0;	
							$offset += 4;
							$timer = 1;
						}
						# print "Timer = $timer: flag = $prev_out_flag, @out\n";
						# $cin = getc(STDIN);
						
						#process the voltage values to scale them properly
						for ($j=1; $j <= scalar @out; $j++) {
						
							if($out[$j] =~ m/m/) { #scale milli by multiplying by 10^-3
								$out[$j] = $out[$j]*0.001;
								
								#executed for one time only to determine the true output value by observing the 
								#the voltage value at 0ns.
								if ($prev_out_flag==0) { 
									if ($out[$j] > $vdd/2) {
										$true_output[$j] = 1;
									}
									else {
										$true_output[$j] = 0;										
									}
								}
								else {
									if (($true_output[$j]==1 and $out[$j] < ($vdd/2-$errThreshold)) or ($true_output[$j]==0 and $out[$j] > ($vdd/2+$errThreshold))) {
										$failure = 1;
										push @whichOutputFailed, ($j+$offset-1);										
									}									
								}
							}
							elsif ($out[$j] =~ m/u/) { #scale microns by multiplying by 10^-6
								$out[$j] = $out[$j]*0.000001;							
																
								#executed for one time only to determine the true output value by observing the 
								#the voltage value at 0ns.
								if ($prev_out_flag==0) { 
									if ($out[$j] > $vdd/2) {
										$true_output[$j] = 1;
									}
									else {
										$true_output[$j] = 0;
										
									}
								}
								else {
									if (($true_output[$j]==1 and $out[$j] < ($vdd/2-$errThreshold)) or ($true_output[$j]==0 and $out[$j] > ($vdd/2+$errThreshold))) {
										$failure = 1;
										push @whichOutputFailed, ($j+$offset-1);										
									}									
								}
							}
							elsif($out[$j] =~ m/n/) { #scale nano by multiplying by 10^-9
								$out[$j] = $out[$j]*0.000000001;
																
								#executed for one time only to determine the true output value by observing the 
								#the voltage value at 0ns.
								if ($prev_out_flag==0) { 
									if ($out[$j] > $vdd/2) {
										$true_output[$j] = 1;
									}
									else {
										$true_output[$j] = 0;
										
									}
								}
								else {
									if (($true_output[$j]==1 and $out[$j] < ($vdd/2-$errThreshold)) or ($true_output[$j]==0 and $out[$j] > ($vdd/2+$errThreshold))) {
										$failure = 1;
										push @whichOutputFailed, ($j+$offset-1);										
									}									
								}
							}
							elsif($out[$j] =~ m/p/) { #scale pico by multiplying by 10^-12
								$out[$j] = $out[$j]*0.000000000001;
																
								#executed for one time only to determine the true output value by observing the 
								#the voltage value at 0ns.
								if ($prev_out_flag==0) { 
									if ($out[$j] > $vdd/2) {
										$true_output[$j] = 1;
									}
									else {
										$true_output[$j] = 0;
										
									}
								}
								else {
									if (($true_output[$j]==1 and $out[$j] < ($vdd/2-$errThreshold)) or ($true_output[$j]==0 and $out[$j] > ($vdd/2+$errThreshold))) {
										$failure = 1;
										push @whichOutputFailed, ($j+$offset-1);										
									}									
								}
							}
							elsif($out[$j] =~ m/f/) { #scale femto by multiplying by 10^-15
								$out[$j] = $out[$j]*0.000000000000001;
																
								#executed for one time only to determine the true output value by observing the 
								#the voltage value at 0ns.
								if ($prev_out_flag==0) { 
									if ($out[$j] > $vdd/2) {
										$true_output[$j] = 1;
									}
									else {
										$true_output[$j] = 0;
										
									}
								}
								else {
									if (($true_output[$j]==1 and $out[$j] < ($vdd/2-$errThreshold)) or ($true_output[$j]==0 and $out[$j] > ($vdd/2+$errThreshold))) {
										$failure = 1;
										push @whichOutputFailed, ($j+$offset-1);										
									}									
								}
							}
							else {								
								#executed for one time only to determine the true output value by observing the 
								#the voltage value at 0ns.
								if ($prev_out_flag==0) { 
									if ($out[$j] > $vdd/2) {
										$true_output[$j] = 1;
									}
									else {
										$true_output[$j] = 0;
									}
								}
								else {
									if (($true_output[$j]==1 and $out[$j] < ($vdd/2-$errThreshold)) or ($true_output[$j]==0 and $out[$j] > ($vdd/2+$errThreshold))) {
										$failure = 1;
										push @whichOutputFailed, ($j+$offset-1);										
									}									
								}
							}							
						}
						$prev_out_flag = 1;								
					}
					
				} #last elsif ends here				
			}#reading of .LIS ends here		
			
			if ($failure==1) {
				$k++;
				@whichOutputFailed = uniq @whichOutputFailed;
				print OUT2 "Output @whichOutputFailed failed.\n";
				print OUT2 "-----------------------------\n";				
				@whichOutputFailed = ();
			}
			elsif ($failure==0) {
				print OUT2 "successful.\n";
				print OUT2 "-----------------------------\n";
			}
			close(OUT2);
		}
		
		$p = $k / $S;
		$rr = (1 - $p)*100;
		print OUT "$F1%\t\t\t$F\t\t\t$S\t\t\t\t$k\t\t\t$p\t\t\t$rr%\n";
		print "--Simulation_output-- $F\t$k\t$p\n";
		
		if ($rr <= 0) {
			last;
		}
	}
	elsif ($F <= 0) {
		print OUT "$F1%\t\t\t$F\t\t\t$S\t\t\t\t0\t\t\t0\t\t\t100%\n";
		print "--Simulation_output-- $F\t$k\t$p\n";
	}
}

$end=time;
$diff = $end - $start;
print OUT "---Execution time is $diff seconds \n";
close(OUT);
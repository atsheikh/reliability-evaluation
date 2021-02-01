#! /usr/bin/perl -w

$start = time;

@circuits = qw (	
cordicMR_0.1953
ex5MR_1.3989
			   );

foreach $i (0..scalar @circuits - 1) {
	system("perl get_failure_rate_hope_level.pl $circuits[$i] 2 2000");
	# # system("perl get_failure_rate_hope_weighted_cel_single.pl $circuits[$i] 1 2");
}

# $k=0;
# foreach $i (0..scalar @circuits - 1) {
	# $k++;
	# # system("perl get_failure_rate_hope_weighted_cel.pl $circuits[$i] 2 2500 $k");
	
	# # system("perl get_failure_rate_hope_level.pl $circuits[$i] 1 2000");
	# system("perl get_failure_rate_hope_weighted.pl $circuits[$i] 2 2000 $k");
	
	# # # system("perl get_failure_rate_hope_level.pl $circuits[$i] 1 2000");
# }




$end = time;
$diff = $end - $start;
print "\n\n\n---Time of Simulation = $diff \n";
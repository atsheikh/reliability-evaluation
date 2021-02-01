#! /usr/bin/perl -w

$start = time;

@circuits = qw (	
s344f
s386f
s444f			   );


# system("perl get_failure_rate_spice_level_single.pl s298f 2 5000");

			   
# $k=0;
foreach $i (0..scalar @circuits - 1) {
	# $k++;
	system("perl get_failure_rate_spice_level_single.pl $circuits[$i] 2 2500 1");
	# system("perl get_failure_rate_spice_level_weighted.pl $circuits[$i] 2 5000 1");
}

$end = time;
$diff = $end - $start;
print "\n\n\n---Time of Simulation = $diff \n";
				
	
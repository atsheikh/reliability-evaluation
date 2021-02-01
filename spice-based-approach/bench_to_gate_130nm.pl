#! /usr/bin/perl 

###############################################################
#                                                             #
# Description: A perl script to convert from bench format     #
#              to gate-level verilog format.        		  #
#                                                             #
#                                                             #
# Author: Ahmad Tariq Sheikh (KFUPM)                          #
#                                                             #
# Date: May 15, 2014.                                         #
#															  #		
#                                                             #
#                                                             #
###############################################################



#************************************************************************
#                                                                       *
#    Main Program                                                       *
#                                                                       *
#************************************************************************

$start = time;

$circuit=$ARGV[0];
$d=$ARGV[1];

open(IN,"$circuit".".bench") || die " Cannot open input file $circuit".".bench \n";
open(OUT_TEMP,">$circuit".".v") || die " Cannot open input file $circuit".".v \n";
open(OUT,">test".".v") || die " Cannot open input file test".".v \n";
open(OUT_AREA,">circarea".".DAT") || die " Cannot open input file $circuit".".v \n";
open(OUT2,">test".".temp") || die " Cannot open input file $circuit".".v \n";


$in = 0; #number of inouts
$out = 0; #number of outputs
$ino = 0;	#nuber of inout pins
$tout=0;
$tran = 0;
$tempArea=0;

$ninv=0;
$nbuff=0;
$nnand=0;
$nand=0;
$nnor=0;
$nor=0;
$dff=0;

$dninv=0;
$dnbuff=0;
$dnnand=0;
$dnand=0;
$dnnor=0;
$dnor=0;
$dgg=0;
$mv=0;

$qninv=0;
$qnbuff=0;
$qnnand=0;
$qnand=0;
$qnnor=0;
$qnor=0;

$maj=0;
$mux=0;
$gg=0;
$qmaj=0;
$qmux=0;
$qgg=0;

$area = 0;

@connectionPattern_DNAND = ();
@connectionPattern_DNOR =  ();
@connectionPattern_DOR =  ();
@connectionPattern_DAND = ();
@connectionPattern_DNOT = ();
@connectionPattern_DBUFF = ();

@connectionPattern_QNAND = ();
@connectionPattern_QNOR =  ();
@connectionPattern_QOR =  ();
@connectionPattern_QAND = ();
@connectionPattern_QNOT = ();
@connectionPattern_QMAJ = ();
@connectionPattern_MAJ = ();

#############################################################
#	Scaling Variables										#
#############################################################
$scaling_all_pmos_nand = 2.4;
$scaling_not_2 = 2.8;
$scaling_nand_23 = 3.1;
$scaling_nand_34 = 4.1;
$scaling_nand_45 = 5.1;

$scaling_quad_not = 2.8;
$scaling_quad_nand2 = 3.1;
$scaling_quad_nand3 = 4.1;
$scaling_quad_nand4 = 5.1;

$scaling_all_nmos_nor = 2;
$scaling_nor_23 = 4.4;
$scaling_nor_34 = 6.2;
$scaling_nor_45 = 7.5;

$scaling_quad_nor2 = 6;
$scaling_quad_nor3 = 6.2;
$scaling_quad_nor4 = 7.5;

$scaling_DGG = 25;
$scaling_DGG2 = 26.5;
#############################################################

#########################################################
#	Basic Dimensions of a transistor					#
#########################################################
$ll = 0.13;
$vdd = 1.3;

$WN = 2*$ll;
$WP = 4*$ll;
#########################################################

$WN1 = $scaling_all_nmos_nor*$WN;
$WP1 = $scaling_all_pmos_nand*$WP;

$WN2 = $scaling_nand_23*$WN;
$WP2 = $scaling_nor_23*$WP;

$WN3 = $scaling_nand_34*$WN;
$WP3 = $scaling_nor_34*$WP;

$WN4 = $scaling_nand_45*$WN;
$WP4 = $scaling_nor_45*$WP;

$WN5 = $scaling_quad_nand2*$WN;
$WP5 = $scaling_quad_nor2*$WP;

$WN6 = $scaling_quad_nand3*$WN;
$WP6 = $scaling_quad_nor3*$WP;

$WN7 = $scaling_quad_nand4*$WN;
$WP7 = $scaling_quad_nor4*$WP;

$WN8 = $scaling_nor_24*$WN;
$WP8 = $scaling_DGG*$WP;
$WP9 = $scaling_DGG2*$WP;

$nmos = "GND NMOS W=WN L=ll"; # AD='2*ll*WN' AS='2*ll*WN' PD='2*(ll+WN)' PS='2*(ll+WN)'";
$pmos = "VDD PMOS W=WP L=ll"; # AD='2*ll*WP' AS='2*ll*WP' PD='2*(ll+WP)' PS='2*(ll+WP)'";

$nmos1 = "GND NMOS W=WN1 L=ll"; # AD='2*ll*WN' AS='2*ll*WN' PD='2*(ll+WN)' PS='2*(ll+WN)'";
$pmos1 = "VDD PMOS W=WP1 L=ll"; # AD='2*ll*WP' AS='2*ll*WP' PD='2*(ll+WP)' PS='2*(ll+WP)'";

$nmos2 = "GND NMOS W=WN2 L=ll"; # AD='2*ll*WN' AS='2*ll*WN' PD='2*(ll+WN)' PS='2*(ll+WN)'";
$pmos2 = "VDD PMOS W=WP2 L=ll"; # AD='2*ll*WP' AS='2*ll*WP' PD='2*(ll+WP)' PS='2*(ll+WP)'";

$nmos3 = "GND NMOS W=WN3 L=ll"; # AD='2*ll*WN' AS='2*ll*WN' PD='2*(ll+WN)' PS='2*(ll+WN)'";
$pmos3 = "VDD PMOS W=WP3 L=ll"; # AD='2*ll*WP' AS='2*ll*WP' PD='2*(ll+WP)' PS='2*(ll+WP)'";

$nmos4 = "GND NMOS W=WN4 L=ll"; # AD='2*ll*WN' AS='2*ll*WN' PD='2*(ll+WN)' PS='2*(ll+WN)'";
$pmos4 = "VDD PMOS W=WP4 L=ll"; # AD='2*ll*WP' AS='2*ll*WP' PD='2*(ll+WP)' PS='2*(ll+WP)'";

$nmos5 = "GND NMOS W=WN5 L=ll"; # AD='2*ll*WN' AS='2*ll*WN' PD='2*(ll+WN)' PS='2*(ll+WN)'";
$pmos5 = "VDD PMOS W=WP5 L=ll"; # AD='2*ll*WP' AS='2*ll*WP' PD='2*(ll+WP)' PS='2*(ll+WP)'";

$nmos6 = "GND NMOS W=WN6 L=ll"; # AD='2*ll*WN' AS='2*ll*WN' PD='2*(ll+WN)' PS='2*(ll+WN)'";
$pmos6 = "VDD PMOS W=WP6 L=ll"; # AD='2*ll*WN' AS='2*ll*WN' PD='2*(ll+WN)' PS='2*(ll+WN)'";

$nmos7 = "GND NMOS W=WN7 L=ll"; # AD='2*ll*WN' AS='2*ll*WN' PD='2*(ll+WN)' PS='2*(ll+WN)'";
$pmos7 = "VDD PMOS W=WP7 L=ll"; # AD='2*ll*WN' AS='2*ll*WN' PD='2*(ll+WN)' PS='2*(ll+WN)'";

$pmos8 = "VDD PMOS W=WP8 L=ll"; # AD='2*ll*WN' AS='2*ll*WN' PD='2*(ll+WN)' PS='2*(ll+WN)'";
$pmos9 = "VDD PMOS W=WP9 L=ll"; # AD='2*ll*WN' AS='2*ll*WN' PD='2*(ll+WN)' PS='2*(ll+WN)'";

print OUT_TEMP "module $circuit (";

while(<IN>){
   
	# Matching Inputs   
	if (/^#/) {
		next;
	}
	
	
	elsif (/INPUT\((.*)\)/) {          
		$INPUT[$in]=$1;
	    $flag{$INPUT[$in]}=1;
	    $in++;		           
	}

	
	# Matching Outputs
	elsif (/OUTPUT\((.*)\)/) {
		$TOUT[$tout]=$1;
		$tout++;
	}	    
         
	
	# Matching NOT gates	
    elsif (/(.*) = NOT\((.*)\)/) {
		
		$i=0;		
		$INV[$i][0]=$1;	#output is stored here
		$INV[$i][1]=$2;	#first input is stored here							
		
		print OUT2 $INV[$i][0]."\n";
		
		print OUT "not nnot0_".$ninv."(".$INV[$i][0].", ".$INV[$i][1]."); \n";			
		
		#################
		#	Update Area	#
		#################
		$trans += 2;	
		$totalGates++;
		$tempArea += $WN + $WP;
		print OUT_AREA "$totalGates nnot".$ninv." $tempArea\n";	
		
		$ninv++;		
	}

	
	# Matching NOT11 gates	
    elsif (/\bNOT11\b/i) {
		
		my @gateList = ($_ =~ m/(\w+\d)/g);			#Read All the Gates
		my @gateName = ($_ =~ m/(\w+)\(/i);	 #Read the gate Name i.e. NOT		
		
		my @gateList = ($_ =~ m/\w+/g);		
		
		$i=0;				
		$INV[$i][0] = $gateList[0]; #output is stored here
		$INV[$i][1] = $gateList[2];	#first input is stored here							
		
		print OUT2 $INV[$i][0]."\n";
		
		print OUT "not NOT1_".$ninv."(".$INV[$i][0].", ".$INV[$i][1]."); \n";			
		
		#################
		#	Update Area	#
		#################
		$trans += 3;	
		$totalGates++;
		$tempArea += $WN + 2*$WP1;
		print OUT_AREA "$totalGates NOT1_".$ninv." $tempArea\n";	
		
		$ninv++;		
	}
	
	
	# Matching NOT12 gates	
    elsif (/\bNOT12\b/i) {
		
		my @gateList = ($_ =~ m/(\w+\d)/g);			#Read All the Gates
		my @gateName = ($_ =~ m/(\w+)\(/i);	 #Read the gate Name i.e. NOT		
		
		my @gateList = ($_ =~ m/\w+/g);		
		
		# print "GL: @gateList, GN: @gateName\n";  exit;
		$i=0;				
		$INV[$i][0] = $gateList[0]; #output is stored here
		$INV[$i][1] = $gateList[2];	#first input is stored here													
		
		print OUT2 $INV[$i][0]."\n";
		
		print OUT "not NOT2_".$ninv."(".$INV[$i][0].", ".$INV[$i][1]."); \n";			
		
		#################
		#	Update Area	#
		#################
		$trans += 3;	
		$totalGates++;
		$tempArea += 2*$WN1 + $WP;
		print OUT_AREA "$totalGates NOT2_".$ninv." $tempArea\n";	
		
		$ninv++;		
	}
	
	
	# Matching NAND gates	
	elsif (/\bNAND\b/i) {	
		my @gateList = ($_ =~ m/(\w+\d)/g);			#Read All the Gates
		my @gateName = ($_ =~ m/(\w+)\(/i);	 #Read the gate Name i.e. NAND			
		
		my @gateList = ($_ =~ m/\w+/g);				
		@gateList = ($gateList[0], @gateList[2..$#gateList]);	
		
		$i = 0;
		$NAND[$i][0] = scalar @gateList - 1; #number of inputs.
		$NAND[$i][1] = $gateList[0]; #output is stored here		
		
					
		foreach $k (2..scalar @gateList)
		{	$NAND[$i][$k] = $gateList[$k-1];	}			
		
		# print OUT2 $NAND[$i][1]."\n";
		print OUT2 $NAND[$i][1]."\n";
		
		print OUT "nand nnand$NAND[$i][0]_".$nnand."($NAND[$i][1], ";
		for ($j=0; $j < $NAND[$i][0] ; $j++){
			if ($j == $NAND[$i][0]-1){
				print OUT $NAND[$i][2+$j]."); ";
			} else {
				print OUT $NAND[$i][2+$j].", ";
			}
		}	
		
		print OUT "\n";
		
		#################
		#  Update Area	#
		#################
		$trans += $NAND[0][0]*2;		
		$totalGates++;
		$tempArea += $NAND[0][0]*$WN + $NAND[0][0]*$WP;
		print OUT_AREA "$totalGates nnand".$nnand." $tempArea\n";
		
		$nnand++;
    }
	
 	
	# Matching NAND gates	
	elsif (/\bNAND21|NAND22|NAND23|NAND24|NAND31|NAND32|NAND33|NAND34|NAND35|NAND36|NAND41|NAND42|NAND43|NAND44|NAND45|NAND46|NAND47|NAND48\b/i) {	
		
		my @gateList = ($_ =~ m/(\w+\d)/g);			#Read All the Gates
		my @gateName = ($_ =~ m/(\w+)\(/i);	 #Read the gate Name i.e. NAND		
		
		my @gateList = ($_ =~ m/\w+/g);				
		# @gateList = ($gateList[0], @gateList[2..$#gateList]);	
		
		$i = 0;
		$NAND[$i][0] = scalar @gateList - 2; #number of inputs.
		$NAND[$i][1] = $gateList[0]; #output is stored here		
			
		foreach $k (3..scalar @gateList)
		{	$NAND[$i][$k] = $gateList[$k-1];	}			
		
		print OUT2 $NAND[$i][1]."\n";
		
		print OUT "nand $gateList[1]_".$nnand."($NAND[$i][1], ";
		for ($j=0; $j < $NAND[$i][0] ; $j++){
			if ($j == $NAND[$i][0]-1){
				print OUT $NAND[$i][3+$j]."); ";
			} else {
				print OUT $NAND[$i][3+$j].", ";
			}
		}	
		
		#####################################################
		#  Update Area										#
		#####################################################
		if ($gateList[1] eq 'NAND21') {
			$trans += 5;		
			$totalGates++;
			$tempArea += $NAND[0][0]*$WN + 2*$WP1 + $WP;			
		}
		elsif ($gateList[1] eq 'NAND22') {
			$trans += 6;		
			$totalGates++;
			$tempArea += $NAND[0][0]*$WN + 4*$WP1;			
		}
		elsif ($gateList[1] eq 'NAND23') {
			$trans += 6;		
			$totalGates++;
			$tempArea += 4*$WN2 + 2*$WP;			
		}
		elsif ($gateList[1] eq 'NAND24') {
			$trans += 7;		
			$totalGates++;
			$tempArea += 4*$WN5 + 2*$WP1 + $WP;			
		}
		elsif ($gateList[1] eq 'NAND31') {
			$trans += 7;		
			$totalGates++;
			$tempArea += $NAND[0][0]*$WN + 2*$WP1 + 2*$WP;			
		}
		elsif ($gateList[1] eq 'NAND32') {
			$trans += 8;		
			$totalGates++;
			$tempArea += $NAND[0][0]*$WN + 4*$WP1 + $WP;			
		}
		elsif ($gateList[1] eq 'NAND33') {
			$trans += 9;		
			$totalGates++;
			$tempArea += $NAND[0][0]*$WN + 6*$WP1;			
		}
		elsif ($gateList[1] eq 'NAND34') {
			$trans += 9;		
			$totalGates++;
			$tempArea += 6*$WN3 + 3*$WP;			
		}
		elsif ($gateList[1] eq 'NAND35') {
			$trans += 10;		
			$totalGates++;
			$tempArea += 6*$WN3 + 2*$WP1 + 2*$WP;			
		}
		elsif ($gateList[1] eq 'NAND36') {
			$trans += 11;		
			$totalGates++;
			$tempArea += 6*$WN6 + 4*$WP1 + $WP;			
		}
		elsif ($gateList[1] eq 'NAND41') {
			$trans += 9;		
			$totalGates++;
			$tempArea += $NAND[0][0]*$WN + 2*$WP1 + 3*$WP;			
		}
		elsif ($gateList[1] eq 'NAND42') {
			$trans += 10;		
			$totalGates++;
			$tempArea += $NAND[0][0]*$WN + 4*$WP1 + 2*$WP;			
		}
		elsif ($gateList[1] eq 'NAND43') {
			$trans += 11;		
			$totalGates++;
			$tempArea += $NAND[0][0]*$WN + 6*$WP1 + $WP;			
		}
		elsif ($gateList[1] eq 'NAND44') {
			$trans += 12;		
			$totalGates++;
			$tempArea += $NAND[0][0]*$WN + 8*$WP1;			
		}
		elsif ($gateList[1] eq 'NAND45') {
			$trans += 12;		
			$totalGates++;
			$tempArea += 8*$WN4 + 4*$WP;			
		}
		elsif ($gateList[1] eq 'NAND46') {
			$trans += 13;		
			$totalGates++;
			$tempArea += 8*$WN4 + 2*$WP1 + 3*$WP;			
		}
		elsif ($gateList[1] eq 'NAND47') {
			$trans += 14;		
			$totalGates++;
			$tempArea += 8*$WN4 + 4*$WP1 + 2*$WP;			
		}
		elsif ($gateList[1] eq 'NAND48') {
			$trans += 15;		
			$totalGates++;
			$tempArea += 8*$WN7 + 6*$WP1 + $WP;			
		}		
		
				
		print OUT_AREA "$totalGates $gateList[1]_".$nnand." $tempArea\n";
		
		$nnand++;
		print OUT "\n";
    }
	
		
	#Matching NOR gates		
	elsif (/\bNOR\b/i) {	
		my @gateList = ($_ =~ m/(\w+\d)/g);			#Read All the Gates
		my @gateName = ($_ =~ m/(\w+)\(/i);	 #Read the gate Name i.e. NOR					
				
		my @gateList = ($_ =~ m/\w+/g);				
		@gateList = ($gateList[0], @gateList[2..$#gateList]);	
		
		$i=0;
		$NOR[$i][0] = scalar @gateList - 1; #number of inputs.
		$NOR[$i][1] = $gateList[0]; #output is stored here		
			
		foreach $k (2..scalar @gateList)
		{	$NOR[$i][$k] = $gateList[$k-1];	}			                  				
				
		# print OUT2 $NOR[$i][1]."\n";
		print OUT2 $NOR[$i][1]."\n";
		
		print OUT "nor nnor$NOR[$i][0]_".$nnor."($NOR[$i][1], ";
		for ($j=0; $j < $NOR[$i][0] ; $j++){
			if ($j == $NOR[$i][0]-1){
				print OUT $NOR[$i][2+$j]."); ";
			} else {
				print OUT $NOR[$i][2+$j].", ";
			}
		}	
		
		#################
		#  Update Area	#
		#################
		$trans += $NOR[0][0]*2;		
		$totalGates++;
		$tempArea += $NOR[0][0]*$WN + $NOR[0][0]*$WP;
		print OUT_AREA "$totalGates nnor".$nnor." $tempArea\n";
		
		$nnor++;
		print OUT "\n";
	}
	
	
	#Matching NOR gates		
	elsif (/\bNOR21|NOR22|NOR23|NOR24|NOR31|NOR32|NOR33|NOR34|NOR35|NOR36|NOR41|NOR42|NOR43|NOR44|NOR45|NOR46|NOR47|NOR48\b/i) {	
		
		my @gateList = ($_ =~ m/(\w+\d)/g);			#Read All the Gates
		my @gateName = ($_ =~ m/(\w+)\(/i);	 #Read the gate Name i.e. NOR					
				
		my @gateList = ($_ =~ m/\w+/g);				
		# @gateList = ($gateList[0], @gateList[2..$#gateList]);	
		
		$i=0;
		$NOR[$i][0] = scalar @gateList - 2; #number of inputs.
		$NOR[$i][1] = $gateList[0]; #output is stored here		
			
		foreach $k (3..scalar @gateList)
		{	$NOR[$i][$k] = $gateList[$k-1];	}			                  				
				
		# print OUT2 $NOR[$i][1]."\n";
		print OUT2 $NOR[$i][1]."\n";
		
		print OUT "nor $gateList[1]_".$nnor."($NOR[$i][1], ";
		for ($j=0; $j < $NOR[$i][0] ; $j++){
			if ($j == $NOR[$i][0]-1){
				print OUT $NOR[$i][3+$j]."); ";
			} else {
				print OUT $NOR[$i][3+$j].", ";
			}
		}
		
		
		#####################################################
		#  Update Area										#
		#####################################################
		if ($gateList[1] eq 'NOR21') {
			$trans += 5;		
			$totalGates++;
			$tempArea += 2*$WN1 + $WN + 2*$WP;			
		}
		elsif ($gateList[1] eq 'NOR22') {
			$trans += 6;		
			$totalGates++;
			$tempArea += 4*$WN1 + 2*$WP;			
		}
		elsif ($gateList[1] eq 'NOR23') {
			$trans += 6;		
			$totalGates++;
			$tempArea += 2*$WN + 4*$WP2;			
		}
		elsif ($gateList[1] eq 'NOR24') {
			$trans += 7;		
			$totalGates++;
			$tempArea += 2*$WN1 + $WN + 4*$WP2;			
		}
		elsif ($gateList[1] eq 'NOR31') {
			$trans += 7;		
			$totalGates++;
			$tempArea += 2*$WN1 + 2*$WN + 3*$WP;				
		}
		elsif ($gateList[1] eq 'NOR32') {
			$trans += 8;		
			$totalGates++;
			$tempArea += 4*$WN1 + $WN + 3*$WP;			
		}
		elsif ($gateList[1] eq 'NOR33') {
			$trans += 9;		
			$totalGates++;
			$tempArea += 6*$WN1 + 3*$WP;			
		}
		elsif ($gateList[1] eq 'NOR34') {
			$trans += 9;		
			$totalGates++;
			$tempArea += 3*$WN + 6*$WP3;			
		}
		elsif ($gateList[1] eq 'NOR35') {
			$trans += 10;		
			$totalGates++;
			$tempArea += 2*$WN1 + 2*$WN + 6*$WP6;			
		}
		elsif ($gateList[1] eq 'NOR36') {
			$trans += 11;		
			$totalGates++;
			$tempArea += 4*$WN1 + $WN + 6*$WP6;			
		}
		elsif ($gateList[1] eq 'NOR41') {
			$trans += 9;		
			$totalGates++;
			$tempArea += 2*$WN1 + 3*$WN + 4*$WP;			
		}
		elsif ($gateList[1] eq 'NOR42') {
			$trans += 10;		
			$totalGates++;
			$tempArea += 4*$WN1 + 2*$WN + 4*$WP;			
		}
		elsif ($gateList[1] eq 'NOR43') {
			$trans += 11;		
			$totalGates++;
			$tempArea += 6*$WN1 + $WN + 4*$WP;			
		}
		elsif ($gateList[1] eq 'NOR44') {
			$trans += 12;		
			$totalGates++;
			$tempArea += 8*$WN1 + 4*$WP;			
		}
		elsif ($gateList[1] eq 'NOR45') {
			$trans += 12;		
			$totalGates++;
			$tempArea += 4*$WN + 8*$WP4;						
		}
		elsif ($gateList[1] eq 'NOR46') {
			$trans += 13;		
			$totalGates++;
			$tempArea += 2*$WN1 + 3*$WN + 8*$WP4;			
		}
		elsif ($gateList[1] eq 'NOR47') {
			$trans += 14;		
			$totalGates++;
			$tempArea += 4*$WN1 + 2*$WN + 8*$WP4;			
		}
		elsif ($gateList[1] eq 'NOR48') {
			$trans += 15;		
			$totalGates++;
			$tempArea += 6*$WN1 + $WN + 8*$WP4;			
		}
		
		print OUT_AREA "$totalGates $gateList[1]_".$nnor." $tempArea\n";
		
		$nnor++;
		print OUT "\n";				
	}
	
	
	# Matching DNOT gates	
	elsif (/(.*) = DNOT\((.*)\)/) {		
		
		$i=0;		
		$QINV[$i][0]=$1;	#output is stored here
		$QINV[$i][1]=$2;	#first input is stored here							
		
		print OUT2 $QINV[$i][0]."\n";
		
		print OUT "not dnot".$qninv."(".$QINV[$i][0].", ".$QINV[$i][1]."); \n";		
				
		#################
		#	Update Area	#
		#################
		$trans += 4;	
		$totalGates++;
		$tempArea += 2*$WN1 + 2*$WP1;
		print OUT_AREA "$totalGates qnot".$qninv." $tempArea\n";	
		
		$qninv++;
	}
	
	
	# Matching DNAND gates	
	elsif (/\bDNAND\b/i) {		
		
		my @gateList = ($_ =~ m/(\w+\d)/g);			#Read All the Gates
		my @gateName = ($_ =~ m/(\w+)\(/i);  		#Read the gate Name i.e. QNAND				
		my @allGates = ($_ =~ m/\((\w.*)\)/ig);  	#Read all Gates including 's' and 'p' keywords										
				
		my @gateList = ($_ =~ m/\w+/g);				
		@gateList = ($gateList[0], @gateList[2..$#gateList]);	
		
		$i=0;
		$QNAND[$i][0] = scalar @gateList - 1; #number of inputs.
		$QNAND[$i][1] = $gateList[0]; #output is stored here		
			
		foreach $k (2..scalar @gateList)
		{	$QNAND[$i][$k] = $gateList[$k-1];	}							
			
		print OUT2 $QNAND[$i][1]."\n";
		print OUT "nand dnand".$qnnand."($QNAND[$i][1], ";
		for ($j=0; $j < $QNAND[$i][0] ; $j++){
			if ($j == $QNAND[$i][0]-1){
				print OUT $QNAND[$i][2+$j].");";# //QNAND\n";
			} else {
				print OUT $QNAND[$i][2+$j].", ";
			}
		}			
		
		print OUT "\n";
		#################
		#  Update Area	#
		#################
		$currentWN = ();
		if($QNAND[0][0] == 2) {		
			$currentWN = $WN5;
		}
		elsif($QNAND[0][0] == 3) {			
			$currentWN = $WN6;
		}
		elsif($QNAND[0][0] == 4) {			
			$currentWN = $WN7;
		}
		
		$trans += $QNAND[0][0]*4;		
		$totalGates++;
		$tempArea += 2*(scalar @gateList - 1)*$currentWN + 2*(scalar @gateList - 1)*$WP1;
		print OUT_AREA "$totalGates qnand".$qnand." $tempArea\n";
		
		$qnnand++;
	}
		
		
	# Matching DNOR gates		
	elsif (/\bDNOR\b/i) {				
		my @gateList = ($_ =~ m/(\w+\d)/g);			#Read All the Gates
		my @gateName = ($_ =~ m/(\w+)\(/i);  		#Read the gate Name i.e. QNAND				
		my @allGates = ($_ =~ m/\((\w.*)\)/ig);  	#Read all Gates including 's' and 'p' keywords			
		
		my @gateList = ($_ =~ m/\w+/g);				
		@gateList = ($gateList[0], @gateList[2..$#gateList]);	
		
		$i=0;
		$QNOR[$i][0] = scalar @gateList - 1; #number of inputs.
		$QNOR[$i][1] = $gateList[0]; #output is stored here		
			
		foreach $k (2..scalar @gateList)
		{	$QNOR[$i][$k] = $gateList[$k-1];	}				
		
		print OUT2 $QNOR[$i][1]."\n";
		print OUT "nor dnor".$qnnor."($QNOR[$i][1], ";
		for ($j=0; $j < $QNOR[$i][0] ; $j++){
			if ($j == $QNOR[$i][0]-1){
				print OUT $QNOR[$i][2+$j].");";# //QNOR\n";
			} else {
				print OUT $QNOR[$i][2+$j].", ";
			}
		}		
		
		print OUT "\n";
		#################
		#  Update Area	#
		#################
		$currentWP = ();
		if($QNOR[0][0] == 2) {
			$currentWP = $WP2;
		}
		elsif($QNOR[0][0] == 3) {
			$currentWP = $WP6;
		}
		elsif($QNOR[0][0] == 4) {
			$currentWP = $WP7;
		}
		
		$trans += $QNOR[$i][0]*4;		
		$totalGates++;
		$tempArea += 2*(scalar @gateList - 1)*$WN1 + 2*(scalar @gateList - 1)*$currentWP;
		print OUT_AREA "$totalGates qnor".$qnnor." $tempArea\n";
		
		$qnnor++;
	}        
	
	
	# Matching DOR/OR gates of C-Element
	elsif (/\bOR\b/i) {				
		my @gateList = ($_ =~ m/(\w+\d)/g);			#Read All the Gates
		my @gateName = ($_ =~ m/(\w+)\(/i);  		#Read the gate Name i.e. QNAND				
				
		my @gateList = ($_ =~ m/\w+/g);				
		@gateList = ($gateList[0], @gateList[2..$#gateList]);	
		
		$i=0;
		$OR[$i][0] = scalar @gateList - 1; #number of inputs.
		$OR[$i][1] = $gateList[0]; #output is stored here		
			
		foreach $k (2..scalar @gateList)
		{	$OR[$i][$k] = $gateList[$k-1];	}				
		
		print OUT2 $OR[$i][1]."\n";
		print OUT "or or".$nor."($OR[$i][1], ";
		for ($j=0; $j < $OR[$i][0] ; $j++){
			if ($j == $OR[$i][0]-1){
				print OUT $OR[$i][2+$j].");";# //OR\n";
			} else {
				print OUT $OR[$i][2+$j].", ";
			}
		}		
		
		print OUT "\n";
		
		#################
		#  Update Area	#
		#################		
		$trans += 12; 
		$totalGates++;
		
		$tempArea += 4.68; 
		print OUT_AREA "$totalGates or".$nor." $tempArea\n";
		
		$nor++;
	}       
	
	
	# Matching DOR gates of C-Element
	elsif (/\bDOR\b/i) {				
		
		my @gateList = ($_ =~ m/(\w+\d)/g);			#Read All the Gates
		my @gateName = ($_ =~ m/(\w+)\(/i);  		#Read the gate Name i.e. QNAND				
				
		my @gateList = ($_ =~ m/\w+/g);				
		@gateList = ($gateList[0], @gateList[2..$#gateList]);	
		
		$i=0;
		$OR[$i][0] = scalar @gateList - 1; #number of inputs.
		$OR[$i][1] = $gateList[0]; #output is stored here		
			
		foreach $k (2..scalar @gateList)
		{	$OR[$i][$k] = $gateList[$k-1];	}				
		
		print OUT2 $OR[$i][1]."\n";
		print OUT "or dor".$nor."($OR[$i][1], ";
		for ($j=0; $j < $OR[$i][0] ; $j++){
			if ($j == $OR[$i][0]-1){
				print OUT $OR[$i][2+$j].");";# //OR\n";
			} else {
				print OUT $OR[$i][2+$j].", ";
			}
		}		
		
		print OUT "\n";
		
		#################
		#  Update Area	#
		#################		
		$trans += 24; 
		$totalGates++;
		
		$tempArea += 21.216; 
		print OUT_AREA "$totalGates or".$nor." $tempArea\n";
		
		$nor++;
	}       	
	
		
} #End of File reading.

#computing proper output signals

for ($i=0; $i<$tout; $i++){
        $outn=$TOUT[$i];
	if ($flago{$outn}!=1){
	    	$flago{$outn}=1;
            	$OUTPUT[$out]=$outn;
		if ($flag{$outn}==1){
			$INOUT[$ino]=$outn;
			$ino++;
		}
	    	$out++;		           
	}	
}


# printing module statement

for ($i=0; $i < $in; $i++){
	print OUT_TEMP $INPUT[$i].", ";
}


for ($i=0; $i < $out; $i++){
	if ($flag{$OUTPUT[$i]}==1){
		print OUT_TEMP $OUTPUT[$i];
	}
	else{
		print OUT_TEMP $OUTPUT[$i];
	}
	if ($i != $out-1) {
           print OUT_TEMP ", ";
        } else {
	   print OUT_TEMP ") ;\n";
	}
}
print OUT "\n";        

#printint output signals

print OUT_TEMP "\noutput ";
for ($i=0; $i < $out; $i++){
	if ($flag{$OUTPUT[$i]}==1){
		print OUT_TEMP $OUTPUT[$i];
	}
	else{
		print OUT_TEMP $OUTPUT[$i];
	}
	if ($i != $out-1) {
           print OUT_TEMP ", ";
        } else {
	   print OUT_TEMP " ;\n";
	}
}


#printing input signals

print OUT_TEMP "input ";
for ($i=0; $i < $in; $i++){
	print OUT_TEMP $INPUT[$i];
	if ($i != $in-1) {
           print OUT_TEMP ", ";
        } else {
	   print OUT_TEMP ";\n";
	}
}

print OUT_TEMP "\n";
print OUT_TEMP "supply1 VDD;\n";             
print OUT_TEMP "supply0 GND;\n\n";

print OUT "endmodule";
        
close(IN);
close(OUT_TEMP);
close(OUT);
close(OUT2);

open(IN,"test".".v") || die " Cannot open input file $circuit".".v \n";
open(OUT,">>$circuit".".v") || die " Cannot open input file $circuit".".v \n";

while (<IN>) {
	print OUT $_;
}
close(IN);
close(OUT);

close(OUT_AREA);

#delete the temporary test file.
system ("del test.v");

$end=time;
$diff = $end - $start;

open(AREA,">trans".".temp") || die " Cannot open input file $circuit".".v \n";
print AREA "$trans $totalGates";
close(AREA);

#write area to a file
open(OUT2,">area.sp") || die " Cannot open input file area.sp \n";
print OUT2 $tempArea;
close (OUT2);

# print "Number of inputs = $in \n";
# print "Number of outputs= $out \n";
# print "Number of inout pins =$ino \n";
# print "Number of INV gates= $ninv \n";
# print "Number of BUFF gates= $nbuff \n";
# print "Number of NAND gates= $nnand \n";
# print "Number of AND gates= $nand \n";
# print "Number of NOR gates= $nnor \n";
# print "Number of OR gates= $nor \n\n";

# print "Number of DINV gates= $dninv \n";
# print "Number of DBUFF gates= $dnbuff \n";
# print "Number of DNAND gates= $dnnand \n";
# print "Number of DAND gates= $dnand \n";
# print "Number of DNOR gates= $dnnor \n";
# print "Number of DOR gates= $dnor \n\n";

# print "Number of QINV gates= $qninv \n";
# print "Number of QBUFF gates= $qnbuff \n";
# print "Number of QNAND gates= $qnnand \n";
# print "Number of QAND gates= $qnand \n";
# print "Number of QNOR gates= $qnnor \n";
# print "Number of QOR gates= $qnor \n\n";

# print "Transistors==============> $trans \n";
# print "Gates==============> $totalGates \n\n";

# print "Execution time is $diff seconds \n";

#! /usr/bin/perl 

###############################################################
#                                                             #
# Description: A perl script to convert from bench format     #
#              to spice.							          #
#                                                             #
#                                                             #
# Updated by: Ahmad Tariq Sheikh (KFUPM)    				  # 	
#															  #		
#															  #		
# Date: September 7, 2014.	                                  #
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
open(OUT,">$circuit".".sp") || die " Cannot open input file $circuit".".v \n";
open(OUT_TEMP,">test".".sp") || die " Cannot open input file $circuit".".v \n";
open(OUT_AREA,">tranarea".".DAT") || die " Cannot open input file $circuit".".v \n";


$in = 0; #number of inouts
$out = 0; #number of outputs
$ino = 0;	#nuber of inout pins
$tout=0;
$tran = 0;
$tempArea=0;

$ninv=0;
$nnand=0;
$nand=0;
$nnor=0;
$nor=0;

$area = 0;

#########################################################
#	Basic Dimensions of a transistor					#
#########################################################
$ll = 0.09;
$vdd = 1.2;

$WN = 2*$ll;
$WP = 4*$ll;
#########################################################

$nmos = "GND NMOS W=WN L=ll"; # AD='2*ll*WN' AS='2*ll*WN' PD='2*(ll+WN)' PS='2*(ll+WN)'";
$pmos = "VDD PMOS W=WP L=ll"; # AD='2*ll*WP' AS='2*ll*WP' PD='2*(ll+WP)' PS='2*(ll+WP)'";


while(<IN>){
   
	# Matching Inputs   
	if (/^#/) {
		next;
	}
	
	
	if (/INPUT\((.*)\)/) {          
		$INPUT[$in]=$1;
	    $flag{$INPUT[$in]}=1;
	    $in++;		           
	}

	
	# Matching Outputs
	if (/OUTPUT\((.*)\)/) {
		$TOUT[$tout]=$1;
		$tout++;
	}	    
         
	
	# Matching NOT gates	
    if (/(.*) = NOT\((.*)\)/) {
		
		$i=0;		
		$INV[$i][0]=$1;	#output is stored here
		$INV[$i][1]=$2;	#first input is stored here					
		
		if ($d == 1) {
			print OUT "\n*N$_";
		}

		#  nmos transistor
		print OUT "M_not".$ninv."_1 N".$INV[$i][0]." N".$INV[$i][1]." GND $nmos\n";
		$tran++;
		$tempArea += $WN;
		print OUT_AREA "$tran $tempArea\n";
		
		#  pmos transistors
		print OUT "M_not".$ninv."_2 N".$INV[$i][0]." N".$INV[$i][1]." VDD $pmos\n\n";
				
		$ninv++;
		$area += $WN + $WP;		
		
		$tran++;
		$tempArea += $WP;
		print OUT_AREA "$tran $tempArea\n";
	}

		
	#Matching OR gates		
	if (/\bOR\b/i) {	
		my @gateList = ($_ =~ m/(\w+\d)/g);	 #Read All the Gates
		my @gateName = ($_ =~ m/(\w+)\(/i);	 #Read the gate Name i.e. OR					
		
		my @gateList = ($_ =~ m/\w+/g);				
		@gateList = ($gateList[0], @gateList[2..$#gateList]);
			
		$i=0;
		$NOR[$i][0] = scalar @gateList - 1; #number of inputs.
		$NOR[$i][1] = $gateList[0]; #output is stored here		
			
		foreach $k (2..scalar @gateList)
		{	$NOR[$i][$k] = $gateList[$k-1];	}			                  				
				
		if ($d == 1) {	
		print OUT "\n*N".$NOR[$i][1]." = OR( ";
			for ($j=0; $j < $NOR[$i][0] ; $j++){
				if ($j == $NOR[$i][0]-1){
					print OUT "N".$NOR[$i][2+$j]." ) \n";
				} else {
					print OUT "N".$NOR[$i][2+$j].", ";
				}
			}
		}

		$i=0;
		$j=0;
		# printing the nmos transistors
		for ($k=0; $k < $NOR[$i][0] ; $k++) {
			print OUT "M_nnnor".$or."_".($k+1)." N".$NOR[$i][1]."_TEMP N".$NOR[$i][$k+2]." GND $nmos \n";	
			$count++;
			$tran++;
			$tempArea += $WN;
			print OUT_AREA "$tran $tempArea\n";					
		}
		
		if ($d == 1) {
			print OUT "\n";
		}

		# printing the pmos transistors
		print OUT "M_nnnor".$or."_".($tran+1)." N".$NOR[$i][1]."_TEMP N".$NOR[$i][$j+2]." nr".$or."_".($j+1)." $pmos\n";	
		$tran++;
		$tempArea += $WP;
		print OUT_AREA "$tran $tempArea\n";
			
		for ($j=1; $j < $NOR[$i][0]-1 ; $j++) {
			print OUT "M_nnnor".$or."_".($tran+1)." nr".$or."_".($j)." N".$NOR[$i][$j+2]." nr".$or."_".($j+1)." $pmos\n";
			$tran++;
			$tempArea += $WP;
			print OUT_AREA "$tran $tempArea\n";		
        }
		
		$j = ($NOR[$i][0]-2);	
		print OUT "M_nnnor".$or."_".($tran+1)." nr".$or."_".($j+1)." N".$NOR[$i][$j+3]." VDD $pmos\n";
		$tran++;
		$tempArea += $WP;
		print OUT_AREA "$tran $tempArea\n";				
		
		$or++;
		$area += (scalar @gateList - 1)*$WN + (scalar @gateList - 1)*$WP;
		
		#  nmos transistor
		print OUT "\n";
		print OUT "M_not".$ninv."_1 N".$NOR[$i][1]." N".$NOR[$i][1]."_TEMP GND $nmos\n";
		$tran++;
		$tempArea += $WN;
		print OUT_AREA "$tran $tempArea\n";
		
		#  pmos transistors
		print OUT "M_not".$ninv."_2 N".$NOR[$i][1]." N".$NOR[$i][1]."_TEMP VDD $pmos\n";
		$tran++;
		$tempArea += $WP;
		print OUT_AREA "$tran $tempArea\n";
		
		$ninv++;
		$area += $WN + $WP;			
	}
		
	
	# Matching AND gates	
	if (/\bAND\b/i) {	
		my @gateList = ($_ =~ m/(\w+\d)/g);			#Read All the Gates
		my @gateName = ($_ =~ m/(\w+)\(/i);	 #Read the gate Name i.e. NAND		
		
		my @gateList = ($_ =~ m/\w+/g);				
		@gateList = ($gateList[0], @gateList[2..$#gateList]);
		
		$i = 0;
		$NAND[$i][0] = scalar @gateList - 1; #number of inputs.
		$NAND[$i][1] = $gateList[0]; #output is stored here		
			
		foreach $k (2..scalar @gateList)
		{	$NAND[$i][$k] = $gateList[$k-1];	}			
		
		if ($d == 1) {		
			print OUT "\n*N".$NAND[$i][1]." = AND( ";
			for ($j=0; $j < $NAND[$i][0] ; $j++){
				if ($j == $NAND[$i][0]-1){
					print OUT "N".$NAND[$i][2+$j]." ) \n";
				} else {
					print OUT "N".$NAND[$i][2+$j].", ";
				}
			}
		}

		# printing the nmos transistors
		$i=0;
		$j=0;
		print OUT "M_nnand".$and."_1 N".$NAND[$i][1]."_TEMP N".$NAND[$i][$j+2]." nd".$and."_".($j+1)." $nmos\n";		
		
		$tran++;
		$tempArea += $WN;
		print OUT_AREA "$tran $tempArea\n";
					
		for ($j=1; $j < $NAND[$i][0]-1 ; $j++){			
			print OUT "M_nnand".$and."_".($j+1)." nd".$and."_".($j)." N".$NAND[$i][$j+2]." nd".$and."_".($j+1)." $nmos\n";								
			$tran++;
			$tempArea += $WN;
			print OUT_AREA "$tran $tempArea\n";
		}

		$j = ($NAND[$i][0]-2);		
		print OUT "M_nnand".$and."_".$NAND[$i][0]." nd".$and."_".($j+1)." N".$NAND[$i][$j+3]." GND $nmos\n";		
		$tran++;
		$tempArea += $WN;
		print OUT_AREA "$tran $tempArea\n";
		
		if ($d == 1) {
			print OUT "\n";
		}

		# printing the pmos transistors		
		for ($k=0; $k < $NAND[$i][0] ; $k++){			
			print OUT "M_nnand".$and."_".($NAND[$i][0]+$k+1)." N".$NAND[$i][1]."_TEMP N".$NAND[$i][$k+2]." VDD $pmos \n";
			$tran++;
			$tempArea += $WP;
			print OUT_AREA "$tran $tempArea\n";
		}	

		$and++;

		#  nmos transistor
		print OUT "\n";
		print OUT "M_not".$ninv."_1 N".$NAND[$i][1]." N".$NAND[$i][1]."_TEMP GND $nmos\n";
		$tran++;
		$tempArea += $WN;
		print OUT_AREA "$tran $tempArea\n";
		
		#  pmos transistors
		print OUT "M_not".$ninv."_2 N".$NAND[$i][1]." N".$NAND[$i][1]."_TEMP VDD $pmos\n";
		$tran++;
		$tempArea += $WP;
		print OUT_AREA "$tran $tempArea\n";
		
		$ninv++;
		$area += $WN + $WP;		
		
		$area += (scalar @gateList - 1)*$WN + (scalar @gateList - 1)*$WP;		
    }
       
	
	# Matching NAND gates	
	if (/\bNAND\b/i) {	
		my @gateList = ($_ =~ m/(\w+\d)/g);			#Read All the Gates
		my @gateName = ($_ =~ m/(\w+)\(/i);	 #Read the gate Name i.e. NAND		
		
		my @gateList = ($_ =~ m/\w+/g);				
		@gateList = ($gateList[0], @gateList[2..$#gateList]);		
		# print "GL :@gateList \n"; exit;
		
		$i = 0;
		$NAND[$i][0] = scalar @gateList - 1; #number of inputs.
		$NAND[$i][1] = $gateList[0]; #output is stored here		
			
		foreach $k (2..scalar @gateList)
		{	$NAND[$i][$k] = $gateList[$k-1];	}			
		
		if ($d == 1) {		
			print OUT "\n*N".$NAND[$i][1]." = NAND( ";
			for ($j=0; $j < $NAND[$i][0] ; $j++){
				if ($j == $NAND[$i][0]-1){
					print OUT "N".$NAND[$i][2+$j]." ) \n";
				} else {
					print OUT "N".$NAND[$i][2+$j].", ";
				}
			}
		}

		# printing the nmos transistors
		$i=0;
		$j=0;
		print OUT "M_nand".$nnand."_1 N".$NAND[$i][1]." N".$NAND[$i][$j+2]." nd".$nnand."_".($j+1)." $nmos\n";		
		
		$tran++;
		$tempArea += $WN;
		print OUT_AREA "$tran $tempArea\n";
					
		for ($j=1; $j < $NAND[$i][0]-1 ; $j++){			
			print OUT "M_nand".$nnand."_".($j+1)." nd".$nnand."_".($j)." N".$NAND[$i][$j+2]." nd".$nnand."_".($j+1)." $nmos\n";								
			$tran++;
			$tempArea += $WN;
			print OUT_AREA "$tran $tempArea\n";
		}

		$j = ($NAND[$i][0]-2);		
		print OUT "M_nand".$nnand."_".$NAND[$i][0]." nd".$nnand."_".($j+1)." N".$NAND[$i][$j+3]." GND $nmos\n";		
		$tran++;
		$tempArea += $WN;
		print OUT_AREA "$tran $tempArea\n";
		
		if ($d == 1) {
			print OUT "\n";
		}

		# printing the pmos transistors		
		for ($k=0; $k < $NAND[$i][0] ; $k++){			
			print OUT "M_nand".$nnand."_".($NAND[$i][0]+$k+1)." N".$NAND[$i][1]." N".$NAND[$i][$k+2]." VDD $pmos \n";
			$tran++;
			$tempArea += $WP;
			print OUT_AREA "$tran $tempArea\n";
		}	

		$nnand++;	
		$area += (scalar @gateList - 1)*$WN + (scalar @gateList - 1)*$WP;		
    }
       
		
	#Matching NOR gates		
	if (/\bNOR\b/i) {	
		my @gateList = ($_ =~ m/(\w+\d)/g);			#Read All the Gates
		my @gateName = ($_ =~ m/(\w+)\(/i);	 #Read the gate Name i.e. NOR					
		
		my @gateList = ($_ =~ m/\w+/g);				
		@gateList = ($gateList[0], @gateList[2..$#gateList]);
		
		$i=0;
		$NOR[$i][0] = scalar @gateList - 1; #number of inputs.
		$NOR[$i][1] = $gateList[0]; #output is stored here		
			
		foreach $k (2..scalar @gateList)
		{	$NOR[$i][$k] = $gateList[$k-1];	}			                  				
				
		if ($d == 1) {	
		print OUT "\n*N".$NOR[$i][1]." = NOR( ";
			for ($j=0; $j < $NOR[$i][0] ; $j++){
				if ($j == $NOR[$i][0]-1){
					print OUT "N".$NOR[$i][2+$j]." ) \n";
				} else {
					print OUT "N".$NOR[$i][2+$j].", ";
				}
			}
		}

		$i=0;
		$j=0;
		# printing the nmos transistors
		for ($k=0; $k < $NOR[$i][0] ; $k++) {
			print OUT "M_nnor".$nnor."_".($k+1)." N".$NOR[$i][1]." N".$NOR[$i][$k+2]." GND $nmos \n";	
			$count++;
			$tran++;
			$tempArea += $WN;
			print OUT_AREA "$tran $tempArea\n";					
		}
		
		if ($d == 1) {
			print OUT "\n";
		}

		# printing the pmos transistors
		print OUT "M_nnor".$nnor."_".($tran+1)." N".$NOR[$i][1]." N".$NOR[$i][$j+2]." nr".$nnor."_".($j+1)." $pmos\n";	
		$tran++;
		$tempArea += $WP;
		print OUT_AREA "$tran $tempArea\n";
			
		for ($j=1; $j < $NOR[$i][0]-1 ; $j++) {
			print OUT "M_nnor".$nnor."_".($tran+1)." nr".$nnor."_".($j)." N".$NOR[$i][$j+2]." nr".$nnor."_".($j+1)." $pmos\n";
			$tran++;
			$tempArea += $WP;
			print OUT_AREA "$tran $tempArea\n";		
        }
		
		$j = ($NOR[$i][0]-2);	
		print OUT "M_nnor".$nnor."_".($tran+1)." nr".$nnor."_".($j+1)." N".$NOR[$i][$j+3]." VDD $pmos\n";
		$tran++;
		$tempArea += $WP;
		print OUT_AREA "$tran $tempArea\n";				
		
		$nnor++;
		$area += (scalar @gateList - 1)*$WN + (scalar @gateList - 1)*$WP;
	}
		
} #End of File reading.

print OUT "\n\n*Control statements\n";
print OUT ".option post=2\n";
print OUT ".TR 1ns 2ns .1ns 3ns 1ns 10ns\n";


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

print OUT ".print TR ";
for ($i=0; $i < $out; $i++){
	if ($flag{$OUTPUT[$i]}==1){
		print OUT "NN".$OUTPUT[$i];
	}
	else{
		print OUT "V(N".$OUTPUT[$i];
	}
	if ($i != $out-1) {
           print OUT ") ";
        } else {
	   # print OUT "), V(xx), V(yy)\n";
	   print OUT ")\n";
	}
}

#########################################################################################################
# Manually add technology file here. 																	# 
#########################################################################################################
print OUT "\n\n* Beta Version released on 2/22/06

* PTM 90nm NMOS 
 
.MODEL NMOS NMOS (  LEVEL   = 54
+version = 4.0          binunit = 1            paramchk= 1            mobmod  = 0          
+capmod  = 2            igcmod  = 1            igbmod  = 1            geomod  = 1          
+diomod  = 1            rdsmod  = 0            rbodymod= 1            rgatemod= 1          
+permod  = 1            acnqsmod= 0            trnqsmod= 0          
+tnom    = 27           toxe    = 2.05e-9      toxp    = 1.4e-9       toxm    = 2.05e-9   
+dtox    = 0.65e-9      epsrox  = 3.9          wint    = 5e-009       lint    = 7.5e-009   
+ll      = 0            wl      = 0            lln     = 1            wln     = 1          
+lw      = 0            ww      = 0            lwn     = 1            wwn     = 1          
+lwl     = 0            wwl     = 0            xpart   = 0            toxref  = 2.05e-9   
+xl      = -40e-9
+vth0    = 0.397        k1      = 0.4          k2      = 0.01         k3      = 0          
+k3b     = 0            w0      = 2.5e-006     dvt0    = 1            dvt1    = 2       
+dvt2    = -0.032       dvt0w   = 0            dvt1w   = 0            dvt2w   = 0          
+dsub    = 0.1          minv    = 0.05         voffl   = 0            dvtp0   = 1.2e-009     
+dvtp1   = 0.1          lpe0    = 0            lpeb    = 0            xj      = 2.8e-008   
+ngate   = 2e+020       ndep    = 1.94e+018    nsd     = 2e+020       phin    = 0          
+cdsc    = 0.0002       cdscb   = 0            cdscd   = 0            cit     = 0          
+voff    = -0.13        nfactor = 1.7          eta0    = 0.0074       etab    = 0          
+vfb     = -0.55        u0      = 0.0547       ua      = 6e-010       ub      = 1.2e-018     
+uc      = -3e-011      vsat    = 113760       a0      = 1.0          ags     = 1e-020     
+a1      = 0            a2      = 1            b0      = -1e-020      b1      = 0          
+keta    = 0.04         dwg     = 0            dwb     = 0            pclm    = 0.06       
+pdiblc1 = 0.001        pdiblc2 = 0.001        pdiblcb = -0.005       drout   = 0.5        
+pvag    = 1e-020       delta   = 0.01         pscbe1  = 8.14e+008    pscbe2  = 1e-007     
+fprout  = 0.2          pdits   = 0.08         pditsd  = 0.23         pditsl  = 2.3e+006   
+rsh     = 5            rdsw    = 180          rsw     = 90           rdw     = 90        
+rdswmin = 0            rdwmin  = 0            rswmin  = 0            prwg    = 0          
+prwb    = 6.8e-011     wr      = 1            alpha0  = 0.074        alpha1  = 0.005      
+beta0   = 30           agidl   = 0.0002       bgidl   = 2.1e+009     cgidl   = 0.0002
+egidl   = 0.8          
+aigbacc = 0.012        bigbacc = 0.0028       cigbacc = 0.002     
+nigbacc = 1            aigbinv = 0.014        bigbinv = 0.004        cigbinv = 0.004      
+eigbinv = 1.1          nigbinv = 3            aigc    = 0.012        bigc    = 0.0028     
+cigc    = 0.002        aigsd   = 0.012        bigsd   = 0.0028       cigsd   = 0.002     
+nigc    = 1            poxedge = 1            pigcd   = 1            ntox    = 1          
+xrcrg1  = 12           xrcrg2  = 5          
+cgso    = 1.9e-010     cgdo    = 1.9e-010     cgbo    = 2.56e-011    cgdl    = 2.653e-10     
+cgsl    = 2.653e-10    ckappas = 0.03         ckappad = 0.03         acde    = 1          
+moin    = 15           noff    = 0.9          voffcv  = 0.02       
+kt1     = -0.11        kt1l    = 0            kt2     = 0.022        ute     = -1.5       
+ua1     = 4.31e-009    ub1     = 7.61e-018    uc1     = -5.6e-011    prt     = 0          
+at      = 33000      
+fnoimod = 1            tnoimod = 0          
+jss     = 0.0001       jsws    = 1e-011       jswgs   = 1e-010       njs     = 1          
+ijthsfwd= 0.01         ijthsrev= 0.001        bvs     = 10           xjbvs   = 1          
+jsd     = 0.0001       jswd    = 1e-011       jswgd   = 1e-010       njd     = 1          
+ijthdfwd= 0.01         ijthdrev= 0.001        bvd     = 10           xjbvd   = 1          
+pbs     = 1            cjs     = 0.0005       mjs     = 0.5          pbsws   = 1          
+cjsws   = 5e-010       mjsws   = 0.33         pbswgs  = 1            cjswgs  = 3e-010     
+mjswgs  = 0.33         pbd     = 1            cjd     = 0.0005       mjd     = 0.5        
+pbswd   = 1            cjswd   = 5e-010       mjswd   = 0.33         pbswgd  = 1          
+cjswgd  = 5e-010       mjswgd  = 0.33         tpb     = 0.005        tcj     = 0.001      
+tpbsw   = 0.005        tcjsw   = 0.001        tpbswg  = 0.005        tcjswg  = 0.001      
+xtis    = 3            xtid    = 3          
+dmcg    = 0e-006       dmci    = 0e-006       dmdg    = 0e-006       dmcgt   = 0e-007     
+dwj     = 0.0e-008     xgw     = 0e-007       xgl     = 0e-008     
+rshg    = 0.4          gbmin   = 1e-010       rbpb    = 5            rbpd    = 15         
+rbps    = 15           rbdb    = 15           rbsb    = 15           ngcon   = 1  )    

* PTM 90nm PMOS
 
.MODEL PMOS PMOS ( LEVEL   = 54
+version = 4.0          binunit = 1            paramchk= 1            mobmod  = 0          
+capmod  = 2            igcmod  = 1            igbmod  = 1            geomod  = 1          
+diomod  = 1            rdsmod  = 0            rbodymod= 1            rgatemod= 1          
+permod  = 1            acnqsmod= 0            trnqsmod= 0          
+tnom    = 27           toxe    = 2.15e-009    toxp    = 1.4e-009     toxm    = 2.15e-009   
+dtox    = 0.75e-9      epsrox  = 3.9          wint    = 5e-009       lint    = 7.5e-009   
+ll      = 0            wl      = 0            lln     = 1            wln     = 1          
+lw      = 0            ww      = 0            lwn     = 1            wwn     = 1          
+lwl     = 0            wwl     = 0            xpart   = 0            toxref  = 2.15e-009   
+xl      = -40e-9
+vth0    = -0.339       k1      = 0.4          k2      = -0.01        k3      = 0          
+k3b     = 0            w0      = 2.5e-006     dvt0    = 1            dvt1    = 2       
+dvt2    = -0.032       dvt0w   = 0            dvt1w   = 0            dvt2w   = 0          
+dsub    = 0.1          minv    = 0.05         voffl   = 0            dvtp0   = 1e-009     
+dvtp1   = 0.05         lpe0    = 0            lpeb    = 0            xj      = 2.8e-008   
+ngate   = 2e+020       ndep    = 1.43e+018    nsd     = 2e+020       phin    = 0          
+cdsc    = 0.000258     cdscb   = 0            cdscd   = 6.1e-008     cit     = 0          
+voff    = -0.126       nfactor = 1.7          eta0    = 0.0074       etab    = 0          
+vfb     = 0.55         u0      = 0.00711      ua      = 2.0e-009     ub      = 0.5e-018     
+uc      = -3e-011      vsat    = 70000        a0      = 1.0          ags     = 1e-020     
+a1      = 0            a2      = 1            b0      = 0            b1      = 0          
+keta    = -0.047       dwg     = 0            dwb     = 0            pclm    = 0.12       
+pdiblc1 = 0.001        pdiblc2 = 0.001        pdiblcb = 3.4e-008     drout   = 0.56       
+pvag    = 1e-020       delta   = 0.01         pscbe1  = 8.14e+008    pscbe2  = 9.58e-007  
+fprout  = 0.2          pdits   = 0.08         pditsd  = 0.23         pditsl  = 2.3e+006   
+rsh     = 5            rdsw    = 200          rsw     = 100          rdw     = 100        
+rdswmin = 0            rdwmin  = 0            rswmin  = 0            prwg    = 3.22e-008  
+prwb    = 6.8e-011     wr      = 1            alpha0  = 0.074        alpha1  = 0.005      
+beta0   = 30           agidl   = 0.0002       bgidl   = 2.1e+009     cgidl   = 0.0002     
+egidl   = 0.8          
+aigbacc = 0.012        bigbacc = 0.0028       cigbacc = 0.002     
+nigbacc = 1            aigbinv = 0.014        bigbinv = 0.004        cigbinv = 0.004      
+eigbinv = 1.1          nigbinv = 3            aigc    = 0.69         bigc    = 0.0012     
+cigc    = 0.0008       aigsd   = 0.0087       bigsd   = 0.0012       cigsd   = 0.0008     
+nigc    = 1            poxedge = 1            pigcd   = 1            ntox    = 1          
+xrcrg1  = 12           xrcrg2  = 5          
+cgso    = 1.8e-010     cgdo    = 1.8e-010     cgbo    = 2.56e-011    cgdl    = 2.653e-10
+cgsl    = 2.653e-10    ckappas = 0.03         ckappad = 0.03         acde    = 1
+moin    = 15           noff    = 0.9          voffcv  = 0.02
+kt1     = -0.11        kt1l    = 0            kt2     = 0.022        ute     = -1.5       
+ua1     = 4.31e-009    ub1     = 7.61e-018    uc1     = -5.6e-011    prt     = 0          
+at      = 33000      
+fnoimod = 1            tnoimod = 0          
+jss     = 0.0001       jsws    = 1e-011       jswgs   = 1e-010       njs     = 1          
+ijthsfwd= 0.01         ijthsrev= 0.001        bvs     = 10           xjbvs   = 1          
+jsd     = 0.0001       jswd    = 1e-011       jswgd   = 1e-010       njd     = 1          
+ijthdfwd= 0.01         ijthdrev= 0.001        bvd     = 10           xjbvd   = 1          
+pbs     = 1            cjs     = 0.0005       mjs     = 0.5          pbsws   = 1          
+cjsws   = 5e-010       mjsws   = 0.33         pbswgs  = 1            cjswgs  = 3e-010     
+mjswgs  = 0.33         pbd     = 1            cjd     = 0.0005       mjd     = 0.5        
+pbswd   = 1            cjswd   = 5e-010       mjswd   = 0.33         pbswgd  = 1          
+cjswgd  = 5e-010       mjswgd  = 0.33         tpb     = 0.005        tcj     = 0.001      
+tpbsw   = 0.005        tcjsw   = 0.001        tpbswg  = 0.005        tcjswg  = 0.001      
+xtis    = 3            xtid    = 3          
+dmcg    = 0e-006       dmci    = 0e-006       dmdg    = 0e-006       dmcgt   = 0e-007     
+dwj     = 0.0e-008     xgw     = 0e-007       xgl     = 0e-008     
+rshg    = 0.4          gbmin   = 1e-010       rbpb    = 5            rbpd    = 15         
+rbps    = 15           rbdb    = 15           rbsb    = 15           ngcon   = 1   ) \n\n";
#########################################################################################################
# Technology file addition ends here.																	#
#########################################################################################################
print OUT "\n";
print OUT ".end";
 

print OUT_TEMP "*$circuit benchmark circuit\n\n";

#printing input signals
print OUT_TEMP "*INPUTS ";
for ($i=0; $i < $in; $i++){
	print OUT_TEMP "N".$INPUT[$i];
	if ($i != $in-1) {
           print OUT_TEMP " ";
        } else {
	   print OUT_TEMP "\n";
	}
} 


#printing output signals
print OUT_TEMP "*OUTPUTS ";
for ($i=0; $i < $out; $i++){
	if ($flag{$OUTPUT[$i]}==1){
		print OUT_TEMP "NN".$OUTPUT[$i];
	}
	else{
		print OUT_TEMP "N".$OUTPUT[$i];
	}
	if ($i != $out-1) {
           print OUT_TEMP " ";
        } else {
	   print OUT_TEMP "\n";
	}
}


print OUT_TEMP "\n*Parameters declaration";
print OUT_TEMP "\n.Param ll=$ll"."U WN='(2*ll)' WP='(4*ll)'\n"; 

print OUT_TEMP "\n*Power supplies";
print OUT_TEMP "\nVDD VDD GND DC $vdd\n";

close (OUT);
close (OUT_TEMP);

open(IN,"$circuit".".sp") || die " Cannot open input file $circuit".".v \n";
open(OUT,">>test.sp") || die " Cannot open input file $circuit".".v \n";
while (<IN>) {
	print OUT $_;
}
close(IN);
close(OUT);

#write area to a file
open(OUT2,">area.sp") || die " Cannot open input file area.sp \n";
print OUT2 $area;
close (OUT2);
close (OUT_AREA);

print "Area = $area\n";

#delete the temporary test file.
system ("del $circuit.sp");
system ("ren test.sp $circuit.sp");

$end=time;
$diff = $end - $start;


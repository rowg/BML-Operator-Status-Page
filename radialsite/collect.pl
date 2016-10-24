#!/usr/bin/perl
#
# CODAR status table collect tool. BML/ML.
#
# Updated 2016 06 28 ML. Added check for bad date values in HDR/RDT files.
#
# Collects system and file information, generates site log file with the following parameters:
# XXXX:Time_Now_Full=Wed Oct 29 18:51:00 2008
# XXXX:Time_Now_Seconds=1225306260
# XXXX:IP=
# XXXX:AC=1
# XXXX:Last_RDLi_Name=RDLi_BML1_2008_10_29_1800.ruv
# XXXX:Last_RDLi_Short_Name=29_1800
# XXXX:Last_RDLi_Updated_Seconds=1225305931
# XXXX:Last_RDLi_Age_Seconds=330
# XXXX:Last_RDLi_Age_Hours=0
# XXXX:Last_RDLm_Name=RDLm_BML1_2008_10_29_1800.ruv
# XXXX:Last_RDLm_Short_Name=29_1800
# XXXX:Last_RDLm_Updated_Seconds=1225305940
# XXXX:Last_RDLm_Age_Seconds=321
# XXXX:Last_RDLm_Age_Hours=0
# XXXX:Root_Disk_Available_GB=21
# XXXX:Archive_Disk_Available_GB=58
# XXXX:Diag_RDT_Name=STAT_BML1_2008_10_26.rdt
# XXXX:RDT_Updated_seconds=1225305940
# XXXX:RDT_Age_Seconds=321
# XXXX:Max_Range_km=76.0
# XXXX:Loop1_Amplitude=2.1480
# XXXX:Loop2_Amplitude=1.5920
# XXXX:Loop1_Phase_Deg=84.6
# XXXX:Loop2_Phase_Deg=90.0
# XXXX:Monopole_SNR_dB=+60.
# XXXX:RDT_Sample_Seconds=1225303800
# XXXX:Diag_HDT_Name=STAT_BML1_2008_10_26.hdt
# XXXX:HDT_Updated_seconds=1225305901
# XXXX:HDT_Age_Seconds=360
# XXXX:Computer_Runtime_Hours=12
# XXXX:AWG_Runtime_Hours=2
# XXXX:Receiver_Chassis_Temperature_DegC=28
# XXXX:Receiver_AWG_Temperature_DegC=38
# XXXX:Transmitter_Chassis_Temperature_DegC=29
# XXXX:Transmitter_Amplifier_Temperature_DegC=35
# XXXX:Transmitter_Forward_Power_W=42
# XXXX:Transmitter_Reverse_Power_W=1
# XXXX:HDT_Sample_Seconds=1225303800
# XXXX:Sentinel_Log_Filename=Sentinel_BML1_20081104.log
# XXXX:Sentinel_Log_Failures=12
#
#
use warnings ;
use strict ;
use Time::Local ;

sub convert_date($$$$$$) ;

# Globals
my $codarpath="/Codar/SeaSonde" ;
my $collectpath="/Users/codar/scripts/collect" ;
my $headerpath="$codarpath/Configs/RadialConfigs/Header.txt" ;
my $radialpath = "$codarpath/Data/Radials" ;
my $diagpath = "$codarpath/Data/Diagnostics" ;
my $sentinelpath = "$codarpath/Logs/SentinelLogs" ;
my $archive="/Volumes/CodarArchives" ;

my $result ;	# Hold result of command
my $result2 ;	# Hold results of another command
my @arresult ;	# Hold array of results
my $sitename = undef ;
if( ! -e $headerpath )
{
	print "Cannot find header file, using site code XXXX.\n" ;
}
else
{
	$sitename=`awk 'NR==1 { print \$2 }' $headerpath` ;
}
if( !defined($sitename) || ($sitename eq "") )
{
	$sitename = "XXXX" ;
}
else
{
	chomp $sitename ;
}

my $logfilename = "$collectpath/Site_${sitename}.log" ;
if( ! open LOG, ">".$logfilename )
{
	die "Cannot open log file ${logfilename}.\n" ;
}

# Collect time information
print LOG "${sitename}:Time_Now_Full=".gmtime()."\n" ;	# Use the concatenate operator to force gmtime to return a string instead of a list of numbers.
print LOG "${sitename}:Time_Now_Seconds=".time()."\n" ;

# Collect IP address, but time out at 30s
#$result=`curl -m 30 -s http://automation.whatismyip.com/n09230945.asp` ;
#http://automation.whatismyip.com/n09230945.asp
#if( ! defined($result) )
#{
#	$result = "" ;
#}
#print LOG "${sitename}:IP=".${result}."\n" ;

# Collect AC present
$result=`pmset -g batt | grep Power` ;
if( ! defined($result) or not $result =~ /'(\w+) Power'/ )
{
        $result = "" ;
}
else
{
        $result = $1 ;
	if( $result eq "AC" )
	{
		$result = "1" ;
	}
	else
	{
		$result = "0" ;
	}
}
print LOG "${sitename}:AC=".${result}."\n" ;

# Collect the sentinel log file information
chdir ${sentinelpath} ;
@arresult=sort(glob("Sentinel_${sitename}_*.log")) ;	# Find all Sentinel files and sort by name
$result=pop(@arresult) ;			# Return last element of array of filename
if( defined($result) )
{
	print LOG "${sitename}:Sentinel_Log_Filename=".${result}."\n" ;
	$result2=`grep Failure ${result} | wc -l` ;
	chomp($result2) ;
	if( (not defined $result2) || ($result2 eq "") )
	{
		$result = 0 ;
	}
	$result2 += 0 ;
	print LOG "${sitename}:Sentinel_Log_Failures=${result2}\n" ;
}
else
{
	print LOG "${sitename}:Sentinel_Log_Filename=\n" ;
	print LOG "${sitename}:Sentinel_Log_Failures=\n" ;
}

# Collect RDLi file information
chdir "${radialpath}" ;
chdir "IdealPattern" ;				# Change down if it's there
@arresult=sort(glob("RDLi_${sitename}_*")) ;	# Find all RDLm files and sort by name
$result=pop(@arresult) ;			# Return last element of array of filename
if( defined($result) )
{
	print LOG "${sitename}:Last_RDLi_Name=".${result}."\n" ;
	print LOG "${sitename}:Last_RDLi_Short_Name=".substr(${result},18,7)."\n" ;
	@arresult=stat(${result}) ;
	$result2=$arresult[9] ;	# [9]=mtime
	print LOG "${sitename}:Last_RDLi_Updated_Seconds=".${result2}."\n" ;
	$result=time()-$result2 ;
	print LOG "${sitename}:Last_RDLi_Age_Seconds=".${result}."\n" ;
	$result /= 3600 ;
	print LOG "${sitename}:Last_RDLi_Age_Hours=".int(${result})."\n" ;
}
else
{
	print LOG "${sitename}:Last_RDLi_Name=\n" ;
	print LOG "${sitename}:Last_RDLi_Short_Name=\n" ;
	print LOG "${sitename}:Last_RDLi_Updated_Seconds=\n" ;
	print LOG "${sitename}:Last_RDLi_Age_Seconds=\n" ;
	print LOG "${sitename}:Last_RDLi_Age_Hours=\n" ;
}

# Collect RDLm file information
chdir "${radialpath}" ;
chdir "MeasPattern" ;				# Change down if it's there
@arresult=sort(glob("RDLm_${sitename}_*")) ;	# Find all RDLm files and sort by name
$result=pop(@arresult) ;			# Return last element of array of filename
if( defined($result) )
{
	print LOG "${sitename}:Last_RDLm_Name=".${result}."\n" ;
	print LOG "${sitename}:Last_RDLm_Short_Name=".substr(${result},18,7)."\n" ;
	@arresult=stat(${result}) ;
	$result2=$arresult[9] ;	# [9]=mtime
	print LOG "${sitename}:Last_RDLm_Updated_Seconds=".${result2}."\n" ;
	$result=time()-$result2 ;
	print LOG "${sitename}:Last_RDLm_Age_Seconds=".${result}."\n" ;
	$result /= 3600 ;
	print LOG "${sitename}:Last_RDLm_Age_Hours=".int(${result})."\n" ;
}
else
{
	print LOG "${sitename}:Last_RDLm_Name=\n" ;
	print LOG "${sitename}:Last_RDLm_Short_Name=\n" ;
	print LOG "${sitename}:Last_RDLm_Updated_Seconds=\n" ;
	print LOG "${sitename}:Last_RDLm_Age_Seconds=\n" ;
	print LOG "${sitename}:Last_RDLm_Age_Hours=\n" ;
}

@arresult=() ;
eval { @arresult=`df -k /` ; } ;
if( @arresult )
{
	$result=$arresult[1] ;
	@arresult= split /\s+/, $result ;
	$result =$arresult[3] ;
	$result = int(0.5+$result/(1024*1024)) ;
}
else
{
	$result="" ;
}
print LOG "${sitename}:Root_Disk_Available_GB=".$result."\n" ;

if( -e $archive )
{
	@arresult=`df -k $archive` ;
	$result=$arresult[1] ;
	@arresult= split /\s+/, $result ;
	$result =$arresult[3] ;
	$result = int(0.5+$result/(1024*1024)) ;
}
else
{
	$result="" ;
}
print LOG "${sitename}:Archive_Disk_Available_GB=".$result."\n" ;

chdir $diagpath ;
@arresult=sort(glob("STAT_${sitename}_*.rdt")) ;	# Find .rdt files and sort by name
$result=pop(@arresult) ;			# Return last element of array of filenames
if( defined($result) )
{
	my $filename=$result ;
	print LOG "${sitename}:Diag_RDT_Name=".$filename."\n" ;
	@arresult=stat(${filename}) ;
	$result=$arresult[9] ;	# [9]=mtime
	print LOG "${sitename}:RDT_Updated_seconds=".${result}."\n" ;
	$result2=time()-$result ;
	print LOG "${sitename}:RDT_Age_Seconds=".${result2}."\n" ;
	
	my $IN ;
	if( open IN, "<".$filename )
	{
		my $line ;
		while( defined($line=<IN>) )
		{
			chomp($line) ;
			if( $line =~ /(^%TableColumnTypes:\s+)(.*)\s+$/ )
			{
				if( defined($2) )
				{
					$line=$2 ;
					last ;
				}
			}
		}
		if( defined($line) )
		{
			@arresult = split /\s+/, $line ;
		}
		# Totally over the top: build a hash of column names versus index numbers
		my $index ;
		my %lut ;
		for $index (0..$#arresult)
		{
			my $name = $arresult[$index] ;
			$lut{$name} = $index+1 ;
		}
#		for $index (keys %lut)
#		{
#			print "$index at $lut{$index}\n" ;
#		}
		my $lastline ;
		while( defined($line=<IN>) )
		{
			if( $line =~ /^%TableEnd:/ )
			{
				last ;
			}
			$lastline = $line ;
		}
		close IN ;
		if( defined($line) )
		{
			@arresult = split /\s+/, $lastline ;
		}
		print LOG "${sitename}:Max_Range_km=${arresult[$lut{RADR}]}\n" ;
		print LOG "${sitename}:Loop1_Amplitude=${arresult[$lut{AMP1}]}\n" ;
		print LOG "${sitename}:Loop2_Amplitude=${arresult[$lut{AMP2}]}\n" ;
		print LOG "${sitename}:Loop1_Phase_Deg=${arresult[$lut{PH13}]}\n" ;
		print LOG "${sitename}:Loop2_Phase_Deg=${arresult[$lut{PH23}]}\n" ;
		print LOG "${sitename}:Monopole_SNR_dB=${arresult[$lut{SSN3}]}\n" ;
		my $yr=$arresult[$lut{TYRS}] ;
		my $mo=$arresult[$lut{TMON}] ;
		my $dy=$arresult[$lut{TDAY}] ;
		my $hr=$arresult[$lut{THRS}] ;
		my $mn=$arresult[$lut{TMON}] ;
		my $sc=$arresult[$lut{TSEC}] ;
		my $sample = convert_date($yr,$mo,$dy,$hr,$mn,$sc) ;
		print LOG "${sitename}:RDT_Sample_Seconds=".$sample."\n" ;
	}
	else
	{
		print LOG "${sitename}:Max_Range_km=\n" ;
		print LOG "${sitename}:Loop1_Amplitude=\n" ;
		print LOG "${sitename}:Loop2_Amplitude=\n" ;
		print LOG "${sitename}:Loop1_Phase_Deg=\n" ;
		print LOG "${sitename}:Loop2_Phase_Deg=\n" ;
		print LOG "${sitename}:Monopole_SNR_dB=\n" ;
		print LOG "${sitename}:RDT_Sample_Seconds=\n" ;
	}	
}
else
{
	print LOG "${sitename}:Diag_RDT_Name=\n" ;
	print LOG "${sitename}:RDT_Updated_Seconds=\n" ;
	print LOG "${sitename}:RDT_Age_Seconds=\n" ;
	print LOG "${sitename}:Max_Range_km=\n" ;
	print LOG "${sitename}:Loop1_Phase_Deg=\n" ;
	print LOG "${sitename}:Loop2_Phase_Deg=\n" ;
	print LOG "${sitename}:Monopole_SNR_dB=\n" ;
	print LOG "${sitename}:RDT_Sample_Seconds=\n" ;
}

@arresult=sort(glob("STAT_${sitename}_*.hdt")) ;	# Find .hdt files and sort by name
$result=pop(@arresult) ;			# Return last element of array of filenames
if( defined($result) )
{
	my $filename=$result ;
	print LOG "${sitename}:Diag_HDT_Name=".$filename."\n" ;
	@arresult=stat(${filename}) ;
	$result=$arresult[9] ;	# [9]=mtime
	print LOG "${sitename}:HDT_Updated_seconds=".${result}."\n" ;
	$result2=time()-$result ;
	print LOG "${sitename}:HDT_Age_Seconds=".${result2}."\n" ;
	
	my $IN ;
	if( open IN, "<".$filename )
	{
		my $line ;
		while( defined($line=<IN>) )
		{
			chomp($line) ;
			if( $line =~ /(^%TableColumnTypes:\s+)(.*)\s+$/ )
			{
				if( defined($2) )
				{
					$line=$2 ;
					last ;
				}
			}
		}
		if( defined($line) )
		{
			@arresult = split /\s+/, $line ;
		}
		# Totally over the top: build a hash of column names versus index numbers
		my $index ;
		my %lut ;
		for $index (0..$#arresult)
		{
			my $name = $arresult[$index] ;
			$lut{$name} = $index+1 ;
		}
#		for $index (keys %lut)
#		{
#			print "$index at $lut{$index}\n" ;
#		}
		my $lastline ;
		while( defined($line=<IN>) )
		{
			if( $line =~ /^%TableEnd:/ )
			{
				last ;
			}
			$lastline = $line ;
		}
		close IN ;
		if( defined($line) )
		{
			@arresult = split /\s+/, $lastline ;
		}
		$result = int(${arresult[$lut{CRUN}]}/60) ;
		print LOG "${sitename}:Computer_Runtime_Hours=$result\n" ;
		$result = int(${arresult[$lut{RUNT}]}/3660) ;
		print LOG "${sitename}:AWG_Runtime_Hours=$result\n" ;
		$result = ${arresult[$lut{RTMP}]} ;
		if( $result == -273 ) { $result = "" } ;
		print LOG "${sitename}:Receiver_Chassis_Temperature_DegC=$result\n" ;
		$result = ${arresult[$lut{MTMP}]} ;
		if( $result == -273 ) { $result = "" } ;
		print LOG "${sitename}:Receiver_AWG_Temperature_DegC=$result\n" ;
		print LOG "${sitename}:Transmitter_Chassis_Temperature_DegC=${arresult[$lut{XPHT}]}\n" ;
		print LOG "${sitename}:Transmitter_Amplifier_Temperature_DegC=${arresult[$lut{XAHT}]}\n" ;
		print LOG "${sitename}:Transmitter_Forward_Power_W=${arresult[$lut{XAFW}]}\n" ;
		print LOG "${sitename}:Transmitter_Reverse_Power_W=${arresult[$lut{XARW}]}\n" ;
		my $yr=$arresult[$lut{TYRS}] ;
		my $mo=$arresult[$lut{TMON}] ;
		my $dy=$arresult[$lut{TDAY}] ;
		my $hr=$arresult[$lut{THRS}] ;
		my $mn=$arresult[$lut{TMON}] ;
		my $sc=$arresult[$lut{TSEC}] ;
		my $sample = convert_date($yr,$mo,$dy,$hr,$mn,$sc) ;
		print LOG "${sitename}:HDT_Sample_Seconds=".$sample."\n" ;
	}
	else
	{
		print LOG "${sitename}:Computer_Runtime_Hours=\n" ;
		print LOG "${sitename}:AWG_Runtime_Hours=\n" ;
		print LOG "${sitename}:Receiver_Chassis_Temperature_DegC=\n" ;
		print LOG "${sitename}:Receiver_AWG_Temperature_DegC=\n" ;
		print LOG "${sitename}:Transmitter_Chassis_Temperature_DegC=\n" ;
		print LOG "${sitename}:Transmitter_Amplifier_Temperature_DegC=\n" ;
		print LOG "${sitename}:Transmitter_Forward_Power_W=\n" ;
		print LOG "${sitename}:Transmitter_Reverse_Power_W=\n" ;
		print LOG "${sitename}:HDT_Sample_Seconds=\n" ;
	}	
}
else
{
	print LOG "${sitename}:Diag_HDT_Name=\n" ;
	print LOG "${sitename}:HDT_Updated_Seconds=\n" ;
	print LOG "${sitename}:HDT_Age_Seconds=\n" ;
	print LOG "${sitename}:Computer_Runtime_Hours=\n" ;
	print LOG "${sitename}:AWG_Runtime_Hours=\n" ;
	print LOG "${sitename}:Receiver_Chassis_Temperature_DegC=\n" ;
	print LOG "${sitename}:Receiver_AWG_Temperature_DegC=\n" ;
	print LOG "${sitename}:Transmitter_Chassis_Temperature_DegC=\n" ;
	print LOG "${sitename}:Transmitter_Amplifier_Temperature_DegC=\n" ;
	print LOG "${sitename}:Transmitter_Forward_Power_W=\n" ;
	print LOG "${sitename}:Transmitter_Reverse_Power_W=\n" ;
	print LOG "${sitename}:HDT_Sample_Seconds=\n" ;
}


sub convert_date($$$$$$)
{
	my ( $yr, $mo, $dy, $hr, $mn, $sc ) = @_ ;
	my $baddate = 0 ;
	if( ($yr > 2050) || ($yr < 1950) ) { $baddate = 1 ; }
	if( ($mo > 12) || ($mo < 1) ) { $baddate = 1 ; }
	if( ($dy > 31) || ($dy < 1) ) { $baddate = 1 ; }
	if( ($hr > 23) || ($hr < 0) ) { $baddate = 1 ; }
	if( ($mn > 59) || ($mn < 0) ) { $baddate = 1 ; }
	if( ($sc > 59) || ($sc < 0) ) { $baddate = 1 ; }
	my $seconds = "" ;
	if( not $baddate )
	{
		$seconds=timegm( $sc, $mn, $hr, $dy, $mo-1, $yr-1900 ) ;
	}
	return $seconds ;
}


exit 0;
#END

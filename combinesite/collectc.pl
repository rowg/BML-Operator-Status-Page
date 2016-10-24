#!/usr/bin/perl
#
# CODAR status table collect tool. BML/ML.
#
# Updated 2009 10 27 ML Changed collect path from /Codar/SeaSonde/Users/Scripts/collect to ~codar/scripts/collect
#
# Generates the following parameters:
# XXXX:Last_Ideal_Radial_Name=
# XXXX:Last_Ideal_Radial_Short_Name=
# XXXX:Last_Ideal_Radial_Updated_Seconds=
# XXXX:Last_Ideal_Radial_Age_Seconds=
# XXXX:Last_Ideal_Radial_Age_Hours=
# XXXX:Last_Measured_Radial_Name=
# XXXX:Last_Measured_Radial_Short_Name=
# XXXX:Last_Measured_Radial_Updated_Seconds=
# XXXX:Last_Measured_Radial_Age_Seconds=
# XXXX:Last_Measured_Radial_Age_Hours=
# XXXX:Collect_Log_Age_Mins=4415
#
use warnings ;
use strict ;
use Time::Local ;	# Check if this is still needed <<<<<<<<<<<<<<<
use File::Glob ':nocase' ;	# Make glob case insensitive (for e.g. PRey)

# Globals
my $codarpath="/Codar/SeaSonde" ;
my $radialpath = "$codarpath/Data/RadialSites" ;
my $collectpath = `pwd` ;
chomp($collectpath) ;
my $logfilename = "$collectpath/collectcp.log" ;
#my $logfilename = "collectcp.log" ;

my $result ;
my $result2 ;
my @arresult ;
my %stations ;


sub read_config_stations
#
# Reads Config_stations.txt
# e.g. name=BML1 col=1 show=y rdlipath=Site_1 rdlmpath=Site_1_RDLm
# Stations is a hash of hash lists, one key for each station.
# The hash list contains the following keys: col, show, rdlipath, rdlmpath.
# %stations = 
# (
#	bml1 => { col => 1, show => "y", rdlipath => "Site_1", rdlmpath => "Site_1_RDLm },
#	prey => { col => 2, show => "y", rdlipath => "Site_1", rdlmpath => "Site_1_RDLm },
#	...
# ) ;
# Name is the four letter station code, col is the table column number, show determines whether the station is shown.
# RDLiPath/RDLmPath are directories where ideal/measured radials are stored on the combine site.
#
{
	my $stationfilename = "$collectpath/Config_stations.txt" ;
	if( ! open IN, $stationfilename )
	{
		die "Cannot open $stationfilename\n" ;
	}
	my $line ;
	my $field ;
	while( defined($line=<IN>) )
	{
		chomp $line ;
		my $refhash_stn = {} ;	# A reference to a hash list containing the station info
		my $refhash_stnpar = {} ;	# A reference to a hash list containing the station parameters
		for $field ( split /\s+/, $line )	# /\s+/ means split on regular expression \s+ which means one or more spaces
		{
			my ($key, $value) = split /=/, $field ;
			$refhash_stnpar->{$key} = $value ;	# Dereference refhash, specify key, set value
		}
		my $name = $refhash_stnpar->{name} ; # TEMP Extract name from stnpar hash
		$stations{$name} = $refhash_stnpar ; # Use $name as key, stnpar as value
	}
	close IN ;
}

sub find_last_radials
#
# Finds the name and age of radial files for each station
#
{
	my $name ;
	for $name ( keys %stations )
	{
		my %stnpar = %{ $stations{$name} } ;
		if( $stnpar{show} ne "y" ) { next }
		my $pathname = $stnpar{rdlipath} ;
		if( defined($pathname) && ($pathname ne "") )
		{
			$pathname = "$radialpath/$pathname" ;
			if( ! -e $pathname )
			{
				print "Cannot find path '${pathname}'.\n" ;
				next
			} ;
			#chdir "$pathname" ;
			@arresult = sort(glob("$pathname/RDLi_${name}_*")) ;
			if( $#arresult > 0 )
			{
				$result = $arresult[-1] ;
				my @parts = split /\//,$result ;
				$result = $parts[-1] ;
				print LOG "${name}:Xfer_Ideal_Radial_Name=$result\n" ;
				print LOG "${name}:Xfer_Ideal_Radial_Short_Name=".substr(${result},18,7)."\n" ;
				my @stats = stat($arresult[-1]) ;
				$result2 = $stats[9] ; # stat.mtime
				print LOG "${name}:Xfer_Ideal_Radial_Updated_Seconds=$result2\n" ;
				$result = time() - $result2 ;
				print LOG "${name}:Xfer_Ideal_Radial_Age_Seconds=$result\n" ;
				$result = int($result/3600) ;
				print LOG "${name}:Xfer_Ideal_Radial_Age_Hours=$result\n" ;
			}
			else
			{
				print LOG "${name}:Xfer_Ideal_Radial_Name=\n" ;
				print LOG "${name}:Xfer_Ideal_Radial_Short_Name=\n" ;
				print LOG "${name}:Xfer_Ideal_Radial_Updated_Seconds=\n" ;
				print LOG "${name}:Xfer_Ideal_Radial_Age_Seconds=\n" ;
				print LOG "${name}:Xfer_Ideal_Radial_Age_Hours=\n" ;
			}
		}
		$pathname = $stnpar{rdlmpath} ;
		if( defined($pathname) && ($pathname ne "") )
		{
			$pathname = "$radialpath/$pathname" ;
			if( ! -e $pathname )
			{
				print "Cannot find path '${pathname}'.\n" ;
				next
			}
			#chdir "$pathname" ;
			@arresult = sort(glob("$pathname/RDLm_${name}_*")) ;
			if( $#arresult > 0 )
			{
				$result = $arresult[-1] ;
				my @parts = split /\//,$result ;
				$result = $parts[-1] ;
				print LOG "${name}:Xfer_Measured_Radial_Name=$result\n" ;
				print LOG "${name}:Xfer_Measured_Radial_Short_Name=".substr(${result},18,7)."\n" ;
				my @stats = stat($arresult[-1]) ;
				$result2 = $stats[9] ; # stat.mtime
				print LOG "${name}:Xfer_Measured_Radial_Updated_Seconds=$result2\n" ;
				$result = time() - $result2 ;
				print LOG "${name}:Xfer_Measured_Radial_Age_Seconds=$result\n" ;
				$result = int($result/3600) ;
				print LOG "${name}:Xfer_Measured_Radial_Age_Hours=$result\n" ;
			}
			else
			{
				print LOG "${name}:Xfer_Measured_Radial_Name=\n" ;
				print LOG "${name}:Xfer_Measured_Radial_Short_Name=\n" ;
				print LOG "${name}:Xfer_Measured_Radial_Updated_Seconds=\n" ;
				print LOG "${name}:Xfer_Measured_Radial_Age_Seconds=\n" ;
				print LOG "${name}:Xfer_Measured_Radial_Age_Hours=\n" ;
			}
		}
	}
	#chdir $collectpath ;
}


sub find_site_logs
#
# Finds the name and age of site log files for each station
#
{
	my $name ;
	for $name ( sort keys %stations )
	{
		if( $stations{$name}{show} ne "y" ) { next }
		my $filename = "$collectpath/Site_${name}.log" ;
		@arresult = stat($filename) ;
		if( $#arresult > 0 )
		{
			$result = $arresult[9] ; # stat.mtime
			$result = int((time()-$result)/60) ;
			print LOG "${name}:Xfer_Collect_Log_Age_Mins=$result\n" ;
		}
		else
		{
			print LOG "${name}:Xfer_Collect_Log_Age_Mins=\n" ;
		}
	}
}

#
# Main program start here
#

if( ! open LOG, ">".$logfilename )
{
	die "Cannot open log file ${logfilename}.\n" ;
}

read_config_stations ;	# Read in hash list of station config parameters
find_last_radials ;	# Find radial files for each station
find_site_logs ;	# Find log file for each station

exit 0 ;
#END

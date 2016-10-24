#!/usr/bin/perl
#
# CODAR status table tool for creating png images of plots. BML/ML.
# This tool should also do the part where it updates the csv files, instead of having mktable do that.
#
# Updated 2008 11 09 ML, changed collect path
# Updated 2009-07-29 ML, added check for absent limit values and prevent their use in extraplot command
#
use warnings ;
use strict ;
use Time::Local ;	# Check if this is still needed <<<<<<<<<<<<<<<

# Globals
my $gnuplot="gnuplot" ;
my $codarpath="/Codar/SeaSonde" ;
my $collectpath = "/Users/codar/scripts/collect" ;

my $result ;
my $result2 ;
my @arresult ;
my %stations ;		# A hash list containing configuration information for stations
my %parameters ;	# A hash list containing configuration information for parameters
my %limits ;		# A hash list containing configuration information for parameter limits


sub mkpng_read_config_stations()
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
		if( length($line) < 2 ) { next }
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

sub mkpng_read_config_parameters()
#
# Reads Config_parameters.txt
# e.g. long_name=Max_Range short_name=RADR show=y check=y graph=y
# Parameters is a hash of hash lists, with one entry for each parameter to check.
# Each hash list contains the following keys: long_name, short_name, show, check, graph
#
{
	my $parameterfilename = "$collectpath/Config_parameters.txt" ;
	if( ! open IN, "<".$parameterfilename )
	{
		die "Cannot open $parameterfilename\n" ;
	}
	my $line ;
	my $field ;
	my $row = 1 ;
	while( defined($line=<IN>) )
	{
		chomp $line ;
		if( length($line) < 2 ) { next }
		my $refhash_parcfg = {} ;	# A reference to a hash list containing the parameter config info
		for $field ( split /\s+/, $line )	# Split line on spaces
		{
			my ($key, $value) = split /=/, $field ;
			$refhash_parcfg->{$key} = $value ;	# Dereference refhash, specify key, set value
		}
		$refhash_parcfg->{status_table_row} = $row ;	# Add key 'status_table_row' with automatically assigned row value
		my $name = $refhash_parcfg->{long_name} ;	# TEMP gross gross gross
		$parameters{$name} = $refhash_parcfg ;	# Add parcfg to parameters at key $index
		$row++ ;
	}
	close IN ;
}

sub mkpng_read_config_limits()
#
# Reads the file Config_limits_XXXX.txt for each station in %stations.
# Example line format: long_name=Max_Range low_red=20 low_orange=40 high_orange=70 high_red=80
# Builds %limits, a hash list with a key for each station whose value is a hash list of parameters.
# The %parameter hash list has a key for each parameter whose value is a hash list of limit settings
# The %limitset hash list has keys: low_red, low_orange, high_orange, high_red.
# Example hash list:
# %limits =
# (
#	bml1 =>
#	{
#		Max_Range => { low_red => 20, low_orange => 40, high_orange => 70, high_red => 80 }
#		Tx_Temperature => { ... }
#		...
#	}
#	bmlr =>
#	{
#		...
#	}
# )
#
{
	my $stnname ;
	for $stnname ( sort keys %stations )
	{
		if( $stations{$stnname}{show} ne "y" ) { next }
		my $limitsfilename = "$collectpath/Config_limits_${stnname}.txt" ;
		if( ! open IN, "<".$limitsfilename )
		{
			die "Cannot open $limitsfilename\n" ;
		}
		my $line ;
		my $field ;
		my $refhash_limitset = {} ;	# Declare a reference to a hash list that will contain the limit set for a station
		while( defined($line=<IN>) )	# Each line contains the limits for one parameter
		{
			chomp $line ;
			if( length($line) < 2 ) { next }
			my $refhash_parlim = {} ;	# This is a reference to a hash list containing the limits for one parameter
			# Loop over each field ("key=value") in the line
			for $field ( split /\s+/, $line )	# Split line on spaces
			{
				my ($key, $value) = split /=/, $field ;
				if( defined($key) && defined ($value) )
				{
					$refhash_parlim->{$key} = $value ;	# Dereference the refhash, select the key, set the value
				}
			}
			# Now refhash_parlim refers to a completed hashlist of limits for one parameter
			my $parname = $refhash_parlim->{long_name} ; # TEMP, get parameter name, need to revise this <<<
			$refhash_limitset->{$parname} = $refhash_parlim ;	# Add parlim to limitset, at key parname
		}
		# Now refhash_limitset refers to a completed hashlist of limits for all parameters for one station
		$limits{$stnname} = $refhash_limitset ; # Add limitset to limits at key stnname
		close IN ;
	}
}


sub make_png()
#
# Makes the png images of graph plots.
#
{
	my $stnname ;
	for $stnname ( keys %stations )
	{
		if( $stations{$stnname}{show} ne "y" ) { next }
		my $parname ;
		for $parname ( keys %parameters )
		{
			if( $parameters{$parname}{graph} ne "y" ) { next }	# Skip parameters that you don't graph
			my $check = $parameters{$parname}{check} ;
			my $shortname = $parameters{$parname}{short_name} ;
			my $longname = $parameters{$parname}{long_name} ;
			my $ymin = $limits{$stnname}{$parname}{ymin} ;
			my $ymax = $limits{$stnname}{$parname}{ymax} ;
			my $gpfilename = "$collectpath/data/${stnname}_${shortname}.gp" ;
			my $pngfilename = "$collectpath/data/${stnname}_${shortname}.png" ;
			my $csvfilename = "$collectpath/data/${stnname}_${shortname}.csv" ;
			my $errfilename = "$collectpath/data/${stnname}_${shortname}.log" ;
			if( ! -e $gpfilename )
			{
				if( open OUT, ">".$gpfilename )
				{
					print OUT "set term png size 800,400\n" ;
					print OUT "set output \"${pngfilename}\"\n" ;
					print OUT "set datafile separator \",\"\n" ;
					print OUT "set xdata time\n" ;
					print OUT "set timefmt \"%Y %m %d %H %M\"\n" ;
					print OUT "set title \"${stnname} ${longname}\"\n" ;
					print OUT "set style data lines\n" ;
					print OUT "set grid\n" ;
					print OUT "set format x \"%H:%M\\n%m/%d\"\n" ;
					if( defined($ymin) && defined($ymax) )
					{
						print OUT "set yrange [${ymin}:${ymax}]\n" ;
					}
					my $extraplot = "" ;
					if( defined(${check}) && ($check eq "y") )
					{
						my $low_red = $limits{$stnname}{$parname}{low_red} ;
						my $low_orange = $limits{$stnname}{$parname}{low_orange} ;
						my $high_orange = $limits{$stnname}{$parname}{high_orange} ;
						my $high_red = $limits{$stnname}{$parname}{high_red} ;
						if( defined $low_red ) { $extraplot .= ", ${low_red} linetype 1 linewidth 2 notitle" ; }		# lt 1 is red
						if( defined $low_orange ) { $extraplot .= ", ${low_orange} linetype 7 linewidth 2 notitle" ; }		# lt 7 is orange
						if( defined $high_orange ) { $extraplot .= ", ${high_orange} linetype 7 linewidth 2 notitle" ; }	# lt 7 is orange
						if( defined $high_red ) { $extraplot .= ", ${high_red} linetype 1 linewidth 2 notitle" ; }		# lt 1 is red
					}
					print OUT "plot \"${csvfilename}\" using 1:2 linetype 3 linewidth 2 title \"\"${extraplot}\n" ; # lt 3 is blue
					close OUT ;
				}
			}
			if( -e $gpfilename )
			{
				# Run gnuplot on gpfile
				`${gnuplot} ${gpfilename} &>${errfilename}` ;
			}
		}
	}
}

#
# Main program start here
#
sub main()
{
	mkpng_read_config_stations ;	# Read in hash list of station config parameters
	mkpng_read_config_parameters ;	# Read in hash list of parameter config parameters
	mkpng_read_config_limits ;	# Read in hash list of limits config parameters
	make_png ;	# Makes png images for graph plots.
	return 0 ;
}

exit main() ;
#END

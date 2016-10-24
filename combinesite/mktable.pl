#!/usr/bin/perl
#
# CODAR status table generation tool. BML/ML.
#
# Updated 2009 10 27 ML. Made it work from current directory rather than codar path. Added local time to Updated caption.
# Updated 2010 01 14 ML. Adjusted size of images table and new plot window.
# Updated 2011 11 30 ML. Added link to station URL, added URL parameter to Config_Station.txt
# Updated 2016 03 24 ML. Replaced underscores with spaces in table row header.
#
#
use warnings ;
use strict;

# Globals
my $codarpath = "/Codar/SeaSonde" ;
#my $collectpath = "$codarpath/Users/Scripts/collect" ;
my $collectpath = "." ;

my %stations ;		# A hash list containing configuration information for stations
my %parameters ;	# A hash list containing configuration information for parameters
my %limits ;		# A hash list containing configuration information for parameter limits
my %values ;		# A hash list containing values from site log files
my @table ;		# An array containing limit checked values and colors for all stations and all parameters
my $show = 0 ;		# A flag to indicate whether the program should show configuration parameters

sub read_config_stations($)
#
# Reads Config_stations.txt
# e.g. name=BML1 show=y rdlipath=Site_1 rdlmpath=Site_1_RDLm
# Stations is a hash of hash lists, one key for each station.
# The hash list contains the following keys: show, rdlipath, rdlmpath.
# %stations = 
# (
#	bml1 => { show => "y", rdlipath => "Site_1", rdlmpath => "Site_1_RDLm, url => "http://12.235.42.20:8240" },
#	prey => { show => "y", rdlipath => "Site_1", rdlmpath => "Site_1_RDLm },
#	...
# ) ;
# Name is the four letter station code, show determines whether the station is shown.
# RDLiPath/RDLmPath are directories where ideal/measured radials are stored on the combine site.
# URL is used to form a link for the table column title
# Order of entries in file is used to set table column order
#
{
	my ( $config_file ) = @_ ;
	my $stationfilename = "$collectpath/$config_file" ;
	#my $stationfilename = "$collectpath/Config_stations.txt" ;
	if( ! open IN, "<".$stationfilename )
	{
		die "Cannot open $stationfilename\n" ;
	}
	my $line ;
	my $field ;
	my $col = 1 ;
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
		$refhash_stnpar->{status_table_col} = $col ;	# Add key status_table_col set to automatically generated column number
		my $name = $refhash_stnpar->{name} ; # TEMP Extract name from stnpar hash
		$stations{$name} = $refhash_stnpar ; # Use $name as key, stnpar as value
		$col++ ;
	}
	close IN ;
}

sub show_config_stations
{
	printf "\nConfig Stations\n" ;
	printf "%3s %-4s %-4s %-10s %-10s\n", "Col", "Name", "Show", "RDLi Path", "RDLm Path" ;
	my $stnname ;
	my @unsortedkeys = ( keys %stations ) ;
	my @sortedkeys = ( sort { $stations{$a}{status_table_col} <=> $stations{$b}{status_table_col} } @unsortedkeys ) ;
	for $stnname ( @sortedkeys )
	{
		#if( $stations{$stnname}{show} ne "y" ) { next }
		my %stnpar = %{ $stations{$stnname} } ;
		my $col = $stnpar{status_table_col} ;
		my $show = $stnpar{show} ;
		if( ! defined($show) ){ $show="" }
		my $rdlipath = $stnpar{rdlipath} ;
		if( ! defined($rdlipath) ){ $rdlipath="" }
		my $rdlmpath = $stnpar{rdlmpath} ;
		if( ! defined($rdlmpath) ){ $rdlmpath="" }
		printf "%3s %-4s %-4s %-10s %-10s\n", $col, $stnname, $show, $rdlipath, $rdlmpath ;
	}
}


sub read_config_parameters
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

sub show_config_parameters
{
	printf "\nConfig Parameters\n" ;
	printf "%3s %40s %-6s %-4s %-5s %-5s\n", "Row", "Long name", "Short", "Show", "Check", "Graph" ;
	my $parname ;
	my @unsortedkeys = ( keys %parameters ) ;
	my @sortedkeys = ( sort { $parameters{$a}{status_table_row} <=> $parameters{$b}{status_table_row} } @unsortedkeys ) ;
	for $parname ( @sortedkeys )	# Work through each key in parameters
	{
		my %parcfg = %{ $parameters{$parname} } ; # Make a copy of the parameter configuration hash that is held at key $parname
		my $row = $parcfg{status_table_row} ;
		printf "%3s %40s %-6s %-4s %-5s %-5s\n", $row, $parname, $parcfg{short_name}, $parcfg{show}, $parcfg{check}, $parcfg{graph} ;
	}
}

sub read_config_limits
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

sub show_config_limits
{
	my $stnname ;
	for $stnname ( sort keys %limits )	# Work through each station in limits
	{
		if( $stations{$stnname}{show} ne "y" ) { next }
		my %limitset = %{ $limits{$stnname} } ; # Make a copy of the limitset for one station
		my $format = "%40s  %-12s %-12s %-12s %-12s %-6s %-6s\n" ;
		print "\nLimits for station $stnname:\n" ;
		printf $format, "Long name", "low_red", "low_orange", "high_orange", "high_red", "Ymin", "Ymax" ;
		my $parname ;
		for $parname ( sort keys %limitset )	# Work through each parameter in limitset
		{
			my %lim = %{ $limitset{$parname} } ;	# Make a copy of the limits for one parameter
			if( !defined($lim{low_red}) )
			{
				print "Undefined limits for parameter '${parname}'\n" ;
				next
			}
			my $ymin = $lim{ymin} ;
			my $ymax = $lim{ymax} ;
			if( !defined($ymin) ) { $ymin = "" } ;
			if( !defined($ymax) ) { $ymax = "" } ;
			printf $format, $parname, $lim{low_red}, $lim{low_orange}, $lim{high_orange}, $lim{high_red}, $ymin, $ymax ;
		}
	}
}


sub read_radial_values
#
# Reads the file Site_XXXX.log for each station in %stations.
# Example line format: XXXX:Max_Range_km=76.0
# Builds %values, a hash list with a key for each station name whose value is a hash list of values.
# The valueset hash list has a key for each parameter name whose value is the parameter value.
# Example hash list
# %values =
# (
#	bml1 =>
#	{
#		Max_Range => 60,
#		Tx_Temperature => 32,
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
	for $stnname ( keys %stations )
	{
		if( $stations{$stnname}{show} ne "y" ) { next }
		my $sitelogfilename = "$collectpath/Site_${stnname}.log" ;
		if( open IN, "<".$sitelogfilename )
		{
			my $line ;
			my $field ;
			my $refhash_valueset = {} ;	# This is a reference to a hash list with one key for each parameter
			while( defined($line=<IN>) )	# Each line contains the value for one parameter
			{
				chomp $line ;
				my ($stnname, $pev) = split /:/, $line ;
				if( defined($pev) )
				{
					my ($parameter, $value) = split /=/, $pev ;	# pev: parameter equals value, e.g. Collect_Log_Age_Mins=4415 
					if( defined($parameter) )
					{
						$refhash_valueset->{$parameter} = $value ;	# <<< Check if you can't just do: $values{$stnname}{$parameter} = $value ;
					}
				}
			}
			# Now refhash_valueset refers to a completed hash list of values for all parameters
			$values{$stnname} = $refhash_valueset ;
			close IN ;
		}
	}
}



sub show_radial_values
{
	my $stnname ;
	for $stnname ( sort keys %values )	# Work through each station in hash list values
	{
		if( ! defined($stations{$stnname}) ) { next }
		if( ! defined($stations{$stnname}{show}) ) { next }
		if( $stations{$stnname}{show} ne "y" ) { next }
		my %valueset = %{ $values{$stnname} } ;	# Make a copy of the valueset for stnname
		print "\nValues for station ${stnname}:\n" ;
		printf "%40s %-6s\n", "Long name", "Value" ;
		my $parname ;
		for $parname ( sort keys %valueset )	# Work through each parameter name key in valueset
		{
			printf "%40s %-6s\n", $parname, $valueset{$parname} ;
		}
	}
}


sub read_combine_values
#
# Reads a file of values from a combine site
#
# File contains the following parameters:
#	XXXX:Last_Ideal_Radial_Name=RDLi_BML1_2008_10_24_2300.ruv
#	XXXX:Last_Ideal_Radial_Updated_Seconds=1224892097
#	XXXX:Last_Ideal_Radial_Age_Seconds=2491
#	XXXX:Last_Ideal_Radial_Age_Hours=0
#	XXXX:Last_Measured_Radial_Name=RDLm_BML1_2008_10_24_2300.ruv
#	XXXX:Last_Measured_Radial_Updated_Seconds=1224892106
#	XXXX:Last_Measured_Radial_Age_Seconds=2482
#	XXXX:Last_Measured_Radial_Age_Hours=0
#	XXXX:Collect_Log_Age_Mins=4415
#
{
	if( open IN, "<"."$collectpath/collectcp.log" )
	{
		my $line ;
		while( defined($line=<IN>) )
		{
			chomp($line) ;
			my ($stnname, $pev) = split /:/, $line ;
			if( defined($pev) )
			{
				my ($parameter, $value) = split /=/, $pev ;	# pev: parameter equals value, e.g. Collect_Log_Age_Mins=4415 
				if( defined($parameter) )
				{
					$values{$stnname}{$parameter} = $value ;
				}
			}
		}
	}
	close IN ;
}

sub show_combine_values
{
}


sub make_table
#
# Creates the @table array from hash lists %parameters, %stations, %limits and %values.
#
#
{
	my $parname ;
	my @unsortedrowkeys = ( keys %parameters ) ;
	my @sortedrowkeys = ( sort { $parameters{$a}{status_table_row} <=> $parameters{$b}{status_table_row} } @unsortedrowkeys ) ; # sort keys by 'row' value
	for $parname ( "", @sortedrowkeys )	# Work through each parameter to create table rows
	{
		if( ($parname ne "") && ($parameters{$parname}{show} ne "y") ) { next }	# Skip parameters that you don't show
		my $refarr_row = [] ;
		my $stnname ;
		my @unsortedcolkeys = ( keys %stations ) ;
		my @sortedcolkeys = ( sort { $stations{$a}{status_table_col} <=> $stations{$b}{status_table_col} } @unsortedcolkeys ) ; # sort keys by 'col' value
		for $stnname ( "", @sortedcolkeys )	# Work through each station to create table columns
		{
			if( ($stnname ne "") && ($stations{$stnname}{show} ne "y") ) { next }	# Skip station that you don't show
			my $color = "white" ;
			my $value ;
			my $value2 = undef ;
			my $align = "center" ;
			if( $stnname eq "" )	# We're doing the left-most column, set it to a title
			{
				$align = "left" ;
				if( $parname eq "" )	# We're doing the top-left cell, set it to "Parameter" (or whatever you want!)
				{
					$value = "<b>Parameter</b>" ;
				}
				else			# We're doing a row title, set it to the parameter name
				{
					$value = "<b>$parname</b>" ;
					$value =~ s/_/&nbsp/g ;
				}
			}
			else
			{
				if( $parname eq "" )	# We're doing a column title, set it to the station name/URL
				{
					my $link = "" ;
					my $url = $stations{$stnname}{url} ;
					if( not defined $url )	# No url? Just use the station name
					{
						$link .= "<b>$stnname</b>" ;
					}
					else			# Create a link to the station URL with the station name as link text
					{
						$link .= "<a href=\"$url\"" ;
						#$link .= " onClick=\"return normalwindow('$url') ;\"" ; # needs terminating ';'???
						$link .= " onClick=\"return newwindow('$url','') ;\"" ; # needs terminating ';'???
						$link .= ">" ;
						$link .= "<b>$stnname</b>" ;
						$link .= "</a>" ;
					}
					$value = $link ;
				}
				else			# We're doing a cell. Read on...
				{
					$value = $values{$stnname}{$parname} ;
					if( defined($value) && ($value ne "") )
					{
						if( $parameters{$parname}{check} eq "y" )
						{
							$color = "lime" ;
							my $high_red = $limits{$stnname}{$parname}{high_red} ;
							my $high_orange = $limits{$stnname}{$parname}{high_orange} ;
							my $low_red = $limits{$stnname}{$parname}{low_red} ;
							my $low_orange = $limits{$stnname}{$parname}{low_orange} ;
							# >>> TRAP for bad values (numbers instead of strings, vv)
							if( defined($high_orange) && ($high_orange ne "") && ($value >= $high_orange) ) { $color = "orange" ; }
							if( defined($high_red) && ($high_red ne "") && ($value >= $high_red) ) { $color = "red" ; }
							if( defined($low_orange) && ($low_orange ne "") && ($value <= $low_orange) ) { $color = "orange" ; }
							if( defined($low_red) && ($low_red ne "") && ($value <= $low_red) ) { $color = "red" ; }
							# Now we're done using $value, it can be tarted up with html
							$value = "<b>${value}</b>" ;
						}
						if( $parameters{$parname}{graph} eq "y" )
						{
							my $shortname = $parameters{$parname}{short_name} ;
							my $stnshort = "${stnname}_${shortname}" ;
							my $link ;
							$link = "<a href=\"${stnshort}\"" ;
							$link .= " onMouseOver=\"return showplot('Table/${stnshort}.png') ;\"" ;
							$link .= " onClick=\"return newwindow('Table/${stnshort}.png','${stnshort}.png') ;\"" ; # needs terminating ';'???
							$link .= ">" ;
							$link .= "<b>$value</b>" ;
							#$link .= "$value" ;
							$link .= "</a>" ;
							$value = $link ;
							$link = "" ;
							$link = "<a href=\"${stnshort}\"" ;
							$link .= " onClick=\"return newwindow('Table/${stnshort}.png','${stnshort}.png') ;\"" ; # needs terminating ';'???
							$link .= ">" ;
							$link .= "<img src=\"Table/${stnshort}.png\" width=\"160\" alt=\"${stnshort}.png\"/>\n" ;
							$link .= "</a>" ;
							$value2 = $link ;
						}
					}
				}
			}
			# Fill out hash list for this cell
			my $refhash_cell = {} ;
			$refhash_cell->{value} = $value ;
			$refhash_cell->{value2} = $value2 ;	# value2 is used in the imagetable
			$refhash_cell->{align} = $align ;
			$refhash_cell->{color} = $color ;
			# Add cell to row array
			push @$refarr_row, $refhash_cell ;
		}
		#$first_row = 0 ;
		push @table, $refarr_row ;
	}
}


sub write_table($)
#
# Generates an HTML table with colored values for each parameter (row) and station (column)
# Uses the @table array with an entry for each parameter,
#	consisting of an array with an entry for each station,
#		consisting of a hash with keys value, color, link. (need to add align info)
# The first row contains the column headings. 
# The first column contains the row headings.
#
{
	my ( $tablename ) = @_ ;
	my $time_now = 0 ;
	my $tablefilename = "$collectpath/${tablename}.html" ;
	if( ! open OUT, ">".$tablefilename )
	{
		die "Cannot open $tablefilename\n" ;
	}
	# Spew header
	print OUT "<head> ", "\n" ;
	print OUT "<title>BML CODAR Status Table</title> ", "\n" ;
	print OUT "<meta http-equiv=\"refresh\" content=\"60\"> ", "\n" ;
	print OUT "<script language=\"JavaScript\"> ", "\n" ;

	print OUT "<!-- ", "\n" ;
	print OUT "function showplot(filename) ", "\n" ;
	print OUT "{ ", "\n" ;
	print OUT " document.images.ImageArea.src = filename ; ", "\n" ;
	print OUT " return false ; ", "\n" ;
	print OUT "} ", "\n" ;
	print OUT "function newwindow(filename,title) ", "\n" ;
	print OUT "{ ", "\n" ;
	print OUT " window.open(filename,title,'width=820,height=420,resizable=yes'); ", "\n" ;
	print OUT " return false ; ", "\n" ;
	print OUT "} ", "\n" ;
	print OUT "//--> ", "\n" ;

	print OUT "</script> ", "\n" ;
	print OUT "<h1><a href=\"http://bml.ucdavis.edu\"><b>BML</b></a> CODAR Status Table</h1> ", "\n" ;
	print OUT "</head> ", "\n" ;

	print OUT "<body>", "\n" ;
	print OUT "<link href=\"style.css\" rel=\"stylesheet\" type=\"text/css\"> ", "\n" ;
	print OUT "<caption>Updated ".localtime()." local time, ".gmtime()." UTC</caption>", "\n" ;
	print OUT "<br />", "\n" ;
	print OUT "<p><a href=\"${tablename}images.html\">Switch to table of images</a></p> ", "\n" ;

	# Outer table holds both status table and image area in position
	#print OUT "<table frame=\"void\" cellpadding=5 cellspacing=1>", "\n" ;
	#print OUT "<tr>", "\n" ;
	#print OUT "<td>", "\n" ;

	# Inner table with status information
	print OUT "<table border width=450 cellpadding=5 cellspacing=0 class=statustable>", "\n" ;

	my $refarr_row ;
	my $header = 1 ;
	for $refarr_row ( @table )
	{
		my @row = @$refarr_row ;
		my $refhash_col ;
		if( $header ) { print OUT "<thead>" ; }
		print OUT "<tr>\n" ;
		for $refhash_col ( @row )
		{
			my %cell = %{ $refhash_col } ;
			my $value = $cell{value} ;
			my $color = $cell{color} ;
			my $align = $cell{align} ;
			# << TIDY UP IN HERE, remove empty attributes
			if( ! defined $align ) { $align = "" }	# TEMP should be able to remove this
			if( ! defined $color ) { $color = "" }	# TEMP should be able to remove this
			if( ! defined $value ) { $value = "" }	# TEMP should be able to remove this
			printf OUT "<td align=%s bgcolor=%s>%s</td>\n", $align, $color, $value ;
		}
		print OUT "</tr>\n" ;
		if( $header ) { print OUT "</thead>" ; }
		$header = 0 ; # Turn off headers for all normal rows
	}
	# Close inner table
	print OUT "</table>\n" ;

	# Close outer table cell
	#print OUT "</td>\n" ;

	# Spacer cell
	#print OUT "<td>\n" ;
	#print OUT "</td>\n" ;
	# ImageArea cell
	#print OUT "<td>\n" ;
	#print OUT "<img src=\"images/latest.jpg\" width=\"520\" alt=\"Standard Range Current Map\" name=\"ImageArea\"/>\n" ;
	#print OUT "</td>\n" ;
	# Outer table row done
	#print OUT "</tr>\n" ;
	# Outer table done
	#print OUT "</table>\n" ;
	# Done
	print OUT "</body>\n" ;
	close OUT ;
}

sub write_imagestable($)
#
# Generates an HTML table with all the images for each parameter (row) and station (column)
# Uses the @table array with an entry for each parameter,
#	consisting of an array with an entry for each station,
#		consisting of a hash with keys value, color, link. (need to add align info)
# The first row contains the column headings. 
# The first column contains the row headings.
#
{
	my ( $tablename ) = @_ ;
	my $time_now = 0 ;
	my $tablefilename = "$collectpath/${tablename}images.html" ;
	if( ! open OUT, ">".$tablefilename )
	{
		die "Cannot open $tablefilename\n" ;
	}
	# Spew header
	print OUT "<head>\n" ;
	print OUT "<title>BML CODAR Status Table Images</title>\n" ;
	print OUT "<meta http-equiv=\"refresh\" content=\"600\">\n" ;
	print OUT "<script language=\"JavaScript\">\n" ;

	print OUT "<!--\n" ;
	print OUT "function showplot(filename)\n" ;
	print OUT "{\n" ;
	print OUT " document.images.ImageArea.src = filename ;\n" ;
	print OUT " return false ;\n" ;
	print OUT "}\n" ;
	print OUT "function newwindow(filename,title)\n" ;
	print OUT "{\n" ;
	print OUT " window.open(filename,title,'width=820,height=420,resizable=yes');\n" ;
	print OUT " return false ;\n" ;
	print OUT "}\n" ;
	print OUT "function normalwindow(filename)\n" ;
	print OUT "{\n" ;
	print OUT " window.open(filename,'_blank');\n" ;
	print OUT " return false ;\n" ;
	print OUT "}\n" ;
	print OUT "//-->\n" ;

	print OUT "</script>\n" ;
	print OUT "<h1><a href=\"http://bml.ucdavis.edu\"><b>BML</b></a> CODAR Status Table</h1>\n" ;
	print OUT "</head>\n" ;

	print OUT "<body>\n" ;
	print OUT "<link href=\"style.css\" rel=\"stylesheet\" type=\"text/css\">\n" ;
	print OUT "<caption>Updated ".gmtime()." UTC</caption>\n" ;
	print OUT "<br />\n" ;
	print OUT "<p><a href=\"${tablename}.html\">Switch to table of values</a></p>\n" ;

	# Table with status information
	print OUT "<table border width=640 cellpadding=5 cellspacing=0 class=statustable>\n" ;

	my $refarr_row ;
	my $header = 1 ;
	for $refarr_row ( @table )
	{
		my @row = @$refarr_row ;
		my $refhash_col ;
		if( $header ) { print OUT "<thead>" ; }
		print OUT "<tr>\n" ;
		for $refhash_col ( @row )
		{
			my %cell = %{ $refhash_col } ;
			my $value = $cell{value} ;
			my $color = $cell{color} ;
			my $align = $cell{align} ;
			my $value2 = $cell{value2} ;
			if( not defined $value ) { $value = "" ; }
			if( not defined $color ) { $color = "" ; }
			if( not defined $align ) { $align = "" ; }
			if( not defined $value2 )
			{
				printf OUT "<td align=%s bgcolor=%s>%s</td>\n", $align, $color, $value ;
			}
			else
			{
				printf OUT "<td>%s</td>\n", $value2 ;	# Allright, a bit of a hack - value2 is the image tag with link
			}
		}
		print OUT "</tr>\n" ;
		if( $header ) { print OUT "</thead>" ; }
		$header = 0 ; # Turn off headers for all normal rows
	}
	# Close table
	print OUT "</table>\n" ;
	# Done
	print OUT "</body>\n" ;
	close OUT ;
}


sub write_csv
#
# Writes the csv files needed for making graph plots.
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
			# Get a timestamp. Should really read which one from the parameter file, but for now just use the current time.
			my $timestamp = $values{$stnname}{Time_Now_Seconds} ;
			if( defined($timestamp) && ($timestamp > 0) )
			{
				my @timearray = gmtime($timestamp) ;
				my $year = $timearray[5]+1900 ;
				my $mon = $timearray[4]+1 ;
				my $day = $timearray[3] ;
				my $hour = $timearray[2] ;
				my $min = $timearray[1] ;
				my $shortname = $parameters{$parname}{short_name} ;
				my $sitecsvfilename = "$collectpath/data/${stnname}_${shortname}.csv" ;
				my $value = $values{$stnname}{$parname} ;
				if( ! defined($value) ) { next }
				if( open OUT, ">>".$sitecsvfilename )
				{
					printf OUT "%04d %02d %02d %02d %02d, %s\n", $year, $mon, $day, $hour, $min, $value ;
					close OUT ;
				}
			}
		}
	}
}


sub show_all
{
	&show_config_stations ;
	&show_config_parameters ;
	&show_config_limits ;
	&show_radial_values ;
	&show_combine_values ;
}

sub show_usage
{
	print "Usage: $0 configfile tablefile [show]\n" ;
}

sub check_args
{
	my $argc = scalar @ARGV ;
	if( $argc < 2 )
	{
		show_usage() ;
		return 1 ;
	}
	if( $argc >= 3 )
	{
		if( $ARGV[2] eq "show" )
		{
			$show = 1 ;
		}
		else
		{
			show_usage() ;
			return 1 ;
		}
	}
	my $config_file = $ARGV[0] ;
	my $table_file = $ARGV[1] ;
	return ( 0, $config_file, $table_file ) ;
}

sub main()
{
	my ( $err, $config_file, $table_file ) = check_args() ;
	if( $err ) { return 1 ; }
	chdir "$collectpath" ;
	read_config_stations($config_file) ;
	read_config_parameters ;
	read_config_limits ;
	read_radial_values ;
	read_combine_values ;
	make_table ;
	write_table($table_file) ;
	write_imagestable($table_file) ;
	write_csv ;	# This needn't happen every call, but maybe it's easiest if it does.
	if( $show == 1 )
	{
		show_all ;
	}
	return 0 ;
}

exit main() ;

#END

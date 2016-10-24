#!/bin/sh
echo Sleeping 30...
/bin/sleep 30
#
echo
echo Copying log files from radial sites
#cd /Users/codar/scripts/collect
# Host names are mapped to IP addresses in /etc/hosts or in ~/.ssh/config
echo BML1
/usr/bin/rsync -av --timeout=20 codar@bml1:~/scripts/collect/Site_BML1.log .
#
echo
echo Checking combine site
./collectc.pl
#
echo
echo Making tables
./mktable.pl Config_stations.txt table			# creates the default set of html files: tables.html and tablesimages.html
#./mktable.pl Config_stations_bml.txt bml_table		# creates a set of html files for BML stations
#./mktable.pl Config_stations_sfsu.txt sfsu_table	# creates a set of html files for SFSU stations
#./mktable.pl Config_stations_nps.txt nps_table		# creates a set of html files for NPS stations
#
# Trim the csv files in the old-bashioned way
for i in ./data/*.csv ; do sort $i | uniq > ${i}.tmp ; tail -200 ${i}.tmp >$i ; rm -f ${i}.tmp ; done
# Now make png images of plots
echo Making all plots
./mkpng.pl
echo
echo Updating webserver files
cp -pf *table.html ~codar/Sites/
cp -pf *tableimages.html ~codar/Sites/
cp -pf data/*.png ~codar/Sites/Table/
echo Done

#END

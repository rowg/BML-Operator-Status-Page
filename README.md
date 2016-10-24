# BML-Operator-Status-Page


## Overview

These scripts implement the BML operator status monitoring page for CODAR SeaSonde HFR Radial sites. The primary goal of the status page is to create a 'single glance' status summary for a network of radial sites. The status page is static html, formatted as a table showing a number of sites and a number of parameters for each site, where each cell shows the current value of the parameter and its 'stoplight' color coded status. The cells are links to a 48 hour plot of the parameter and the column headers are links to the Radial Webserver address of each radial site. Note that the radial webserver is not accessible on stations that do not support incoming network connections, such as some cellular data modems.

An example status page is at http://boon.ucdavis.edu/hfr_status.html and a snapshot is available at https://github.com/rowg/BML-Operator-Status-Page/blob/master/Example_Status_Table.png

### Prerequisites

The radialsite code requires perl as provided by OSX with only the standard modules. The combinesite scripts also needs perl but no extra modules. The combinesite script mkpng.pl uses gnuplot to create the 2 day plots and if you want the combinesite to serve the status page directly, you will need to enable the OSX webserver. Alternatively you can push the status page to an external webserver.



## Code Description

The implementation is in two parts: radialsite and combinesite, where the radialsite script is responsible for generating the site status log file and the combinesite scripts are responsible for generating the status pages.

### Radial Site

The radialsite code consists of one perl script that is periodically run from cron or launchd. It creates a text file containing all the site status information and the file is then pulled by the combinesite or pushed by the radialsite, depending on your preference for file transfers.

### Combine Site

The combinesite code consists of a perl script that is called periodically by cron or launchd. It first transfers all site log files except those that must be pushed, then it examines each site log file in turn, compares the parameters with predetermined limit values and generates the status table. The current values are stored and the 48 hour plots are generated using gnuplot. The finished table is then copied to the webserver document root.

## Installation

### Radial Site

At the radial site there is only one script called collect.pl, installed wherever you like, but my convention is to use ~codar/scripts/collect because the /Codar/SeaSonde/Users/Scripts location has previously gotten squashed by Radial Suite updates.

The script collect.pl must be made executable if it isn't already, using:
`chmod +x collect.pl`

Run the script manually to test it (check for no error messages):
`./collect.pl`

and check that it wrote an output file Site_XXXX.log. The script relies on the Header.txt file to provide the site name and it generates a file called Site_XXXX.log in the current directory.

You should also check that it correctly reads the disk space available on the backup/archive drive because it assumes that the volume is called CodarArchives. You can either use this name for your archive volume or change the script to use whatever volume name you have. This can be changed on line 63 of the collect.pl script:
`my $archive="/Volumes/CodarArchives" ;`

To call the script periodically, either create a cron job or a launchd plist to run collect.pl from the scripts directory every 10 minutes. For cron this looks like:
`*/10	*	*	*	*	cd ~/scripts/collect ; ./collect.pl`

Add a suitable line to whatever file transfer mechanism you're using and your radial site installation is finished.


### Combine Site

At the combine site, the installation is a little more involved but you only need to do this once for all your radial sites. If you do not operate a combine site, this code can be run on any computer that is available, or you can request to have your radial sites displayed on an exsting status page such as the one at BML.

By convention the scripts are installed in ~codar/scripts/collect but they can be installed elsewhere.

The scripts are named as follows:
**cron.sh**		The entry point script that gets called from cron, calls collectc.pl, mktable.pl and mkpng.pl</br>
**collectc.pl**	Checks for up to date radial files at the combine site.</br>
**mktable.pl**	Generates the table.html and tableimages.html files for the webserver.</br>
**mkpng.pl**	Makes each of the 48 hour plots using gnuplot.</br>


The script mktable.pl uses a number of parameter files that defined the layout of the table in terms of which radial sites you want to monitor, which parameters you want to monitor and what the parameter limits are:
**Config_stations.txt**	Lists the radial sites you wish to monitor.</br>
**Config_parameters.txt**	Lists the parameters you wish to monitor.</br>
**Config_limits_BML1.txt**	Lists the parameter limits for a specific radial site.</br>
**Site_BML1.log**		The status log file from a specific radial site.</br>
**table.html**		The output file containing the status table.</br>
**tableimages.html**	An alternative output file containing a table of thumbnail images.</br>

Normally you will need to adjust the contents of the Config_stations.txt file only.


The Config_stations.txt file has the following format:
`name=BML1 show=y rdlipath=Site_1 rdlmpath=Site_1_RDLm url=http://12.235.42.20:8240`</br>
`name=PREY show=y rdlipath=Site_2 rdlmpath=Site_2_RDLm`</br>
`name=GCVE show=n`</br>
`name=BMLR show=y rdlipath=Site_5 rdlmpath=Site_5_RDLm url=http://12.235.42.23:8240`</br>
`name=PAFS show=y rdlipath=Site_6 rdlmpath=Site_6_RDLm url=http://166.130.35.187:8240`</br>

The parameter **name** is used to locate the Site_XXXX.log file, name the site and locate the Config_limits_XXXX.txt file.
**show** is used to enable or disable the display of the site in the table.</br>
**rdlipath** points to the subdirectory containing the ideal pattern radial files under /Codar/SeaSonde/RadialSites/.</br>
**rdlmpath** points to the subdirectory containing the measured pattern radial files under /Codar/SeaSonde/RadialSites/.</br>
**url** is the link at the radial site column header and normally points to the Radial WebServer URL and port.</br>


The Config_parameters.txt file has the following format:<br>
`long_name=Xfer_Ideal_Radial_Name			short_name=	show=n	check=n	graph=n`<br>
`long_name=Xfer_Ideal_Radial_Short_Name			short_name=	show=y	check=n	graph=n`<br>
`long_name=Xfer_Ideal_Radial_Updated_Seconds		short_name=	show=n	check=n	graph=n`<br>
`long_name=Xfer_Ideal_Radial_Age_Seconds			short_name=	show=n	check=n	graph=n`<br>
`long_name=Xfer_Ideal_Radial_Age_Hours			short_name=XIRA	show=y	check=y	graph=y`<br>
`long_name=Xfer_Measured_Radial_Name			short_name=	show=n	check=n	graph=n`<br>
`long_name=Xfer_Measured_Radial_Short_Name		short_name=	show=y	check=n	graph=n`<br>
`long_name=Xfer_Measured_Radial_Updated_Seconds		short_name=	show=n	check=n	graph=n`<br>
`long_name=Xfer_Measured_Radial_Age_Seconds		short_name=	show=n	check=n	graph=n`<br>
`long_name=Xfer_Measured_Radial_Age_Hours		short_name=XMRA	show=y	check=y	graph=y`<br>

Here **long_name** is used to locate the parameter in the Site_XXXX.log file.
**short name** is used to create parameter specific files under data/.</br>
**show** is a flag to enable or disable the entire row for all radial sites.</br>
**check** is a flag to enable color coding the entire row for all radial sites, or color the row white.</br>
**graph** is a flag to enable or disable generating a plot.</br>


The Config_limits_XXXX.txt file has the following format:
`long_name=Last_RDLm_Age_Hours				low_red=-1	low_orange=-1	high_orange=2	high_red=3`</br>
`long_name=Last_RDLi_Age_Hours				low_red=-1	low_orange=-1	high_orange=2	high_red=3`</br>
`long_name=Root_Disk_Available_GB			low_red=10	low_orange=15`</br>
`long_name=Archive_Disk_Available_GB			low_red=10	low_orange=15`</br>

Here **long_name** is used to locate the parameter in the Site_XXXX.log file.
**low_red** defines the value below which the cell is colored red.</br>
**low_orange** defines the value below which the cell is colored orange.</br>
**high_orange** defines the value above which the cell is colored orange.</br>
**high_red** defines the value above which the cell is colored red.</br>

The cell is green if the value lies between low_orange and high_orange.

Note that when you change the limits, the color coding will be updated on the next call to mktable.pl but in order to update the limit lines drawn on the plots you need to delete the corresponding gnuplot files data/XXXX.gp, described below.

### Plotting

The 48 hour plots are generated by mkplot.png using data stored in a CSV file in the subdirectory data/ and the limits defined in the Config_limits_XXXX.txt file. The mkpngpl script first generates a gnuplot command file called XXXX.gp in the data/ subdirectory and then calls gnuplot with the command file. If you change the limits in the Config_limits_XXXX.txt file, you must delete the corresponding gp file to cause it to be regenerated. You may delete all gp files, they will be regenerated automatically.

If you installed gnuplot as an Application rather than using a package manager, you may need to explicitly identify the path of the gnuplot executable in the mkpng.pl script at line 14.

If you do not have gnuplot, don't want the hassle of installing it or just don't want plots, you can disable them by commenting out the call to mkpng.pl in cron.sh at line 107 and the cp command that copies the png files on line 108.

### Style

The status page is a static html file that is rendered according to the styles defined in 'style.css', located in the same directory as the table.html files.



## Finally

These scripts are deliberately very simple and unsophisticated so that you can easily extend them to do other things. For example, if you want to add a parameter to check for something new, you add the relevant code to the radialsite collect.pl script that causes the new parameter to appear in the Site_XXX.log file and you add the parameter to the Config_parameters.txt and Config_limits_XXXX.txt files on the combinesite and you're done. If you want to change the way that the log files are transferred from the radialsite tothe combinesite, you add or delete the commands from the cron.sh script.

If there's anything you want me to add, just let me know.

Marcel
mlosekoot@ucdavis.edu or boondata@ucdavis.edu




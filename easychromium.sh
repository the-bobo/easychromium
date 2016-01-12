#!/bin/bash

# run by typing: bash easychromium.sh

# This script installs the latest version of the open source Chromium browser for OS X
# It pulls the code from google and builds it locally on your machine
# Run it in the folder where you want to install Chromium
# Suggestion: /Applications/Chromium

# TO DO
# output everything to stdout and $LOGFILE
# add ccache support - check for existence, proper versioning, update/patch to correct version, compile with it
# search for @#@ as an in-line to do marker thoughout the script

####################
####################
# PRE-BUILD BEGIN
####################
####################

# initialize logfile, appends by default and creates if not found

LOGFILE="./logeasychromium.log"

echo "=========New Build Attempt=========" | tee -a $LOGFILE
echo $(date) | tee -a $LOGFILE
echo "=========New Build Attempt=========" | tee -a $LOGFILE

# check OS X version, can be used in future for choosing different code flows on basis of OS version

OS_VERSION=$(sw_vers -productVersion)
echo "OS X Version "$OS_VERSION" detected" | tee -a $LOGFILE



#########################
# SOFTWARE VERSION CHECKS
#########################

###
# Based in part on version checker code cc by-sa 3.0
# Courtesy http://stackoverflow.com/users/1032785/jordanm at http://stackoverflow.com/a/11602790
###

# git >= 2.2.1
	# @#@ - make this automatically upgrade git , see comments below
	# @#@ - make this output git path (which git) to LOGFILE - which may behave unexpectedly: http://stackoverflow.com/a/677212
	# @#@ - do i need commmand -v git or command -V git? which will work correctly on a system without git?

if command -V git >/dev/null 2>&1; then

	for cmd in git; do
		[[ $("$cmd" --version) =~ ([0-9][.][0-9.]*) ]] && version="${BASH_REMATCH[1]}"
		if ! awk -v ver="$version" 'BEGIN { if (ver < 2.2.1) exit 1; }'; then
			echo 'ERROR: '$cmd' version 2.2.1 or higher required' | tee -a $LOGFILE
			exit 1;
		fi
	done
else 
	echo "ERROR: git is not installed, please install Xcode and xcode-cli to get git, or brew install git" | tee -a $LOGFILE
	exit 1;
fi
		# git version --> $LOGFILE
		# git path --> $LOGFILE
		# if git not detected, advise user to install Xcode
		# else, if git detected
				# which git
					# if /usr/local/bin/git stdout "attempting to update git using homebrew" and --> LOGFILE
					# brew update && brew upgrade git
					# else if /usr/bin/git
					# stdout "STOPPING - you need to update xcode to 5+ before proceeding, recommended version is 6.4:  https://developer.apple.com/support/xcode/" and --> $LOGFILE

# XCode >= 5
	# @#@ need to validate this works when user has Xcode 5.0 installed - should we check against 5.0 or 5.0.0?
	# @#@ need to validate the if logic works for users with neither xcode nor xcode-cli installed
	# @#@ need to output path of XCode to logfile (useful for users with multiple XCode versions installed, eventually
	#	we can enable user selecting specific versino of Xcode to build with by providing a path maybe?)

	# sample response when Xcode is not installed but xcode-cli is:
	# xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance
	# sample response when Xcode and xcode-cli are both missing:
	# xcode-select: note: no developer tools were found at '/Applications/Xcode.app', requesting install. Choose an option in the dialog to download the command line developer tools.

XCODE_CHECK="$(command xcodebuild 2>&1)"
if [[ "$XCODE_CHECK"=~"error" ]]; then
	echo "Xcode not found, please see xcodehelp.txt in this repository and install Xcode." | tee -a $LOGFILE
	exit 1;

elif [[ "$XCODE_CHECK"=~"note" ]]; then
	echo "Xcode and xcode-cli not found, please see xcodehelp.txt in this repository and install Xcode." | tee -a $LOGFILE
	exit 1;

else
	echo "Xcode detected, testing version" | tee -a LOGFILE
	for cmd in xcodebuild; do
		[[ $("$cmd" -version) =~ ([0-9][.][0-9.]*) ]] && version="${BASH_REMATCH[1]}"
		if ! awk -v ver="$version" 'BEGIN { if (ver < 5.0) exit 1; }'; then
			echo 'ERROR: '$cmd' version 5.0 or higher required' | tee -a $LOGFILE
			echo 'Version detected was: '$version | tee -a $LOGFILE
			exit 1;
		fi
	done
fi

# has xcode-cli?
	# @#@ need to implement xcode-cli testing and path output to $LOGFILE
		# xcode-cli version --> $LOGFILE
		# xcode-cli path --> $LOGFILE
			# else, xcode-select --install
			# installed xcode-cli using xcode-select --install --> $LOGFILE
			# xcode-cli version and path --> $LOGFILE

# has depot_tools? (check by trying 'gclient')
	# @#@ need to output depot_tools version and path to $LOGFILE
	# @#@ is there version checking we need to do here?
	# see http://dev.chromium.org/developers/how-tos/install-depot-tools 
	# see http://dev.chromium.org/developers/how-tos/depottools
	# see http://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools.html

DEPOT_CHECK="$(command -V gclient 2>&1)"
if [[ DEPOT_CHECK=~"not found" ]]; then
	echo "depot_tools not found, try checking your PATH" | tee -a $LOGFILE
	echo "Alternatively, easychromium can try to install depot_tools for you." | tee -a $LOGFILE
	read -r -p "Install depot_tools? (Y/n) " response
	if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo "trying to install depot_tools" | tee -a $LOGFILE
		# insert install for depot_tools, see http://dev.chromium.org/developers/how-tos/install-depot-tools
	else
		echo "no depot_tools found, user chose not to auto-install, exiting" | tee -a $LOGFILE
		exit 1;
	fi
else
	echo "depot_tools found, proceeding" | tee -a $LOGFILE
fi


		# depot_tools version --> $LOGFILE
		# depot_tools path --> $LOGFILE
			# else, "no depot_tools detected, installing depot_tools" --> $LOGFILE
			# 

# config file inputs
	# config file exists? (./config.txt) 
		# if no, stdout "no configuration file found, expected ./config.txt \n using defaults, no API's will be loaded" --> $LOGFILE
		# if yes, output "configuration file found, using ./config.txt" --> $LOGFILE

####################
####################
# PRE-BUILD COMPLETE
####################
####################


####################
####################
# BUILD SETUP BEGIN
####################
####################

# @#@ should check to see if depot_tools already exists / if needs updating
# download depot_tools, see: http://dev.chromium.org/developers/how-tos/install-depot-tools
#echo "Downloading depot_tools from https://chromium.googlesource.com/chromium/tools/depot_tools.git" | tee -a $LOGFILE
#git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git



####################
# BUILD SETUP END
####################
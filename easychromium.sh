#!/bin/bash

# run by typing: bash easychromium.sh

# This script installs the latest version of the open source Chromium browser for OS X
# It pulls the code from google and builds it locally on your machine
# Run it in the folder where you want to install Chromium
	# WARNING: path to build directory must NOT contain spaces
# After it builds cp [PATH TO YOUR CHROMIUM DIRECTORY]/Chromium/src/out/Debug/Chromium.app /Applications

# TO DO
# must update .gclient and set GYP_DEFINES before building - see http://stackoverflow.com/questions/13316437/insert-lines-in-a-file-starting-from-a-specific-line
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

echo "Beginning software version checks" | tee -a $LOGFILE

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
	#	we can enable user selecting specific version of Xcode to build with by providing a path maybe?)

	# sample response when Xcode is not installed but xcode-cli is:
	# xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance
	# sample response when Xcode and xcode-cli are both missing:
	# xcode-select: note: no developer tools were found at '/Applications/Xcode.app', requesting install. Choose an option in the dialog to download the command line developer tools.
	# sample response when Xcode 7.2 build ver 7C68 is installed (for running xcodebuild):
	# xcodebuild: error: The directory /Users/bobo does not contain an Xcode project.
	# sample response when Xcode 7.2 is installed, but license not agreed to:
	# 	Agreeing to the Xcode/iOS license requires admin privileges, please re-run as root via sudo.

XCODE_CHECK="$(command xcodebuild 2>&1)"
if [[ "$XCODE_CHECK"=~"requires" ]]; then
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
		echo "Trying to install depot_tools, see see http://dev.chromium.org/developers/how-tos/install-depot-tools for more" | tee -a $LOGFILE
		echo "Downloading depot_tools from https://chromium.googlesource.com/chromium/tools/depot_tools.git" | tee -a $LOGFILE
		git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
		if [[ $? -eq 0 ]]; then
			echo "git clone successful" | tee -a $LOGFILE
		else
			echo "git clone of depot_tools failed, exiting" | tee -a $LOGFILE
			exit 1;
		fi
		
		echo "Exporting depot_tools to PATH" | tee -a $LOGFILE
		export PATH=`pwd`/depot_tools:"$PATH"
		if [[ $? - eq 0 ]]; then
			echo "PATH updated to $PATH" | tee -a $LOGFILE
			echo "this PATH update is non-permanent, only for this shell session" | tee -a $LOGFILE
		else
			echo "Error updating PATH with depot_tools, exiting" | tee -a $LOGFILE
			exit 1;
		fi
	else
		echo "no depot_tools found, user chose not to auto-install, exiting" | tee -a $LOGFILE
		exit 1;
	fi
else
	echo "depot_tools found, proceeding" | tee -a $LOGFILE
fi



echo "Software checks finished" | tee -a $LOGFILE


####################
####################
# PRE-BUILD END
####################
####################

echo "#### PRE-BUILD COMPLETE ####" | tee -a $LOGFILE


####################
####################
# BUILD SETUP BEGIN
####################
####################

echo "#### BUILD SETUP BEGINNING ####" | tee -a $LOGFILE

echo "Checking for config file ./config.txt" | tee -a $LOGFILE

if [[ -f "./config.txt" ]]; then 
	echo "./config.txt exists, but integration not supported yet, not using - no google APIs will be installed" | tee -a $LOGFILE
	# @#@ to do - implement scrubbing config.txt for paramaters into ./build/gyp_chromium or a GYP_DEFINES environment variable
	# @#@ to do - or, do these need to go elsewhere? seems like we just need client id, secret, and one other? http://dev.chromium.org/developers/how-tos/api-keys
	# @#@ - after importing keys run gclient sync, test to make sure runs successfully
else
	echo "./config.txt does not exist, proceeding with defaults - no google APIs will be installed" | tee -a $LOGFILE
fi

echo "Building local gclient config file for build using gclient config https://src.chromium.org/svn/trunk/src https://chromium-status.appspot.com/lkgr" | tee -a $LOGFILE
gclient config https://src.chromium.org/svn/trunk/src https://chromium-status.appspot.com/lkgr
if [[ $? -eq 0 ]]; then
	echo ".gclient config file successfully built" | tee -a $LOGFILE
else
	echo ".gclient config file failed, check console for errors, exiting" | tee -a $LOGFILE
	exit 1;
fi

echo "Choose yes below for faster download, no to stick with defaults" | tee -a $LOGFILE
read -r -p "Automatically tweak .gclient config file for faster download/build time? (Y/n) " response
	if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
		# how to edit .gclient file?
		: <<'COMMENT'
		echo "testing line insertion in .gclient"
		filetext="$(cat ./.gclient)"
		echo "$filetext"
		insert='    FOO'
		match='    "custom_deps" : {'
		#match='solutions'
		echo "match: $match"
		# the empty "" is needed because sed -i on OS X expects a mandatory file extension, which .gclient lacks
		# see http://stackoverflow.com/a/28592391
		# the actual newline instead of \n is necessary because OS X's old BSD sed is weird
		# see http://stackoverflow.com/a/24276470/3277902 for the comprehensive BSD/linux sed differences
		sed -i "" "s/$match/$match"'\
		'"$insert/" .gclient
		echo "new file"
		cat .gclient
COMMENT

	else
		echo "User chose not to tweak .gclient config file, proceeding with defaults" | tee -a $LOGFILE
		file="$(cat ./.gclient)"
		echo "$file" | tee -a $LOGFILE
	fi


####################
####################
# BUILD SETUP END
####################
####################

echo "#### BUILD SETUP COMPLETE ####" | tee -a $LOGFILE

####################
####################
# BUILD BEGIN
####################
####################

echo "#### BEGIN BUILD ####" | tee -a $LOGFILE

# check waterfall status

echo "Checking waterfall to confirm Tree is Open - this is not implemented yet, assuimg Tree OPEN" | tee -a $LOGFILE
	# @#@ see https://build.chromium.org/p/chromium/console and https://build.chromium.org/p/chromium/json/help
	# appears to have a JSON API but not sure how to poll it
	# need to implement automatic confirmation of open status on tree before proceeding 
	# see also http://chromium.googlecode.com/svn-history/r4675/wiki/UsefulURLs.wiki
	# appears that http://chromium-status.appspot.com/lkgr provides a commit hash of last known good revision
	# and https://build.chromium.org/p/chromium/lkgr-status/ includes a link for that hash
	# example: https://chromium.googlesource.com/chromium/src/+/ba29be9b6599986753d10305513c10a87f0764d8
		# what's after /+/ is the hash returned by /lkgr and linked to on /lkgr-status

echo "Fetching fresh stable version of the code, ~6.5GB expected" | tee -a $LOGFILE
echo "Future versions of this script should permit updating a current fetch instead of fetching full source" | tee -a $LOGFILE

# get the shallow version of the code, ~6.5GB: 
fetch --nohooks --no-history chromium 
if [[ $? -eq 0 ]]; then
	echo "code successfully fetched" | tee -a $LOGFILE
else
	echo "code fetch failed, check console for errors, exiting" | tee -a $LOGFILE
	exit 1;
fi
	# should this be "gclient sync" instead? see - https://www.ulyaoth.net/resources/tutorial-install-chromium-from-source-on-mac-os-x.43/
	# @#@ - fetching code should allow updating the code instead of pulling down a fresh copy
	# @#@ - for example: gclient sync --revision src@##### where ##### is the latest green revision number
	# see - https://www.ulyaoth.net/resources/tutorial-install-chromium-from-source-on-mac-os-x.43/

echo "setting GYP_DEFINES for fastbuild=1" | tee -a $LOGFILE
# @#@# - set { 'GYP_DEFINES': 'fastbuild=1' }
# see - https://www.chromium.org/developers/gyp-environment-variables

echo "building the code using ninja" | tee -a $LOGFILE
# build the code
ninja -C out/Debug chrome

if [[ $? -eq 0 ]]; then
	echo "Chromium successfully built, exiting without errors" | tee -a $LOGFILE
	exit 0;
else
	echo "Chromium build failed, check console for errors, exiting" | tee -a $LOGFILE
	exit 1;
fi

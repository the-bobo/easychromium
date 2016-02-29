#!/bin/bash

# run by typing: bash easychromium.sh

# you need: XCode 5+, OSX 10.9+, ~10-20GB of space, ~3-5 hours (on 16GB RAM, more if less RAM)

# This script builds the latest version of the open source Chromium browser for OS X from source
# Copy the [your folder]/src/out/Release/Chromium.app file into /Applications/ when it finishes


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


#########################
# git check
#########################


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


#########################
# xcode check
#########################


XCODE_CHECK="$(command xcodebuild -version 2>&1)"
if [[ "$XCODE_CHECK" =~ "requires" ]]; then
	echo "Xcode not found, please see xcodehelp.txt in this repository and install Xcode." | tee -a $LOGFILE
	exit 1;

elif [[ "$XCODE_CHECK" =~ "note" ]]; then
	echo "Xcode and xcode-cli not found, please see xcodehelp.txt in this repository and install Xcode." | tee -a $LOGFILE
	exit 1;

else
	echo "Xcode detected, testing version" | tee -a $LOGFILE
	for cmd in xcodebuild; do
		[[ $("$cmd" -version) =~ ([0-9][.][0-9.]*) ]] && version="${BASH_REMATCH[1]}"
		if ! awk -v ver="$version" 'BEGIN { if (ver < 5.0) exit 1; }'; then
			echo 'ERROR: '$cmd' version 5.0 or higher required' | tee -a $LOGFILE
			echo 'XCode version detected was: '$version | tee -a $LOGFILE
			exit 1;
		fi
		echo 'XCode version detected was: '$version | tee -a $LOGFILE
	done
fi


#########################
# depot_tools check
#########################


if [ -d ./depot_tools/ ]
	then
	echo "./depot_tools/ found, updating PATH" | tee -a $LOGFILE
else
	echo "./depot_tools/ not found, git cloning to get it" | tee -a $LOGFILE
	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
	if [[ $? -eq 0 ]]; then
		echo "git clone of depot_tools successful" | tee -a $LOGFILE
	else
		echo "git clone of depot_tools failed, exiting" | tee -a $LOGFILE
		exit 1;
	fi
fi

export PATH=`pwd`/depot_tools:"$PATH"
if [[ $? -eq 0 ]]; then
	echo "PATH successfully updated to $PATH" | tee -a $LOGFILE
	echo "this PATH update is non-permanent, only for this shell session" | tee -a $LOGFILE
else
	echo "Error updating PATH with depot_tools, exiting" | tee -a $LOGFILE
	exit 1;
fi


####################
####################
# PRE-BUILD END
####################
####################

echo "#### PRE-BUILD COMPLETE ####" | tee -a $LOGFILE


####################
####################
# BUILD BEGIN
####################
####################

echo "#### BEGIN BUILD ####" | tee -a $LOGFILE


cd src
git fetch --tags origin | tee -a $LOGFILE
export GYP_DEFINES="fastbuild=1 mac_strip_release=1 buildtype=Official"
gclient sync --verbose --verbose --verbose --jobs 16 | tee -a $LOGFILE
git checkout -b new_release tags/48.0.2564.116 | tee -a $LOGFILE
gclient sync --verbose --verbose --verbose --with_branch_heads --jobs 16 | tee -a $LOGFILE
git checkout master | tee -a $LOGFILE
gclient sync --verbose --verbose --verbose --jobs 16 | tee -a $LOGFILE
git checkout new_release | tee -a $LOGFILE
gclient sync --verbose --verbose --verbose --with_branch_heads --jobs 16 | tee -a $LOGFILE
ninja -C out/Release chrome | tee -a $LOGFILE
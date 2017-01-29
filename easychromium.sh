#!/bin/bash

# run by typing: bash easychromium.sh

# you need: XCode 5+, OSX 10.9+, ~10-20GB of space, ~3-5 hours (on 16GB RAM, more if less RAM)

# This script builds the latest version of the open source Chromium browser for OS X from source
# Copy the [your folder]/src/out/Release/Chromium.app file into /Applications/ when it finishes

# DOES check to see if you already have the source code downloaded
# DOES check to see if the latest version is ahead of locally installed version


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
		var1=$(echo "$version" | cut -d. -f1)
		var2=$(echo "$version" | cut -d. -f2)
		var3=$(echo "$version" | cut -d. -f3)
		
		if [[ $var1 -lt 2 ]]; then
			echo 'ERROR: '$cmd' version 2.2.1 or higher required' | tee -a $LOGFILE
			exit 1;
		fi
		if [[ $var1 -gt 2 && $var2 -lt 2 ]]; then
			echo 'ERROR: '$cmd' version 2.2.1 or higher required' | tee -a $LOGFILE
			exit 1;
		fi
		if [[ $var1 -gt 2 && $var2 -gt 2 && $var3 -lt 1 ]]; then
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

# retrieves CSV of current Chromium releases, saves in a file "releasestargets" without extension
curl https://omahaproxy.appspot.com/all -o releasestargets

# returns the version number of the current stable Chromium release for mac, cutting on the comma 
# sample: 48.0.2564.116
TARGET=$(grep mac,stable, releasestargets | cut -d, -f3)
echo "target Chromium version is: $TARGET" | tee -a $LOGFILE
rm releasestargets

if [ -d /Applications/Chromium.app/ ]
  then
  echo "Chromium exists in /Applications/" | tee -a $LOGFILE
  echo "checking if latest stable release is newer than current install" | tee -a $LOGFILE
  CURRENT=$(mdls -name kMDItemVersion /Applications/Chromium.app/ | awk '/kMDItemVersion/{print $NF}' | sed 's/"//g')
  echo "current version is: $CURRENT"

  version_1=$TARGET
  version_2=$CURRENT

	#The following bash function will return 0 (true) if $version_1 > $version_2, 1 (false) otherwise, 
	#as long as the variables $version_1 and $version_2 both contain only an arbitrary number of digit groups separated by periods
	#adapted from code by kopischke (credit cc-by-sa 3.0) on stack exchange: http://apple.stackexchange.com/a/86362

	function versions_check {
		while [[ $version_1 != "0" || $version_2 != "0" ]]; do
			(( ${version_1%%.*} > ${version_2%%.*} )) && return 0
			[[ ${version_1} =~ "." ]] && version_1="${version_1#*.}" || version_1=0
			[[ ${version_2} =~ "." ]] && version_2="${version_2#*.}" || version_2=0
		done
		false
}
	#Implementing other comparisons, like greater or equal, is as simple as changing the comparison operator of the arithmetic 
	#evaluation, i.e. (( ${version_1%%.*} >= "${version_2%%.*}" )).

	versions_check $version_1 $version_2
	if [[ $? -eq 0 ]]; then
		echo "TARGET version is newer than CURRENT, proceeding to update" | tee -a $LOGFILE
	else
		echo "TARGET version is NOT newer than CURRENT, aborting" | tee -a $LOGFILE
		exit 1;
	fi
else
  echo "Chromium not found in /Applications/, proceeding to build from latest stable release" | tee -a $LOGFIE
fi

if [ -d ./src/ ]
	then
	echo "./src/ found, proceeding to gclient sync master" | tee -a $LOGFILE
else
	echo "./src/ not found, assuming this is a fresh install, fetching chromium" | tee -a $LOGFILE
	fetch chromium | tee -a $LOGFILE
fi

cd src
SRC_PATH=`pwd`
echo "$SRC_PATH"


git checkout master
git fetch --tags origin | tee -a $LOGFILE
# export GYP_DEFINES="fastbuild=1 mac_strip_release=1 ffmpeg_branding=Chrome proprietary_codecs=1 buildtype=Official"

gclient sync --verbose --verbose --verbose --jobs 16 | tee -a $LOGFILE
git checkout -b new_release$TARGET tags/$TARGET | tee -a $LOGFILE
gclient sync --verbose --verbose --verbose --with_branch_heads --jobs 16 | tee -a $LOGFILE
git checkout master | tee -a $LOGFILE
gclient sync --verbose --verbose --verbose --jobs 16 | tee -a $LOGFILE
git checkout new_release$TARGET | tee -a $LOGFILE

#export GYP_DEFINES="fastbuild=1 mac_strip_release=1 ffmpeg_branding=Chrome proprietary_codecs=1 buildtype=Official"

# build args.gn (replacement for obsolete GYP_DEFINES)
touch "args.gn"
echo -e 'symbol_level=1\nenable_stripping=true\nffmpeg_branding="Chrome"\nproprietary_codecs=1\nis_official_build=true' > ./args.gn

gclient sync --verbose --verbose --verbose --with_branch_heads --jobs 16 | tee -a $LOGFILE

echo "after all the gclient sync my pwd is: " | tee -a $LOGFILE
pwd | tee -a $LOGFILE
echo "gonna try to cd to src_path" | tee -a $LOGFILE
cd "$SRC_PATH" | tee -a $LOGFILE
echo "my new pwd is: " | tee -a $LOGFILE
pwd | tee -a $LOGFILE
gn gen out/foo | tee -a $LOGFILE
ninja -C out/foo chrome | tee -a $LOGFILE

#ARG_VAR="$SRC_VAR/out/Release chrome"
#ninja -C "$ARG_VAR"
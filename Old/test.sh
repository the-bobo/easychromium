#!/bin/bash

# this outputs to console and appends it to logfile (creating logfile if needed)
# 	echo "my message" | tee -a ./easychromium.log

# this is a multiline comment
# : <<'COMMENT'
# code
# code
# code
# COMMENT

# save to a filepath determined by a variable
# LOGFILE="./logtest.log"
# echo "does this work?" | tee -a $LOGFILE

# $? - use that to see what the last executed command exited with 
#	1 is an error condition, 0 is a successful exit

# see http://mywiki.wooledge.org/BashFAQ/031
# for notes on [ ] vs. [[ ]] (for bash on OS X, just use [[ ]])

# redirect stderr to stdout: append 2>&1 to the command
#	example: XCODE_CHECK="$(command xcodebuild 2>&1)"
#	that captures the stderr and stdout of that command in the variable "$XCODE_CHECK"
#	use double quotes to preserve newlines in the variable
#	0 == stdin, 1 == stdout, 2 == stderr

# command -v is verbose. -V is more verbose.

# list of conditionals in bash: http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_07_01.html

if [ $# -lt 1 ]; then
	echo "Usage : bash easychromium.sh <OPTION>"
	echo ""
	echo "Currently supported <OPTION>'s:  defaults, interactive"
	echo ""
	echo "defaults builds and installs Release version of stable branch of Chromium"
	echo "    -defaults uses a local .gclient if one exists"
	echo "defaults copies built Chromium to /Applications/"
	echo "    -defaults does not replace or remove existing user profiles"
	echo "    -move or rename existing Chromium.app files in /Applications/ to avoid overwriting"
	echo ""
	echo "interactive permits user interaction for various build options"
	echo ""
	echo "Future pull requests welcome to enable other <OPTION>'s"
	echo "e.g.: debug, beta, canary"
	echo ""
	echo ""
	exit 1;
fi

case "$1" in
	defaults )
	echo "Running with defaults" | tee -a $LOGFILE 
	flag="defaults"
	;;

	interactive )
	echo "Running with interactive" | tee -a $LOGFILE 
	flag="interactive"
	;;

	* )
	echo "Usage : bash easychromium.sh <OPTION>"
	echo ""
	echo "Currently supported <OPTION>'s:  defaults, interactive"
	echo ""
	echo "defaults builds and installs Release version of stable branch of Chromium"
	echo "    -defaults uses a local .gclient if one exists"
	echo "defaults copies built Chromium to /Applications/"
	echo "    -defaults does not replace or remove existing user profiles"
	echo "    -move or rename existing Chromium.app file in /Applications/ to avoid overwriting"
	echo ""
	echo "interactive permits user interaction for various build options"
	echo ""
	echo "Future pull requests welcome to enable other <OPTION>'s"
	echo "e.g.: debug, beta, canary"
	echo ""
	echo ""
	exit 1;
	;;
esac



case "$flag" in
	defaults )
	echo "flag is defaults" | tee -a $LOGFILE
	response="yes"
	;;

	interactive )
	echo "flag is interactive" | tee -a $LOGFILE
	read -r -p "Automatically tweak .gclient config file for faster download/build time? (Y/n) " response
	;;
esac

if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then	
	echo "you said yes!"
else
	echo "you said no"
fi

OS_VERSION=$(sw_vers -productVersion)
LOGFILE="./logtest.log"

echo "does this work?" | tee -a $LOGFILE

echo "testing substring match"
fuu="hello harry"
bar=""

if [[ $fuu =~ $bar ]]; then
	echo "found it"
else
	echo "did not find it"
fi

: <<'COMMENT'
echo "testing xcode_check"

XCODE_CHECK="$(command xcodebuild -version 2>&1)"
echo "$XCODE_CHECK"
foo="requires"

if [[ "$XCODE_CHECK"=~"$foo" ]]; then
	echo "Xcode not found, please see xcodehelp.txt in this repository and install Xcode." | tee -a $LOGFILE
	exit 1;
fi
COMMENT

echo "testing updating url in .gclient"
cat ./.gclient
insert='    "url"         : "https://chromium.googlesource.com/chromium/src.git",'
match='    "url"         : "https://src.chromium.org/svn/trunk/src",'
sed -i "" "s%$match%$insert%" ./.gclient
cat ./.gclient

: <<'COMMENT'
echo "testing line insertion in .gclient"
filetext="$(cat ./.gclient)"
echo "$filetext"
insert="    \"src\/third_party\/WebKit\/LayoutTests\": None,"'\
'"    \"src\/chrome\/tools\/test\/reference_build\/chrome\": None,"'\
'"    \"src\/chrome_frame\/tools\/test\/reference_build\/chrome\": None,"'\
'"    \"src\/chrome\/tools\/test\/reference_build\/chrome_linux\": None,"'\
'"    \"src\/chrome\/tools\/test\/reference_build\/chrome_mac\": None,"'\
'"    \"src\/third_party\/hunspell_dictionaries\": None,"
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

:<<'COMMENT'
echo "testing export"

export FOO="bar"
if [[ $? -eq 0 ]]; then
	echo "$FOO"
else
	echo "failed"
fi

PATH=`pwd`/lalala/hoohah
echo $PATH
COMMENT

: <<'COMMENT'
echo "=========New Build Attempt=========" | tee -a ./logtest.log
echo $(date) | tee -a ./logtest.log
echo "=========New Build Attempt=========" | tee -a ./logtest.log
echo "OS X Version "$OS_VERSION" detected" | tee -a ./logtest.log
echo "more output" | tee -a ./logtest.log

if [[ $(git --version) =~ "2" ]]; then 
	echo "git version 2.x detected"
fi
echo "end"
COMMENT

# testing git version
# sample respnonses: 
#	git version 2.5.4 (Apple Git-61)
#	git version 2.6.4
#	-bash: git: command not found

###
# Based on version checker code cc by-sa 3.0
# Courtesy http://stackoverflow.com/users/1032785/jordanm at http://stackoverflow.com/a/11602790
###

: <<'COMMENT'
for cmd in git; do
	[[ $("$cmd" --version) =~ ([0-9][.][0-9.]*) ]] && version="${BASH_REMATCH[1]}"
	echo "that command returned: "$?
	if ! awk -v ver="$version" 'BEGIN { if (ver < 2.6.5) exit 1; }'; then
		echo 'ERROR: '$cmd' version 2.6.5 or higher required' | tee -a $LOGFILE
	fi
done
COMMENT

:<<'COMMENT'
XCODE_CHECK="$(command xcodebuild 2>&1)"
if [[ "$XCODE_CHECK"=~"error" ]]; then
	echo "Xcode not found, please see xcodehelp.txt in this repository and install Xcode." | tee -a $LOGFILE
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
COMMENT

: <<'COMMENT'
echo "pre"
DEPOT_CHECK="$(command -V gclient 2>&1)"
if [[ DEPOT_CHECK=~"not found" ]]; then
	echo "depot_tools not found, try checking your PATH" | tee -a $LOGFILE
	echo "Alternatively, easychromium can try to install depot_tools for you." | tee -a $LOGFILE
	read -r -p "Install depot_tools? (Y/n) " response
	if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo "trying to install depot_tools"
	else
		echo "no depot_tools found, exiting"
		exit 1;
	fi
else
	echo "found"
fi


if [[ -f "./config.txt" ]]; then 
	echo "./config.txt exists"
else
	echo "does not exist"
fi
COMMENT

: <<'COMMENT'
if ! grep "error" "${XCODE_CHECK}"; then
	echo "xcode found"
else
	echo "not found"
fi
COMMENT

: <<'COMMENT'
if command -v xcodebuild >/dev/null 2>&1; then

	for cmd in xcodebuild; do
		[[ $("$cmd" -version) =~ ([0-9][.][0-9.]*) ]] && version="${BASH_REMATCH[1]}"
		echo "that command returned: "$?
		if ! awk -v ver="$version" 'BEGIN { if (ver < 5.0.0) exit 1; }'; then
			echo 'ERROR: '$cmd' version 5.0.0 or higher required. Please update Xcode.' | tee -a $LOGFILE
			exit 1;
		fi
	done

else 
	echo "ERROR: xcode is not installed. See xcodehelp.txt in easychromium repository." | tee -a $LOGFILE
	exit 1;
fi
COMMENT
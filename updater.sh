#!/bin/bash
# script to be run from crontab to update Chromium install
# tested on OS X El Capitan 10.11.2


# retrieves CSV of current Chromium releases, saves in a file "releases" without extension
curl https://omahaproxy.appspot.com/all -o releases

# returns the version number of the current stable Chromium release for mac, cutting on the comma 
# sample: 48.0.2564.109
TARGET=$(grep mac,stable, releases | cut -d, -f3)
echo "target is: "
echo "$TARGET"

# returns version number of currently installed Chromium
# sample: 50.0.2624.0
CURRENT=$(mdls -name kMDItemVersion /Applications/Chromium.app/ | awk '/kMDItemVersion/{print $NF}' | sed 's/"//g')
echo "current is: "
echo "$CURRENT"

echo "deleting CSV"
rm releases

# probably we'll want to do:
#	cd ./src/
#	gclient sync --no-history --with_tags --verbose --verbose --verbose
#			
#		this command resulted in ~5.4GB of files being pulled down
#
#	git checkout -b new_release tags/$TARGET 
#		see https://www.chromium.org/developers/how-tos/get-the-code/working-with-release-branches
#		RESULT: 
# git checkout -b new_release tags/48.0.2564.109
# Checking out files: 100% (71266/71266), done.
# Previous HEAD position was 26f3c55... CC Animation: Move files from cc_blink to Source/platform/animation
# Branch new_release set up to track remote ref refs/tags/48.0.2564.109.
# Switched to a new branch 'new_release'
#		git show-ref --tags should work after gclient syncing with_tags
#
#	gclient sync --no-history --with_branch_heads --jobs 16 --verbose --verbose --verbose
#	OR
#	just a regular: gclient sync (see https://groups.google.com/a/chromium.org/forum/#!msg/chromium-dev/VTOniO05UDc/nG3F2e67_4sJ)

# now we build?
# probably don't need the second gclient sync after we did the one --with_tags ?
# do we need to do gclient runhooks? see the easychromium.sh file for however we did runhooks there?

#	gclient sync --nohooks --no-history --with_tags --verbose --verbose --verbose
#	git checkout -b new_release tags/$TARGET
#	./build/gyp_chromium -Dfastbuild=1 -Dmac_strip_release=1 -Dbuildtype=Official 
#		got an error: crashpad.gyp not found
#	gclient runhooks 
#		got an error: Updating projects from gyp files...
#		gyp: /Users/bobo/Code/betatest/src/third_party/crashpad/crashpad/crashpad.gyp not found (cwd: /Users/bobo/Code/betatest)
#		Error: Command '/usr/bin/python src/build/gyp_chromium' returned non-zero exit status 1 in /Users/bobo/Code/betatest
#	

# this is what it should look like:
#	gclient sync --nohooks --no-history --with_tags --verbose --verbose --verbose
#	git checkout -b new_release tags/$TARGET
#	gclient sync --no-history --verbose --verbose --verbose
#	./src/build/gyp_chromium -Dfastbuild=1 -Dmac_strip_release=1 -Dbuildtype=Official 
#	gclient runhooks

#	Okay, the above five commands works fine, though i had to interrupt the second gclient sync and run it again

#	okay.....when doing the gclient sync after git checkout i hang on gclient sync, it keeps saying "still working on src"
#	the error after ctrl+c'ing looks like this: Attempting rebase onto origin... - after that line it just hangs, then 
#	shows "interrupted" from when i ctrl+c'd

# after building, copy new build over:
# rsync -ac --delete Chromium.app /Application/Chromium.app
# OR
# /bin/cp Chromium.app /Applications/
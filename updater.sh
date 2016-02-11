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
#		git show-ref --tags should work after gclient syncing with_tags
#
#	gclient sync --no-history --with_branch_heads --jobs 16 --verbose --verbose --verbose
#	OR
#	just a regular: gclient sync (see https://groups.google.com/a/chromium.org/forum/#!msg/chromium-dev/VTOniO05UDc/nG3F2e67_4sJ)

# now we build?

# after building, copy new build over:
# rsync -ac --delete Chromium.app /Application/Chromium.app
# OR
# /bin/cp Chromium.app /Applications/
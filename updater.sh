#!/bin/bash
# script to be run from crontab to update Chromium install
# tested on OS X El Capitan 10.11.2


# retrieves CSV of current Chromium releases, saves in a file "all" without extension
curl -O https://omahaproxy.appspot.com/all

# returns the version number of the current stable Chromium release for mac, cutting on the comma 
# sample: 48.0.2564.109
grep mac,stable, all | cut -d, -f3

# returns version number of currently installed Chromium
# sample: 50.0.2624.0
mdls -name kMDItemVersion /Applications/Chromium.app/ | awk '/kMDItemVersion/{print $NF}' | sed 's/"//g'


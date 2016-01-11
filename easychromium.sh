#!/bin/bash

# run by typing: bash easychromium.sh

# This script installs the latest version of the open source Chromium browser for OS X
# It pulls the code from google and builds it locally on your machine
# Run it in the folder where you want to install chrome
# Suggestion: /Applications/Chromium

# TO DO
# maybe just output everything to stdout and ./easychromium.log
# should append a newline after every write to ./easychromium.log
# search for @#@ as an in-line to do marker thoughout the script

####################
# PRE-BUILD BEGIN
####################

# check OS X version, assign a macro flag to it
	# OSX = MACRO

# pre-build checklist, use git --version etc.:
	# logfile already exists?
		# if yes, append with =====current timestamp==== on a newline, 
			# else, create ./easychromium.log
		# "This version of OS X detected: MACRO" --> ./easychromium.log
	# has git >= 2.2.1?
		# git version --> ./easychromium.log
		# git path --> ./easychromium.log
			# if git not detected, stdout "git not detected, please install xcode-cli: do not "get xcode" just click Okay"
				# xcode-select --install
			# installed xcode-cli using xcode-select --install --> ./easychromium.log
			# git version and git path --> ./easychromium.log

			# else, if git detected
				# which git
					# if /usr/local/bin/git stdout "attempting to update git using homebrew" and --> ./easychromium.log
					# brew update && brew upgrade git
					# else if /usr/bin/git
					# stdout "STOPPING - you need to update xcode to 5+ before proceeding, recommended version is 6.4:  https://developer.apple.com/support/xcode/" and --> ./easychromium.log
	# has xcode-cli?
		# xcode-cli version --> ./easychromium.log
		# xcode-cli path --> ./easychromium.log
			# else, xcode-select --install
			# installed xcode-cli using xcode-select --install --> ./easychromium.log
			# xcode-cli version and path --> ./easychromium.log
	# has xcode? (5+ to 6.4, 7.x seems buggy)
		# xcode version --> ./easychromium.log
		# xcode path (location on disk of xcode.app?) --> ./easychromium.log
			# else, "no xcode install detected, please install xcode 5+, recommended is 6.4 : https://developer.apple.com/support/xcode/" --> ./easychromium.log
	# has depot_tools? (check by trying 'gclient')
		# depot_tools version --> ./easychromium.log
		# depot_tools path --> easychromium.log
			# else, "no depot_tools detected, installing depot_tools" --> ./easychromium.log
			# 

# config file inputs
	# config file exists? (./config.txt) 
		# if no, stdout "no configuration file found, expected ./config.txt \n using defaults, no API's will be loaded" --> ./easychromium.log
		# if yes, output "configuration file found, using ./config.txt" --> ./easychromium.log

####################
# PRE-BUILD COMPLETE
####################


####################
# BUILD SETUP BEGIN
####################

# @#@ should check to see if depot_tools already exists / if needs updating
# download depot_tools, see: http://dev.chromium.org/developers/how-tos/install-depot-tools
echo "Downloading depot_tools from https://chromium.googlesource.com/chromium/tools/depot_tools.git" | tee -a ./easychromium.log
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git



####################
# BUILD SETUP END
####################
#!/bin/bash


export PATH=`pwd`/depot_tools:"$PATH"
cd src
git fetch --tags origin
export GYP_DEFINES="fastbuild=1 mac_strip_release=1 buildtype=Official"
gclient sync --verbose --verbose --verbose --jobs 16
git checkout -b new_release tags/48.0.2564.116
gclient sync --verbose --verbose --verbose --with_branch_heads --jobs 16
git checkout master
gclient sync --verbose --verbose --verbose --jobs 16
git checkout new_release
gclient sync --verbose --verbose --verbose --with_branch_heads --jobs 16
LOGFILE="./logeasychromium.log"
ninja -C out/Release chrome | tee -a $LOGFILE
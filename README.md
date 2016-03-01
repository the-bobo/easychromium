# easychromium
Bash script to build and install Chromium from source on OS X  

Run with 

    `bash easychromium.sh`

Can be run as a cron job for automatic updates  

You need: git 1.9+, XCode 5+, OS X 10.9+, ~15-20GB of space, ~3-5 hours on 16GB RAM, more otherwise

Tested on:  
* OS X El Capitan 10.11.2  
* XCode 7.2  
* git version 2.6.4 (git-scm, not apple git)  
* Python 2.7.10  
* gclient.py 0.7 (from depot_tools)  

Successfully built Chromium Version ~~50.0.2624.0 (64-bit)~~ 48.0.2564.116 (64-bit), the latest stable release for OSX

Pull requests welcome  

![chromium screenshot](https://raw.githubusercontent.com/the-bobo/easychromium/master/Chromium%20Screenshot.jpg)

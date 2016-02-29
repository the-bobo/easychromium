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

#	16th try: based on https://www.chromium.org/developers/how-tos/get-the-code/working-with-release-branches
#	switch to master branch
#	export GYP_DEFINES="fastbuild=1 mac_strip_release=1 buildtype=Official"
#	git fetch --tags
#	git checkout -b gamma_new_release tags/48.0.2564.109
#	../depot_tools/gclient sync --with_branch_heads --jobs 16
#	same error, now trying Primiano's method of rm .git/shallow in each directory where the error appears
#	first directory: /src/buildtools
#	rm ./buildtools/.git/shallow
#	../depot_tools/gclient sync --with_branch_heads --force --reset --jobs 16
#	error:
#		bobo@bobos-MacBook-Pro:~/Code/gammatest/src$ rm ./buildtools/.git/shallow
#		bobo@bobos-MacBook-Pro:~/Code/gammatest/src$ ../depot_tools/gclient sync --with_branch_heads --force --reset --jobs 16
#		Syncing projects:  15% (10/65) src/native_client                               

#		src/buildtools (ERROR)
#		----------------------------------------
#		[0:00:00] Started.
#		----------------------------------------
#		Error: Command 'git rev-list -n 1 HEAD' returned non-zero exit status 128 in /Users/bobo/Code/gammatest/src/buildtools
#		error: Could not read 81863fe70639e85606b541d9d36e9e98c96b957e
#		fatal: Failed to traverse parents of commit 0f8e6e4b126ee88137930a0ae4776c4741808740
#
#	decided to try: git fetch --tags origin (still on branch gamma_new_release)
#	then try this again: ../depot_tools/gclient sync --with_branch_heads --force --reset --jobs 16
#	same error


######################
######################
###################### - newest current version for mac is now: 48.0.2564.116 as of 2/23/2016
######################
######################
######################

#	here's what it should probably be (v24):
#	fetch chromium
#	export PATH=`pwd`/depot_tools:"$PATH"
#	cd src
#	git fetch --tags origin
#	export GYP_DEFINES="fastbuild=1 mac_strip_release=1 buildtype=Official"
#	gclient sync --verbose --verbose --verbose --jobs 16
#	git checkout -b new_release tags/48.0.2564.116
#	gclient sync --verbose --verbose --verbose --with_branch_heads --jobs 16
# **** maybe here we need to git checkout master and then gclient sync in master before git checkout new_release ?
# **** i noticed it updating clang after we tried gclient sync in master once ninja failed (after we gclient sync'd in the tag)
#	LOGFILE="./logeasychromium.log"
#	ninja -C out/Release chrome | tee -a $LOGFILE

#	old try:
#	1) get code
#	2) get tags
#	3) sync
#	4) checkout tag
#	5) sync branch heads
#	6) build x ---- fail

#	new try:
#	1) get code
#	2) get tags
#	3) sync
#	4) checkout tag
#	5) sync branch heads
#	6) checkout master
#	7) sync
#	8) checkout tag 
#	9) build x ---- failed, going to try syncing branch heads first then building again
#	10) after syncing branch heads (on the tag) again and then building, it worked!

#	possible good version (after "new try") - you have to sync both branches twice:
#	fetch chromium
#	export PATH=`pwd`/depot_tools:"$PATH"
#	cd src
#	git fetch --tags origin
#	export GYP_DEFINES="fastbuild=1 mac_strip_release=1 buildtype=Official"
#	gclient sync --verbose --verbose --verbose --jobs 16
#	git checkout -b new_release tags/48.0.2564.116
#	gclient sync --verbose --verbose --verbose --with_branch_heads --jobs 16
#	git checkout master
#	gclient sync --verbose --verbose --verbose --jobs 16
#	git checkout new_release
#	gclient sync --verbose --verbose --verbose --with_branch_heads --jobs 16
#	LOGFILE="./logeasychromium.log"
#	ninja -C out/Release chrome | tee -a $LOGFILE

##################	the script should check to see if ./src exists, if yes then update, else fetch code
##################	the checks for dependencies should happen each time regardless
##################	updating is tricky, because it requires compiling, when should the cron job run?

#	the updater script should just start at "cd src" and go from there, eventually /bin/cp (or rsync)
#		rsync -ac --delete Chromium.app /Application/Chromium.app  (double check this)
#	or:	/bin/cp Chromium.app /Applications/  to put the new Chromium app file to the appropriate place 
#	go ahead and scrub omahaproxy for the correct $TARGET tag to git checkout to
#	also, longterm someone should just release a minisigned binary, this is way too cumbersome for most users



#	23rd try: /hammertest
#	let's gclient sync (no branch heads) the master branch

#	git checkout master
#	echo $GYP_DEFINES
#	gclient sync --jobs 16 --verbose --verbose --verbose
#	git checkout -b 7new_release tags/48.0.2564.116
#	echo $GYP_DEFINES
#	gclient sync --jobs 16 --with_branch_heads --verbose --verbose --verbose
#	echo $LOGFILE
#	ninja -C out/Release chrome | tee -a $LOGFILE
################ IT FINISHED!, now to test the file...



#	22nd try: /hammertest
#	delete the tag 48.0.2564.116 that we named, then git fetch --tags origin again, 
#	then git fetch origin again

#	git branch -d 48.0.2564.116
#	git checkout master
#	git fetch --tags origin
#	git checkout -b 6new_release tags/48.0.2564.116
#	echo $GYP_DEFINES
#	gclient sync --jobs 16 --with_branch_heads --verbose --verbose --verbose
#		same error for crashpad unstaged changes
#	let's try deleting /src/thrid_party/crashpad/
#	rm -rf ./third_party/crashpad/
#	gclient sync --jobs 16 --with_branch_heads --verbose --verbose --verbose
#		output: runs successfully
#	echo $LOGFILE
###	ninja -C out/Release chrome | tee -a $LOGFILE
		# same ##NINJA ERROR## generated


#	21st try: /hammertest
#	we'll do a full gclient sync when we checkout the branch, not a --with_branch_heads
#	git checkout -b 5new_release tags/48.0.2564.116
#	gclient sync --jobs 16 --verbose --verbose --verbose
#		same unstaged changes error


#	20th try: /hammertest
#	we'll try to update our local so that we don't get these unstaged changes error again
#	git checkout master
#	git fetch origin
#	git fetch --tags origin
#	git checkout -b 4new_release tags/48.0.2564.116
#	echo $GYP_DEFINES
#	gclient sync --jobs 16 --with_branch_heads --verbose --verbose --verbose
#		output: same unstaged changes error (crashpad)
#	git status
#		output:
#		On branch 4new_release
#		Your branch is up-to-date with '48.0.2564.116'.
#		Untracked files:
#		(use "git add <file>..." to include in what will be committed)

#		logeasychromium.log
#		third_party/re2/src/
#	git reset --hard HEAD
#	gclient sync --jobs 16 --with_branch_heads --verbose --verbose --verbose
#		same unstaged changes error (/src/thirdparty/crashpad/crashpad)


#	19th try: /hammertest

######################## - Shit, maybe we messed up by checking out 48.0.2564.109 instead of 48.0.2564.116
#							in these past couple builds...

#	git checkout master
#	git checkout -b 3new_release tags/48.0.2564.116
#	echo $GYP_DEFINES
#	gclient sync --jobs 16 --with_branch_heads --verbose --verbose --verbose
#		output: same "unstaged changes" error for crashpad as before






#	18th try: /hammertest
#	we've fetched WITH history and got ALL tags,
#	trying a new checkout of our tag 48.0.2564.109

#	git checkout master
#	echo $GYP_DEFINES
#	git checkout -b 2new_release tags/48.0.2564.109
#	echo $GYP_DEFINES
#	gclient sync --jobs 16 --with_branch_heads --verbose --verbose --verbose
#		same error for unstaged changes:
#		Error: 19> 
#		19> ____ src/third_party/crashpad/crashpad at 97b0f86d0ccb095391ca64b3948f0d6c02975ac1
#		19> 	You have unstaged changes.
#		19> 	Please commit, stash, or reset.
#	gclient sync --jobs 16 --force --reset --with_branch_heads --verbose --verbose --verbose
#	ninja -C out/Release chrome | tee -a $LOGFILE
#		output: ##NINJA ERROR##


#	17th try: /hammertest
#	we'll try fetching WITH history and getting only ONE tag
#	
#	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
#	export PATH=`pwd`/depot_tools:"$PATH"
#	export GYP_DEFINES="fastbuild=1 mac_strip_release=1 buildtype=Official"
#	gclient
#	fetch chromium
#	cd src
#	git fetch origin 48.0.2564.116:48.0.2564.116 --dry-run
#		otherwise try: git fetch --tags origin
#		output of the --dry-run:
#		From https://chromium.googlesource.com/chromium/src
#		* [new tag]         48.0.2564.116 -> 48.0.2564.116
#	git fetch origin 48.0.2564.116:48.0.2564.116
#	git checkout -b new_release tags/48.0.2564.109
#		output was:
#		Checking out files: 100% (75657/75657), done.
#		Previous HEAD position was 80fab8c... Roll src/native_client/ bd5edeb19..902e00158 (3 commits).
#		Branch new_release set up to track remote ref refs/tags/48.0.2564.109.
#		Switched to a new branch 'new_release'
#	echo $GYP_DEFINES
#	git branch 
#		output was:
#		48.0.2564.116
#  		master
#		* new_release
#	gclient sync --jobs 16 --with_branch_heads --verbose --verbose --verbose
#		command executed successfully!!!!
#		one weird warning i saw:
#		WARNING: 'src/third_party/re2/src' is no longer part of this client.  It is recommended that you manually remove it.
#	LOGFILE="./logeasychromium.log"
#	ninja -C out/Release chrome | tee -a $LOGFILE
#		output was:
#		a big error, see below (search for ##NINJA ERROR##)
#	ninja -C out/Release chrome
#		same error ##NINJA ERROR## outputted
#	git checkout master
#	git fetch --tags origin
#		interesting note - should have just done this from the beginning, only saved ~100MB
#		by just doing git fetch origin 48.0.2564.116:48.0.2564.116 instead
#	git checkout new_release
#	echo $GYP_DEFINES
#	echo $LOGFILE
#	gclient sync --jobs 16 --with_branch_heads --verbose --verbose --verbose
#		output was:
#		Error: 19> 
#		19> ____ src/third_party/crashpad/crashpad at 97b0f86d0ccb095391ca64b3948f0d6c02975ac1
#		19> 	You have unstaged changes.
#		19> 	Please commit, stash, or reset.
#	gclient sync --jobs 16 --with_branch_heads --force --reset --verbose --verbose --verbose
#	ninja -C out/Release chrome | tee -a $LOGFILE
#		output was:
#		same error, search ##NINJA ERROR##
#	gclient sync --jobs 16 --verbose --verbose --verbose
###	ninja -C out/Release chrome | tee -a $LOGFILE
#		output was same error, bailing on this attempt



##NINJA ERROR##
4 errors generated.
FAILED: ../../third_party/llvm-build/Release+Asserts/bin/clang++ -MMD -MF obj/third_party/webrtc/base/rtc_base_approved.ratetracker.o.d -DV8_DEPRECATION_WARNINGS -DCLD_VERSION=2 -D__ASSERT_MACROS_DEFINE_VERSIONS_WITHOUT_UNDERSCORE=0 -DCHROMIUM_BUILD -DCR_CLANG_REVISION=247874-1 -DUSE_LIBJPEG_TURBO=1 -DENABLE_ONE_CLICK_SIGNIN -DENABLE_PRE_SYNC_BACKUP -DENABLE_WEBRTC=1 -DENABLE_MEDIA_ROUTER=1 -DENABLE_PEPPER_CDMS -DENABLE_CONFIGURATION_POLICY -DENABLE_NOTIFICATIONS -DENABLE_HIDPI=1 -DFIELDTRIAL_TESTING_ENABLED -DENABLE_TASK_MANAGER=1 -DENABLE_EXTENSIONS=1 -DENABLE_PDF=1 -DENABLE_PLUGIN_INSTALLATION=1 -DENABLE_PLUGINS=1 -DENABLE_SESSION_SERVICE=1 -DENABLE_THEMES=1 -DENABLE_AUTOFILL_DIALOG=1 -DENABLE_PROD_WALLET_SERVICE=1 -DENABLE_BACKGROUND=1 -DENABLE_GOOGLE_NOW=1 -DENABLE_PRINTING=1 -DENABLE_BASIC_PRINTING=1 -DENABLE_PRINT_PREVIEW=1 -DENABLE_SPELLCHECK=1 -DUSE_BROWSER_SPELLCHECKER=1 -DENABLE_CAPTIVE_PORTAL_DETECTION=1 -DENABLE_APP_LIST=1 -DENABLE_SETTINGS_APP=1 -DENABLE_SUPERVISED_USERS=1 -DENABLE_SERVICE_DISCOVERY=1 -DV8_USE_EXTERNAL_STARTUP_DATA -DFULL_SAFE_BROWSING -DSAFE_BROWSING_CSD -DSAFE_BROWSING_DB_LOCAL -DWEBRTC_RESTRICT_LOGGING -DEXPAT_RELATIVE_PATH -DWEBRTC_CHROMIUM_BUILD -DLOGGING_INSIDE_WEBRTC -DWEBRTC_POSIX -DWEBRTC_MAC -DUSE_LIBPCI=1 -DUSE_OPENSSL=1 -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -DNDEBUG -DOFFICIAL_BUILD -DNVALGRIND -DDYNAMIC_ANNOTATIONS_ENABLED=0 -D_FORTIFY_SOURCE=2 -Igen -I../.. -I../../third_party/webrtc_overrides -I../../third_party -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk -O2 -fvisibility=hidden -Werror -Wnewline-eof -mmacosx-version-min=10.6 -arch x86_64 -Wall -Wendif-labels -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Wno-selector-type-mismatch -Wpartial-availability -Wheader-hygiene -Wno-char-subscripts -Wno-unneeded-internal-declaration -Wno-covered-switch-default -Wstring-conversion -Wno-c++11-narrowing -Wno-deprecated-register -Wno-inconsistent-missing-override -Wno-shift-negative-value -Wno-bitfield-width -std=c++11 -stdlib=libc++ -fno-rtti -fno-exceptions -fvisibility-inlines-hidden -fno-threadsafe-statics -Xclang -load -Xclang /Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/lib/libFindBadConstructs.dylib -Xclang -add-plugin -Xclang find-bad-constructs -Xclang -plugin-arg-find-bad-constructs -Xclang check-templates -fcolor-diagnostics -fno-strict-aliasing  -c ../../third_party/webrtc/base/ratetracker.cc -o obj/third_party/webrtc/base/rtc_base_approved.ratetracker.o
In file included from ../../third_party/webrtc/base/ratetracker.cc:17:
In file included from ../../third_party/webrtc/base/checks.h:14:
In file included from /Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/sstream:174:
In file included from /Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/ostream:140:
In file included from /Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/locale:192:
/Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/cstdlib:167:44: error: declaration conflicts with target of using declaration already in scope
inline _LIBCPP_INLINE_VISIBILITY long      abs(     long __x) _NOEXCEPT {return  labs(__x);}
                                           ^
/Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/stdlib.h:115:44: note: target of using declaration
inline _LIBCPP_INLINE_VISIBILITY long      abs(     long __x) _NOEXCEPT {return  labs(__x);}
                                           ^
/Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/cstdlib:135:9: note: using declaration
using ::abs;
        ^
/Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/cstdlib:169:44: error: declaration conflicts with target of using declaration already in scope
inline _LIBCPP_INLINE_VISIBILITY long long abs(long long __x) _NOEXCEPT {return llabs(__x);}
                                           ^
/Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/stdlib.h:117:44: note: target of using declaration
inline _LIBCPP_INLINE_VISIBILITY long long abs(long long __x) _NOEXCEPT {return llabs(__x);}
                                           ^
/Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/cstdlib:135:9: note: using declaration
using ::abs;
        ^
/Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/cstdlib:172:42: error: declaration conflicts with target of using declaration already in scope
inline _LIBCPP_INLINE_VISIBILITY  ldiv_t div(     long __x,      long __y) _NOEXCEPT {return  ldiv(__x, __y);}
                                         ^
/Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/stdlib.h:120:42: note: target of using declaration
inline _LIBCPP_INLINE_VISIBILITY  ldiv_t div(     long __x,      long __y) _NOEXCEPT {return  ldiv(__x, __y);}
                                         ^
/Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/cstdlib:143:9: note: using declaration
using ::div;
        ^
/Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/cstdlib:174:42: error: declaration conflicts with target of using declaration already in scope
inline _LIBCPP_INLINE_VISIBILITY lldiv_t div(long long __x, long long __y) _NOEXCEPT {return lldiv(__x, __y);}
                                         ^
/Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/stdlib.h:122:42: note: target of using declaration
inline _LIBCPP_INLINE_VISIBILITY lldiv_t div(long long __x, long long __y) _NOEXCEPT {return lldiv(__x, __y);}
                                         ^
/Users/bobo/Code/hammertest/src/third_party/llvm-build/Release+Asserts/bin/../include/c++/v1/cstdlib:143:9: note: using declaration
using ::div;
        ^
4 errors generated.
ninja: build stopped: subcommand failed.


#	15.5-th try: /foxtrottest
#	git checkout master -f
#	git fetch --tags origin
#		could i just do a git fetch tag 48.0.2564.109 instead?
#	git checkout -b new_release tags/48.0.2564.109
#	gclient sync --no-history --verbose --verbose --verbose
#	SAME ERROR - CONCLUSION: SHALLOW GIT FETCHES CANNOT BE USED TO BUILD RELEASE TAGS
#	Error: Command 'git checkout --quiet 3ba3ca22ec610fe95683f6bfdeea9d90c768abd7' returned non-zero exit status 128 in /Users/bobo/Code/foxtrottest/src/buildtools
#	fatal: reference is not a tree: 3ba3ca22ec610fe95683f6bfdeea9d90c768abd7




#	15th try: fresh fetch of the source code (/foxtrottest)
#	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
#	export PATH=`pwd`/depot_tools:"$PATH"
#	export GYP_DEFINES="fastbuild=1 mac_strip_release=1 buildtype=Official"
#	gclient
#	fetch --no-history chromium
#	git fetch --tags origin
#	git checkout -b new_release tags/48.0.2564.109
#	gclient sync --no-history --verbose --verbose --verbose

#	IT WORKS - this script ran fine and the gclient sync on the release tag worked fine
#	Updating projects from gyp files...
#	Hook '/usr/bin/python src/build/gyp_chromium' took 73.19 secs
#	bobo@bobos-MacBook-Pro:~/Code/foxtrottest$ echo $?
#	0

#	Now to try building
#	cd src
#	LOGFILE="./logeasychromium.log"
#	ninja -C out/Release chrome | tee -a $LOGFILE

#	it built...but it seemed to build 50.0.2624.0, not 48.0.2564.109, and my branch new_release has disappeared
#	bobo@bobos-MacBook-Pro:~/Code/foxtrottest/src$ git branch
#	* (HEAD detached at origin/master)
#	master
#	I think I forgot to checkout the 48.0.2564.109 tag





#	14th try: using an older checkout of the main src code as our base (/gammatest/)
#	git fetch --tags origin
#		downloaded like 7GB...took forever!
#	export GYP_DEFINES="fastbuild=1 mac_strip_release=1 buildtype=Official"
#	git checkout -b gamma_new_release tags/48.0.2564.109
#	../depot_tools/gclient sync --no-history --verbose --verbose --verbose

#	Same Error!
#	________ running 'git -c core.deltaBaseCacheLimit=2g fetch origin --verbose' in '/Users/bobo/Code/gammatest/src/chrome/tools/test/reference_build/chrome_mac'
# [0:07:23] From https://chromium.googlesource.com/chromium/reference_builds/chrome_mac
# [0:07:23]  = [up to date]      master     -> origin/master
# [0:07:24] Checked out 8dc181329e7c5255f83b4b85dc2f71498a237955 to a detached HEAD. Before making any commits
# in this repo, you should use 'git checkout <branch>' to switch to
# an existing branch or use 'git checkout origin -b <branch>' to
# create a new branch for your work.
# [0:07:24] Finished.
# ----------------------------------------
# gclient_utils(887) flush:No more worker threads or can't queue anything.

# src/buildtools (ERROR)
# ----------------------------------------
# [0:00:00] Started.
# _____ src/buildtools at 3ba3ca22ec610fe95683f6bfdeea9d90c768abd7
# [0:00:03] Fetching origin

# ________ running 'git -c core.deltaBaseCacheLimit=2g fetch origin --verbose' in '/Users/bobo/Code/gammatest/src/buildtools'
# [0:00:05] From https://chromium.googlesource.com/chromium/buildtools
# [0:00:05]  = [up to date]      master     -> origin/master
# ----------------------------------------
# Error: Command 'git checkout --quiet 3ba3ca22ec610fe95683f6bfdeea9d90c768abd7' returned non-zero exit status 128 in /Users/bobo/Code/gammatest/src/buildtools
# fatal: reference is not a tree: 3ba3ca22ec610fe95683f6bfdeea9d90c768abd7

#	13th try: copied .gclient_entries back into /betatest
#	git fetch --tags origin
#		taking a long time, like ~350MB of stuff to download, ton of stuff updated
#	export GYP_DEFINES="fastbuild=1 mac_strip_release=1 buildtype=Official"
#	git checkout -b 12new_release tags/48.0.2564.109
#	gclient sync --no-history --verbose --verbose --verbose
#		same error, fatal: reference is not a tree

#	12th try:
#	git checkout -b 11new_release tags/48.0.2564.109
#	gclient sync 
#		.gclient file in parent directory /Users/bobo/Code/betatest might not be the file you want to use
#		Syncing projects:  18% (12/65) src/testing/gtest                               

#		src/buildtools (ERROR)
#		----------------------------------------
#		[0:00:00] Started.
#		----------------------------------------
#		Error: Command 'git checkout --quiet 3ba3ca22ec610fe95683f6bfdeea9d90c768abd7' returned non-zero exit status 128 in /Users/bobo/Code/betatest/src/buildtools
#		fatal: reference is not a tree: 3ba3ca22ec610fe95683f6bfdeea9d90c768abd7

#	11th try:
#	git fetch --tags origin
#	export GYP_DEFINES="fastbuild=1 mac_strip_release=1 buildtype=Official"
#	git checkout -b 10new_release tags/48.0.2564.109
#	gclient sync --no-history --with_branch_heads --force --reset --verbose --verbose --verbose


#	Tenth try: not going to interrupt the gclient sync
#	git fetch origin
#	export GYP_DEFINES="fastbuild=1 mac_strip_release=1 buildtype=Official"
#	git checkout -b 9new_release tags/48.0.2564.109
#		(echo $GYP_DEFINES shows they still exist)
#	gclient sync --no-history --verbose --verbose --verbose 
#		runs for a while, grabs a bunch of stuff, then it spits out this error:
#		[0:00:00] Started.
#		_____ src/native_client at 546ef11ffcbedf8c33bfa12643408c1182b6839e
#		[0:00:01] Fetching origin

#		________ running 'git -c core.deltaBaseCacheLimit=2g fetch origin --verbose' in '/Users/bobo/Code/betatest/src/native_client'
#		[0:00:02] From https://chromium.googlesource.com/native_client/src/native_client
#		[0:00:02]  = [up to date]      bradnelson/pnacl-in-pnacl -> origin/bradnelson/pnacl-in-pnacl
#		[0:00:02]  = [up to date]      branch_heads/2311 -> origin/branch_heads/2311
#		[0:00:02]  = [up to date]      infra/config -> origin/infra/config
#		[0:00:02]  = [up to date]      master     -> origin/master
#		[0:00:02]  = [up to date]      togit      -> togit
#		----------------------------------------
#		Error: Command 'git checkout --quiet 546ef11ffcbedf8c33bfa12643408c1182b6839e' returned non-zero exit status 128 in /Users/bobo/Code/betatest/src/native_client
#		fatal: reference is not a tree: 546ef11ffcbedf8c33bfa12643408c1182b6839e

#		trying gclient sync two more times gives the same error, though with different hashes:
#		Error: Command 'git checkout --quiet 615a6b0e2b376e3ae946972a52ef897bf6daaff3' returned non-zero exit status 128 in /Users/bobo/Code/betatest/src/breakpad/src
#		fatal: reference is not a tree: 615a6b0e2b376e3ae946972a52ef897bf6daaff3

#		trying gclient sync --no-history --with_branch_heads --verbose --verbose --verbose 
#		gave the same error

#		trying gclient sync --no-history --with_branch_heads --verbose --verbose --verbose --force --reset
#		gave same/similar error:
#		________ running 'git reset --hard HEAD' in '/Users/bobo/Code/betatest/src/breakpad/src'
#		[0:00:02] HEAD is now at 7fef95a Fix usage of deprecated method sendSynchronousRequest:returningResponse:error:.
#		----------------------------------------
#		Error: Command 'git checkout --quiet 615a6b0e2b376e3ae946972a52ef897bf6daaff3' returned non-zero exit status 128 in /Users/bobo/Code/betatest/src/breakpad/src
#		fatal: reference is not a tree: 615a6b0e2b376e3ae946972a52ef897bf6daaff3

#	Ninth try: delete .gclient and .gclient_entries (back them up elsewhere), use the Managed Mode: False (fetch version)
#	of the .gclient file

#	git fetch origin
#	export GYP_DEFINES="fastbuild=1 mac_strip_release=1 buildtype=Official"
#	git checkout -b 8new_release tags/48.0.2564.109
#		(echo $GYP_DEFINES shows they still exist)
#	gclient sync --no-history --verbose --verbose --verbose 
#		Error: client not configured; see 'gclient config' -- (this was before I copied over the fetch version of .gclient)
#	fetch --no-history 
#		this gives an error: 
#		Traceback (most recent call last):
#		File "/Users/bobo/Code/betatest/depot_tools/fetch.py", line 346, in <module>
#	    sys.exit(main())
#	  File "/Users/bobo/Code/betatest/depot_tools/fetch.py", line 339, in main
#	    options, config, props = handle_args(sys.argv)
#	  File "/Users/bobo/Code/betatest/depot_tools/fetch.py", line 279, in handle_args
#	    config = argv[1]
#	IndexError: list index out of range

#	gclient sync --no-history --verbose --verbose --verbose 
#	was working, i interrupted it because i thought it was hanging


#	Eighth try: git fetch origin instead of gclient sync --with_tags
#	git fetch origin
#	export GYP_DEFINES="fastbuild=1 mac_strip_release=1 buildtype=Official"
#	git checkout -b 7new_release tags/48.0.2564.109
#		(echo $GYP_DEFINES shows they still exist)
#	gclient sync --no-history --verbose --verbose --verbose 
#	Same error - the reason is because i have a .gclient file

#	Seventh try: skipping gclient sync inside the target branch
#	gclient sync --nohooks --no-history --with_tags --verbose --verbose --verbose
#	git checkout -b 6new_release tags/48.0.2564.109
#	./build/gyp_chromium -Dfastbuild=1 -Dmac_strip_release=1 -Dbuildtype=Official 
#		Updating projects from gyp files...
#		gyp: /Users/bobo/Code/betatest/src/third_party/crashpad/crashpad/crashpad.gyp not found (cwd: /Users/bobo/Code/betatest/src)
#	gclient sync --no-history --with_tags --verbose --verbose --verbose
#	hangs, same error for Attempting rebase


#	Sixth try: trying a plain gclient sync inside the target branch
#	skipping first gclient sync since switching to master has git saying that i am up to date with origin/master
#	git checkout -b 5new_release tags/48.0.2564.109
#	gclient sync
#	hangs, same error for Attempting rebase


#	Fifth try:
#	skipping first gclient sync since switching to master has git saying that i am up to date with origin/master
#	git checkout -b 4new_release tags/48.0.2564.109
#		trying --nohooks on this sync
#	gclient sync --nohooks --no-history --verbose --verbose --verbose
#	same error as First Error (the extra gclient_utils.Error text comes because I ctrl+c before it says "still working on src")
#	gclient sync --nohooks --no-history --verbose --verbose --verbose
#
#		[0:00:07]  = [up to date]      9.0.600.0  -> 9.0.600.0
#		[0:00:07]  = [up to date]      pre_blink_merge -> pre_blink_merge
#		[0:00:07] Attempting rebase onto origin...
#		----------------------------------------gclient_utils(1034) run:Caught exception in thread src
#
#		gclient_utils(1035) run:(<class 'gclient_utils.Error'>, Error('1> Unrecognized error, please merge or rebase manually.\n1> cd /Users/bobo/Code/betatest/src && git rebase --verbose origin',), <traceback object at 0x102df4248>)
#		gclient_utils(1038) run:_Worker.run(src) done
#		interrupted
#
#	trying the sync again
#	new error:
#
#	[0:00:07]  = [up to date]      pre_blink_merge -> pre_blink_merge
#	[0:00:07] Attempting rebase onto origin...
#	[0:00:08] 
#	[0:00:08] Rebase produced error output:
#	Cannot rebase: You have unstaged changes.
#	Please commit or stash them.
#	----------------------------------------
#	Error: 1> Unrecognized error, please merge or rebase manually.
#	1> cd /Users/bobo/Code/betatest/src && git rebase --verbose origin
#
#	had to git checkout -f master because of "local changes to the following files" (hundreds or thousands of them)


#	Fourth try:
#	trying again from master branch
#	gclient sync --nohooks --no-history --with_tags --verbose --verbose --verbose 
#	git checkout -b 3new_release tags/48.0.2564.109
#	gclient sync --no-history --verbose --verbose --verbose
#	got the same error as First error, but with some more text:
#	[0:00:09]  = [up to date]      pre_blink_merge -> pre_blink_merge
#	[0:00:23] Attempting rebase onto origin...
#	----------------------------------------gclient_utils(1034) run:Caught exception in thread src
#
#	gclient_utils(1035) run:(<class 'gclient_utils.Error'>, Error('1> Unrecognized error, please merge or rebase manually.\n1> cd /Users/bobo/Code/betatest/src && git rebase --verbose origin',), <traceback object at 0x1104a7050>)
#	interrupted
#	gclient_utils(1038) run:_Worker.run(src) done

#	Third try:
#	git checkout -b 2new_release tags/48.0.2564.109
#	gclient sync --no-history --verbose --verbose --verbose
#	get the same error as First error, deleted 2new_release branch

#	Second error:
#	Okay, the above five commands works fine, though i had to interrupt the second gclient sync and run it again
#	So now the thing to test is building it. But when I do git status I get 
#		HEAD detached at origin/master
#	So gonna re-do those five commands (skipping the first one)

#	First error:
#	okay.....when doing the gclient sync after git checkout i hang on gclient sync, it keeps saying "still working on src"
#	the error after ctrl+c'ing looks like this: Attempting rebase onto origin... - after that line it just hangs, then 
#	shows "interrupted" from when i ctrl+c'd

# after building, copy new build over:
# rsync -ac --delete Chromium.app /Application/Chromium.app
# OR
# /bin/cp Chromium.app /Applications/
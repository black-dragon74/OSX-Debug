#!/bin/bash

# Code is poetry

# Script to generate debugging files for a hackintosh
# Written by black.dragon74 as a tribute to the hackintosh community
# EFI Mount script credits to RehabMan @tonymacx86

# Declare variables to be used in this script
scriptVersion=2.9
scriptDir=~/Library/debugNk
dbgURL="https://raw.githubusercontent.com/black-dragon74/OSX-Debug/master/gen_debug.sh"
efiScript=$scriptDir/mount_efi.sh
pledit=/usr/libexec/PlistBuddy
efiScriptURL="https://raw.githubusercontent.com/black-dragon74/OSX-Debug/master/mount_efi.sh"
regExplorer=/Applications/IORegistryExplorer.app
regExplorerURL="https://raw.githubusercontent.com/black-dragon74/OSX-Debug/master/IORegistryExplorer.zip"
patchmaticB=$scriptDir/patchmatic
patchmaticBURL="https://raw.githubusercontent.com/black-dragon74/OSX-Debug/master/patchmatic"
testURL="google.com"
maskedVal="XX-MASKED-XX"
checkForConnAhead=0
randomNumber=$(echo $(( ( RANDOM )  + 12 )))
ioREGName=$(hostname | sed 's/.local//g')
outDir=~/Desktop/$randomNumber
zipFileName=debug_$randomNumber.zip
efiloc="null"
sysPfl=/usr/sbin/system_profiler
hostName=$(hostname | sed 's/.local//g')
genSysDump="no"

# Declare functions to be used in this script.
function printHeader(){
	clear
	echo -e "====================================="
	echo -e "+   macOS DEBUG REPORT GENERATOR    +"
	echo -e "-------------------------------------"
	echo -e "+       SCRIPT VERSION $scriptVersion          +"
	echo -e "====================================="
	echo -e " " && sleep 0.5
	echo -e "====================================="
	echo -e "+      AUTHOR: black.dragon74       +"
	echo -e "====================================="
	echo " " && sleep 0.5
}

function checkConn(){
	if ping -c 1 $testURL &>/dev/null;
		then
		echo "Internet connectivity is all good to go."
	else
		echo "Unable to connect to the internet. Aborted."
		exit
	fi
}

function checkIOREG(){
	if [[ ! -e $outDir/$ioREGName.ioreg ]]; then
		echo "IOREG dump failed. Retrying" && sleep 0.5
		dumpIOREGv2
	else
		echo "IOREG Verified as $outDir/$ioREGName.ioreg"
	fi
}

function dumpIOREGv2(){
	echo "Increased delay x2 for IOREG dump. This will take a while...(33 sec)"
	# Credits black-dragon74
	osascript >/dev/null 2>&1 <<-EOF
		quit application "IORegistryExplorer"
		delay 2

		activate application "IORegistryExplorer"
		delay 8
		tell application "System Events"
			tell process "IORegistryExplorer"
				keystroke "s" using {command down}
				delay 2
				keystroke "g" using {command down, shift down}
				delay 1
				keystroke "$outDir"
				delay 2
				key code 36
				delay 4
				keystroke "$ioREGName"
				delay 2
				key code 36
				delay 6
				keystroke "s" using {command down}
				delay 6
			end tell
		end tell

		quit application "IORegistryExplorer"
	EOF

	# Check for successful dump
	checkIOREG
}

function dumpIOREG(){
	# Credits black-dragon74
	osascript >/dev/null 2>&1 <<-EOF
		quit application "IORegistryExplorer"
		delay 1

		activate application "IORegistryExplorer"
		delay 4
		tell application "System Events"
			tell process "IORegistryExplorer"
				keystroke "s" using {command down}
				delay 1
				keystroke "g" using {command down, shift down}
				delay 0.5
				keystroke "$outDir"
				delay 1
				key code 36
				delay 2
				keystroke "$ioREGName"
				delay 1
				key code 36
				delay 3
				keystroke "s" using {command down}
				delay 3
			end tell
		end tell

		quit application "IORegistryExplorer"
	EOF

	# Check for successful dump
	checkIOREG
}

function dumpKernelLog(){
	bt=$(sysctl -n kern.boottime | sed 's/^.*} //')

	bTm=$(echo "$bt" | awk '{print $2}')
	bTd=$(echo "$bt" | awk '{print $3}')
	bTt=$(echo "$bt" | awk '{print $4}')
	bTy=$(echo "$bt" | awk '{print $5}')

	bTm=$(awk -v "month=$bTm" 'BEGIN {months = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"; print (index(months, month) + 3) / 4}')
	bTm=$(printf %02d $bTm)

    # hardcode system BSD date path to avoid conflict in PATH (i.e. GNU date)
	ep=$(/bin/date -jf '%H:%M:%S' $bTt '+%s')

	cs=$((ep - 60 ))

    # hardcode system BSD date path to avoid conflict in PATH (i.e. GNU date)
	bTt=$(/bin/date -r $cs '+%H:%M:%S')

	stopTime=$(log show --debug --info --start "$bTy-$bTm-$bTd $bTt" | grep loginwindow | head -1)
	stopTime="${stopTime%      *}"

	echo "Extract boot log from $bTy-$bTm-$bTd $bTt"

	log show --debug --info --start "$bTy-$bTm-$bTd $bTt" | grep -E 'kernel:|loginwindow:' | sed -n -e "/kernel: PMAP: PCID enabled/,/$stopTime/ p"
}

function rebuildCaches(){
	# Fix kext list redunancy on some macOS versions
	swver=$(sw_vers -productVersion | sed 's/\.//g' | colrm 5)

	if [[ $swvwe -ge 1011 ]]; then
		sudo kextcache -system-caches #Using system caches tends to help
	else
		sudo touch /System/Library/Extensions && sudo kextcache -u / #Good old method
	fi
}

function dumpKextstat(){

	echo "ACPIPLAT LOG :-"
	kextstat|grep -y acpiplat
	echo "END ACPIPLAT LOG."
	echo -e " "
	echo -e " "


	echo -e "APPLEINTELCPU LOG:-"
	kextstat|grep -y appleintelcpu
	echo -e "END APPLEINTELCPU LOG."
	echo -e " "
	echo -e " "


	echo -e "APPLE LPC LOG:-"
	kextstat|grep -y applelpc
	echo -e "END APPLE LPC LOG."
	echo -e " "
	echo -e " "


	echo -e "APPLE HDA LOG:-"
	kextstat|grep -y applehda
	echo -e "END APPLE HDA LOG."
	echo -e " "
	echo -e " "


	echo -e "LS FOR APPLEHDA :-"
	ls -l /System/Library/Extensions/AppleHDA.kext/Contents/Resources/*.zml*
	echo -e "END LS FOR APPLEHDA."
	echo -e " "
	echo -e " "


	echo -e "ASSERTIONS DUMP :-"
	pmset -g assertions
	echo -e "END DUMP FOR ASSERTIONS."
	echo -e " "
	echo -e " "


	echo -e "DUMP FOR TRIM STATUS :-"
	system_profiler SPSerialATADataType|grep TRIM
	echo -e "END DUMP FOR TRIM STATUS."
	echo -e " "
	echo -e " "
}

# Add function to dump system information, requested by Jake
# Make it optional though as a full system report might take 3+ minutes on slow machines
# If user includes a -sysprofile arg then only generate a system report
function genSystemRep(){
	# Generate report in .spx format so that it is easier to debug.
	# If user wishes so, he can generate a report in txt format.
	# To generate a report in .txt format you can use gen_debug -sysprofile txt
	if [[ ! -z $1 ]]; then
		# Check arg
		if [[ "$1" == "txt" ]]; then
			# Generate report in .txt format
			echo "Generating report in txt format as requested."
			$sysPfl > $outDir/SysDump-$hostName.txt 2>/dev/null
		else
			echo -e "Ignored invalid arg: $1\nGenerating report in spx format."
			# Generate report in spx format
			$sysPfl -xml > $outDir/SysDump-$hostName.spx 2>/dev/null
		fi
	else
		# Generate report in spx format
		$sysPfl -xml > $outDir/SysDump-$hostName.spx 2>/dev/null
	fi
}

function dumpBootLog(){
	if [[ -z $(which bdmesg) ]]; then
		echo "BDMESG not found. Unable to dump boot log."
	else
		bdmesg > $outDir/bootlog.txt 2>/dev/null
	fi
}

function dumpNVRAM(){
	nvram -x -p
}

function updateIfNew(){
	# This function checks if the script's update is available on the remote
	# If yes, it will update automatically

	# If internet connection is fine
	if ping -c 1 $testURL &>/dev/null;
		then
		echo "Hold on for a moment...."
		# Get latest version
		cd $scriptDir
		curl -o ndbg $dbgURL &>/dev/null
		if [[ -e ./ndbg ]]; then
			chmod a+x ./ndbg
			reVer=$(./ndbg -v)
			if [[ "$reVer" != $scriptVersion ]]; then
				echo "Hey! Before we proceed, I found a new version of the script." && sleep 0.5
				echo "You are running $scriptVersion and new version is $reVer" && sleep 0.5
				read -p "Shall I update it now?[y/n]: " updAns
				case $updAns in
					[yY]* )
						# Update
						sudo cp -f ./ndbg $(which gen_debug)
						sudo chmod a+x $(which gen_debug)
						rm ./ndbg &>/dev/null
						echo "Great! Now re run the program..."
						exit
						;;
					* )
						# Don't update
						echo "It is recommended to have the latest version. Still, you rule."
						echo "Proceeding......"
						echo
				esac
			fi
		fi
	fi
}

if [[ $1 = "-v" ]]; then
	echo $scriptVersion
	exit
fi

# Welcome, Here wo go!
printHeader

# Update if new version is found on the remote
if [[ $1 != "-u"* ]]; then
	updateIfNew
fi

# Check for custom args
arg="$1"
if [[ ! -z $arg ]]; then
	case $arg in
		[-][uU]* )
			echo "Updating your copy of OSX-Debug"
			checkConn
			cd $(echo $HOME)
			if [[ -e ./tdbg ]]; then
				rm -rf ./tdbg
			fi
			curl -o tdbg $dbgURL &>/dev/null
			if [[ ! -e ./tdbg ]]; then
				echo "Download failed. Try again."
				exit
			fi
			echo "Installing...."
			sudo cp -f ./tdbg $(which gen_debug)
			sudo chmod a+x $(which gen_debug)
			rm ./tdbg &>/dev/null
			exit
			;;
		"-sysprofile" )
			# Set genSysDump to yes
			genSysDump="yes"
			echo "System report will be included in the dump as requested."
			;;	
			* )
			echo "Invalid args. Exit."
			exit
			;;	
	esac
fi

# Check if script directory exists else create it
if [ -d $scriptDir ];
	then
	echo -e "Found script data directory at $scriptDir"
else
	echo -e "Script data directory not present, creating it."
	mkdir -p $scriptDir
fi

# Check for mount EFI script
if [ -e $efiScript ];
	then
	echo -e "EFI Mount Script (RehabMan) found. No need to download."
	checkForConnAhead=1
else
	echo -e "EFI Mount Script (RehabMan) not found. Need to fetch it."
	echo -e "Checking connectivity.."
	checkConn # If no connection found, script will terminate here.

	# Stuffs to do in case internet connectivity is fine
	echo -e "Downloading EFI Mount script"
	curl -o $efiScript $efiScriptURL &>/dev/null

	# Check if the script is actually there
	if [ -e $efiScript ];
		then
		echo -e "Script downloaded. Verifying."
		if [[ $(echo $(md5 $efiScript) | sed 's/.*= //g') = 9e104d2f7d1b0e70e36dffd8031de2c8 ]];
			then
			echo -e "Script is verified."
			echo -e "Setting permissions."
			chmod a+x $efiScript
		else
			echo -e "Corrupted file is downloaded. Try again."
			rm $efiScript
			exit
		fi
	else
		echo -e "Download failed due to some reasons. Try again."
		exit
	fi
fi

# Check for IORegistryExplorer
if [ -e $regExplorer ];
	then
	echo -e "IORegistryExplorer found at $regExplorer"
	echo "Verifying if the version is 2.1"
	if [[  "$($pledit -c "Print CFBundleVersion" $regExplorer/Contents/Info.plist)" = "2.1" ]]; then
		echo "Verified version 2.1"
		checkForConnAhead=1
	else
		echo "This version of IORegistryExplorer is not recommended."
		echo "Removing conflicting version."
		rm -rf $regExplorer &>/dev/null

		# In some cases maybe sudo is required to remove this application
		if [[ -e $regExplorer ]]; then
			sudo rm -rf $regExplorer &>/dev/null
		fi

		# Check connection only if required
		if [ $checkForConnAhead -eq 1 ];
			then
			echo -e "Checking connectivity.."
			checkConn # If no connection found, script will terminate here.
		fi

		# Stuffs to do in case internet connectivity is fine
		echo -e "Downloading IORegistryExplorer."
		curl -o $scriptDir/IORegistryExplorer.zip $regExplorerURL &>/dev/null

		# Check if the downloaded file exists
		if [ -e $scriptDir/IORegistryExplorer.zip ];
			then
			echo -e "Downloaded IORegistryExplorer."
			echo -e "Verifying Downloaded file."
			if [[ $(echo $(md5 $scriptDir/IORegistryExplorer.zip) | sed 's/.*= //g') = 494a39316ed52c0c73438a4755c4732a ]];
				then
				echo -e "File Verified. Installing."
				unzip -o $scriptDir/IORegistryExplorer.zip -d /Applications/ &>/dev/null
				echo -e "Installed IORegistryExplorer at $regExplorer"
				rm -f $scriptDir/IORegistryExplorer.zip
				rm -rf /Applications/__MACOSX &>/dev/null
			else
				echo -e "Maybe a corrupted file is downloaded. Try again."
				rm -f $scriptDir/IORegistryExplorer.zip
				exit
			fi
		else
			echo -e "Download of IORegistryExplorer failed. Try again."
			exit
		fi
	fi
else
	echo -e "IORegistryExplorer not found at $regExplorer"
	# Check connection only if required
	if [ $checkForConnAhead -eq 1 ];
		then
		echo -e "Checking connectivity.."
		checkConn # If no connection found, script will terminate here.
	fi

	# Stuffs to do in case internet connectivity is fine
	echo -e "Downloading IORegistryExplorer."
	curl -o $scriptDir/IORegistryExplorer.zip $regExplorerURL &>/dev/null

	# Check if the downloaded file exists
	if [ -e $scriptDir/IORegistryExplorer.zip ];
		then
		echo -e "Downloaded IORegistryExplorer."
		echo -e "Verifying Downloaded file."
		if [[ $(echo $(md5 $scriptDir/IORegistryExplorer.zip) | sed 's/.*= //g') = 494a39316ed52c0c73438a4755c4732a ]];
			then
			echo -e "File Verified. Installing."
			unzip -o $scriptDir/IORegistryExplorer.zip -d /Applications/ &>/dev/null
			echo -e "Installed IORegistryExplorer at $regExplorer"
			rm -f $scriptDir/IORegistryExplorer.zip
			rm -rf /Applications/__MACOSX &>/dev/null
		else
			echo -e "Maybe a corrupted file is downloaded. Try again."
			rm -f $scriptDir/IORegistryExplorer.zip
			exit
		fi
	else
		echo -e "Download of IORegistryExplorer failed. Try again."
		exit
	fi

fi

# Check for patchmatic
if [[ $(which patchmatic) = "" ]];
	then 
	echo -e "Patchmatic not installed. Checking in DATA directory."
	if [ ! -e $patchmaticB ]; 
		then
		echo -e "Patchmatic not found in data directory."
		if [ $checkForConnAhead -eq 1 ];
			then
			checkConn &>/dev/null # If no connection found, script will terminate here.
		fi

		# Stuffs to do in case internet connectivity is fine
		echo -e "Downloading Patchmatic."
		curl -o $patchmaticB $patchmaticBURL &>/dev/null

		# Check integrity of downloaded file.
		if [ -e $patchmaticB ];
			then
			echo -e "Downloaded Patchmatic."
			echo -e "Verifying downloaded file."
			if [[ $(echo $(md5 $patchmaticB) | sed 's/.*= //g') = a295cf066a74191a36395bbec4b5d4a4 ]];
				then
				echo -e "File verified."
				echo -e "It resides at $patchmaticB"
			else
				echo -e "Verification failed. Try again."
				rm -f $patchmaticB
				exit
			fi	
		fi
	else
		echo -e "Binary found in DATA directory."
		checkForConnAhead=1
	fi
else 
	echo -e "Found patchmatic at $(which patchmatic)"
	patchmaticB=$(which patchmatic)
	checkForConnAhead=1
fi

# Start dumping the data, start by creating dirs
if [ -e $outDir ];
	then
	rm -rf $outDir
else
	mkdir -p $outDir
fi

# Change active directory to $outDir
cd $outDir
echo -e "Data will be dumped at $outDir"

# Request root access
sudo xyz &>/dev/null

# Add an empty file denoting gen_debug version
touch gdb-$scriptVersion

# Extract loaded tables using patchmatic
echo -e "Dumping loaded ACPI tables."
mkdir patchmatic_extraction
cd ./patchmatic_extraction
sudo chmod a+x $patchmaticB
$patchmaticB -extract
cd ..
echo -e "Dumped loaded ACPI tables."

# Dumping system logs
echo -e "Dumping System log."
cp /var/log/system.log .

# Dumping kernel log
echo -e "Dumping kernel log."
dumpKernelLog &> kernel_log.txt

# Dumping kextstat
echo -e "Dumping kextstat."
touch kextstat_log.txt
dumpKextstat &>kextstat_log.txt

# Dump kextcache
echo -e "Dumping kextcache"
touch kextcache_log.txt
rebuildCaches &>kextcache_log.txt

# Dump clover files
echo -e "Dumping clover files."
efiloc=$(sudo $efiScript)
echo -e "Mounted EFI at $efiloc (credits RehabMan)"
cp -prf $efiloc/EFI/CLOVER .
echo -e "Removing theme dir."
cd ./CLOVER && rm -rf them* &>/dev/null
echo -e "Removing tools dir."
rm -rf too* &>/dev/null
echo -e "Masking your System IDs"
$pledit -c "Set SMBIOS:SerialNumber $maskedVal" config.plist
$pledit -c "Set SMBIOS:BoardSerialNumber $maskedVal" config.plist 
$pledit -c "Set SMBIOS:SmUUID $maskedVal" config.plist 
$pledit -c "Set RtVariables:ROM $maskedVal" config.plist 
cd ..
echo -e "Dumped CLOVER files."
echo -e "Unmounted $efiloc"
diskutil unmount $efiloc &>/dev/null

# Dump IOREG
echo -e "Dumping IOREG."
dumpIOREG

# Dump System Profile if user has asked so
if [[ "$genSysDump" == "yes" ]]; then
	echo "Generating system info, this may take a while."
	genSystemRep $2
else
	echo -e "System dump not requested.\nYou may use gen_debug -sysprofile to generate system dump."
	echo -e "For output in TXT format use: \"gen_debug -sysprofile txt\". Default format is SPX"
fi

# Dump boot log
echo "Dumping Boot log"
dumpBootLog

# Dump NVRAM
echo "Dumping NVRAM values..."
dumpNVRAM > nvram.plist

# Zip all the files
echo -e "Zipping all the files"
zip -r $zipFileName * &>/dev/null
echo -e "Zipped files at: $outDir/debug_$randomNumber.zip"

# Remove unzipped files
shopt -s extglob
rm -rf -- !(debug_*)

# Ask to open the out directory.
read -p "Dump complete. Open $outDir?(Yy/Nn) " readOut
case $readOut in
	[yY]|[yY][eE][sS] )
		open $outDir
		;;
	[nN]|[nN][oO] )
		echo -e "Okay. You can open it manually."
		;;	
	* )
		echo -e "Invalid option selected. Open manually."
		;;	
esac

# Say Thank You!
echo -e "Thank You! Hope your problem gets sorted out soon."
exit


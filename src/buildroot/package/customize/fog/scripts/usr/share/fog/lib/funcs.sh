#!/bin/sh

REG_LOCAL_MACHINE_XP="/ntfs/WINDOWS/system32/config/system"
REG_LOCAL_MACHINE_7="/ntfs/Windows/System32/config/SYSTEM"
REG_HOSTNAME_KEY1_XP="\ControlSet001\Services\Tcpip\Parameters\NV Hostname"
REG_HOSTNAME_KEY2_XP="\ControlSet001\Control\ComputerName\ComputerName\ComputerName"
REG_HOSTNAME_KEY1_7="\ControlSet001\services\Tcpip\Parameters\NV Hostname"
REG_HOSTNAME_KEY2_7="\ControlSet001\Control\ComputerName\ComputerName\ComputerName"
REG_HOSTNAME_MOUNTED_DEVICES_7="\MountedDevices"

#If a sub shell gets involked and we lose kernel vars this will reimport them
$(for var in $(cat /proc/cmdline); do echo export $var | grep =; done)

setupDNS()
{
	echo "nameserver $1" > /etc/resolv.conf
}

changeHostname()
{
	echo -n " * Changing hostname...........................";
	if [ -n "$hostname" ]
	then
		mkdir /ntfs &>/dev/null
		regfile="";
		key1="";
		key2="";
		if [ "$osid" = "5" ]
		then
			ntfs-3g -o force,rw $win7sys /ntfs
			regfile=$REG_LOCAL_MACHINE_7
			key1=$REG_HOSTNAME_KEY1_7
			key2=$REG_HOSTNAME_KEY2_7
		elif [ "$osid" = "1" ]
		then
			ntfs-3g -o force,rw $part /ntfs
			regfile=$REG_LOCAL_MACHINE_XP
			key1=$REG_HOSTNAME_KEY1_XP
			key2=$REG_HOSTNAME_KEY2_XP
		fi
		reged -e "$regfile" &>/dev/null  <<EOFREG 
ed $key1
$hostname
ed $key2
$hostname
q
y
EOFREG
		umount /ntfs
		echo "Done";
	else
		echo "Skipped";
	fi
}

clearMountedDevices()
{
	

	mkdir /ntfs &>/dev/null

	if [ "$osid" = "5" ]
	then
		echo -n " * Clearing mounted devices....................";
		ntfs-3g -o force,rw $win7sys /ntfs
		reged -e "$REG_LOCAL_MACHINE_7" &>/dev/null  <<EOFMOUNT
cd $REG_HOSTNAME_MOUNTED_DEVICES_7
delallv
q
y
EOFMOUNT
		echo "Done";		
		umount /ntfs
	fi
}

doInventory()
{
	sysman=`dmidecode -s system-manufacturer`;
	sysproduct=`dmidecode -s system-product-name`;
	sysversion=`dmidecode -s system-version`;
	sysserial=`dmidecode -s system-serial-number`;
	systype=`dmidecode -t 3 | grep Type:`;
	biosversion=`dmidecode -s bios-version`;
	biosvendor=`dmidecode -s bios-vendor`;
	biosdate=`dmidecode -s bios-release-date`;
	mbman=`dmidecode -s baseboard-manufacturer`;
	mbproductname=`dmidecode -s baseboard-product-name`;
	mbversion=`dmidecode -s baseboard-version`;
	mbserial=`dmidecode -s baseboard-serial-number`;
	mbasset=`dmidecode -s baseboard-asset-tag`;
	cpuman=`dmidecode -s processor-manufacturer`;
	cpuversion=`dmidecode -s processor-version`;
	cpucurrent=`dmidecode -t 4 | grep 'Current Speed:' | head -n1`;
	cpumax=`dmidecode -t 4 | grep 'Max Speed:' | head -n1`;
	mem=`cat /proc/meminfo | grep MemTotal`;
	hdinfo=`hdparm -i $hd | grep Model=`;
	caseman=`dmidecode -s chassis-manufacturer`;
	casever=`dmidecode -s chassis-version`;
	caseserial=`dmidecode -s chassis-serial-number`;
	casesasset=`dmidecode -s chassis-asset-tag`;
	
	sysman64=`echo $sysman | base64`;
	sysproduct64=`echo $sysproduct | base64`;
	sysversion64=`echo $sysversion | base64`;
	sysserial64=`echo $sysserial | base64`;
	systype64=`echo $systype | base64`;
	biosversion64=`echo $biosversion | base64`;
	biosvendor64=`echo $biosvendor | base64`;
	biosdate64=`echo $biosdate | base64`;
	mbman64=`echo $mbman | base64`;
	mbproductname64=`echo $mbproductname | base64`;
	mbversion64=`echo $mbversion | base64`;
	mbserial64=`echo $mbserial | base64`;
	mbasset64=`echo $mbasset | base64`;
	cpuman64=`echo $cpuman | base64`;
	cpuversion64=`echo $cpuversion | base64`;
	cpucurrent64=`echo $cpucurrent | base64`;
	cpumax64=`echo $cpumax | base64`;
	mem64=`echo $mem | base64`;
	hdinfo64=`echo $hdinfo | base64`;
	caseman64=`echo $caseman | base64`;
	casever64=`echo $casever | base64`;
	caseserial64=`echo $caseserial | base64`;
	casesasset64=`echo $casesasset | base64`;	
}

determineOS()
{
	if [ -n "$1" ]; then
		if [ "$1" = "1" ]; then
			osname="Windows XP";
			mbrfile="/usr/share/fog/mbr/xp.mbr";
		elif [ "$1" = "2" ]; then
			osname="Windows Vista";
			mbrfile="/usr/share/fog/mbr/vista.mbr";
		elif [ "$1" = "3" ]; then
			osname="Windows 98";
			mbrfile="";
		elif [ "$1" = "4" ]; then
			osname="Windows (Other)";
			mbrfile="";	
		elif [ "$1" = "5" ]; then
			osname="Windows 7";
			mbrfile="/usr/share/fog/mbr/win7.mbr";				
		elif [ "$1" = "50" ]; then
			osname="Linux";
			mbrfile="";								
		elif [ "$1" = "99" ]; then
			osname="Other OS";
			mbrfile="";			
		else
			handleError " * Invalid operating system id ($1)!";
		fi
	else
		handleError " * Unable to determine operating system type!";
	fi
}

clearScreen()
{
	for i in $(seq 0 99);
	do
		echo "";
	done
}

sec2String()
{
	if [ $1 -gt 60 ]
	then
		if [ $1 -gt 3600 ]
		then
			if [ $1 -gt 216000 ]
			then
				val=$(expr $1 "/" 216000)
				echo -n "$val days";
			else
				val=$(expr $1 "/" 3600)
				echo -n "$val hours";
			fi
		else
			val=$(expr $1 "/" 60)
			echo -n "$val min";
		fi
	else
		echo -n "$1 sec";
	fi
}

getSAMLoc()
{
	poss="/ntfs/WINDOWS/system32/config/SAM /ntfs/Windows/System32/config/SAM";
	for pth in $poss;
	do
		if [ -f $pth ]; then
			sam=$pth;
			return 0;
		fi
	done
	return 0;
}

getHardDisk()
{
#echo "-----${fdrive}";
	if [ -n "${fdrive}" ]
	then
		hd="${fdrive}";
		return 0;
	else
		hd="";
	
		for i in `fogpartinfo --list-devices 2>/dev/null`
		do
			hd="$i";
			return 0;
		done;
	
		# Lets check and see if the partition shows up in /proc/partitions		
		for i in hda hdb hdc hdd hde hdf sda sdb sdc sdd sde sdf;
		do		
			strData=`cat /proc/partitions | grep $i 2>/dev/null`
			if [ -n "$strData" ]
			then
				hd="/dev/$i"
				return 0;
			fi 
		done;		
		
		for i in hda hdb hdc hdd hde hdf sda sdb sdc sdd sde sdf;
		do		
			strData=`head -1 /dev/$i 2>/dev/null`
			if [ -n "$strData" ]
			then
				hd="/dev/$i"
				return 0;
			fi 
		done;	
	
		# Failed, probably because there is no partition on the device
		for i in hda hdb hdc hdd hde hdf sda sdb sdc sdd sde sdf;
		do		
			strData=`fdisk -l | grep /dev/$i 2>/dev/null`
			if [ -n "$strData" ]
			then
				hd="/dev/$i"
				return 0;
			fi 
		done;	
	fi
	return 1;
}

correctVistaMBR()
{
	echo -n " * Correcting Vista MBR........................";
	dd if=$1 of=/tmp.mbr count=1 bs=512 &>/dev/null
	xxd /tmp.mbr /tmp.mbr.txt &>/dev/null
	rm /tmp.mbr &>/dev/null
	fogmbrfix /tmp.mbr.txt /tmp.mbr.fix.txt &>/dev/null
	rm /tmp.mbr.txt &>/dev/null
	xxd -r /tmp.mbr.fix.txt /mbr.mbr &>/dev/null
	rm /tmp.mbr.fix.txt &>/dev/null
	dd if=/mbr.mbr of=$1 count=1 bs=512 &>/dev/null
	echo "Done";
}

displayBanner()
{
	echo "  +--------------------------------------------------------------------------+";
	echo "  |                                                                          |";
	echo "  |                       ..#######:.    ..,#,..     .::##::.                | ";
	echo "  |                  .:######          .:;####:......;#;..                   |";
	echo "  |                  ...##...        ...##;,;##::::.##...                    |";
	echo "  |                     ,#          ...##.....##:::##     ..::               |";
	echo "  |                     ##    .::###,,##.   . ##.::#.:######::.              |";
	echo "  |                  ...##:::###::....#. ..  .#...#. #...#:::.               |";
	echo "  |                  ..:####:..    ..##......##::##  ..  #                   |";
	echo "  |                      #  .      ...##:,;##;:::#: ... ##..                 |";
	echo "  |                     .#  .       .:;####;::::.##:::;#:..                  |";
	echo "  |                      #                     ..:;###..                     |";
	echo "  |                                                                          |";
	echo "  |                       Free Computer Imaging Solution                     |";
	echo "  |                               Version 0.32                               |";
	echo "  |                                                                          |";
	echo "  +--------------------------------------------------------------------------+";
	echo "  | Created by:                                                              |";
	echo "  |              Chuck Syperski                                              |";
	echo "  |              Jian Zhang                                                  |";
	echo "  |                                                                          |";
	echo "  | Released under GPL Version 3                                             |";
	echo "  +--------------------------------------------------------------------------+";
	echo "";
	echo "";
}

handleError()
{
        echo "";
	echo " #############################################################################";
	echo " #                                                                           #";	
	echo " #                     An error has been detected!                           #";
	echo " #                                                                           #";	
	echo " #############################################################################";
	sleep 3;
	echo "";
	echo "";
	echo -e " $1";
	echo "";
	echo "";
	echo " #############################################################################";
	echo " #                                                                           #";	
	echo " #                  Computer will reboot in 1 minute.                        #";
	echo " #                                                                           #";	
	echo " #############################################################################";	
	sleep 60;
	exit 0;
}

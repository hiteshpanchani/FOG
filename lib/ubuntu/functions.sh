#
#  FOG is a computer imaging solution.
#  Copyright (C) 2007  Chuck Syperski & Jian Zhang
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#    any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
#

installInitScript()
{
	echo -n "  * Installing init scripts";
	${initdpath}/${initdMCfullname} stop >/dev/null 2>&1;
	${initdpath}/${initdIRfullname} stop >/dev/null 2>&1;
	${initdpath}/${initdSDfullname} stop >/dev/null 2>&1;
	
	cp -f ${initdsrc}/* ${initdpath}/
	chmod 755 ${initdpath}/${initdMCfullname}
	sysv-rc-conf ${initdMCfullname} on >/dev/null 2>&1;
	chmod 755 ${initdpath}/${initdIRfullname}
	sysv-rc-conf ${initdIRfullname} on >/dev/null 2>&1;		
	chmod 755 ${initdpath}/${initdSDfullname}
	sysv-rc-conf ${initdSDfullname} on >/dev/null 2>&1;	
	echo "...OK";	
}

configureFOGService()
{
	echo "<?php
define( \"UPDSENDERPATH\", \"/usr/local/sbin/udp-sender\" );
define( \"MULTICASTLOGPATH\", \"/opt/fog/log/multicast.log\" );
define( \"MULTICASTDEVICEOUTPUT\", \"/dev/tty2\" );
define( \"MULTICASTSLEEPTIME\", 10 );
define( \"MULTICASTINTERFACE\", \"${interface}\" );
define( \"UDPSENDER_MAXWAIT\", null );

define( \"MYSQL_HOST\", \"${snmysqlhost}\" );
define( \"MYSQL_DATABASE\", \"fog\" );
define( \"MYSQL_USERNAME\", \"${snmysqluser}\" );
define( \"MYSQL_PASSWORD\", \"${snmysqlpass}\" );

define( \"LOGMAXSIZE\", \"1000000\" );

define( \"REPLICATORLOGPATH\", \"/opt/fog/log/fogreplicator.log\" );
define( \"REPLICATORDEVICEOUTPUT\", \"/dev/tty3\" );
define( \"REPLICATORSLEEPTIME\", 600 );
define( \"REPLICATORIFCONFIG\", \"/sbin/ifconfig\" );

define( \"SCHEDULERLOGPATH\", \"/opt/fog/log/fogscheduler.log\" );
define( \"SCHEDULERDEVICEOUTPUT\", \"/dev/tty4\" );
define( \"SCHEDULERWEBROOT\", \"${webdirdest}\" );
define( \"SCHEDULERSLEEPTIME\", 60 );
?>" > ${servicedst}/etc/config.php;


	echo -n "  * Starting FOG Multicast Management Server"; 
	${initdpath}/${initdMCfullname} stop >/dev/null 2>&1;
	${initdpath}/${initdMCfullname} start >/dev/null 2>&1;
	if [ "$?" != "0" ]
	then
		echo "...Failed!";
		exit 1;	
	else
		echo "...OK";
	fi	
	
	echo -n "  * Starting FOG Image Replicator Server"; 
	${initdpath}/${initdIRfullname} stop >/dev/null 2>&1;
	${initdpath}/${initdIRfullname} start >/dev/null 2>&1;
	if [ "$?" != "0" ]
	then
		echo "...Failed!";
		exit 1;	
	else
		echo "...OK";
	fi	
	
	echo -n "  * Starting FOG Task Scheduler Server"; 
	${initdpath}/${initdSDfullname} stop >/dev/null 2>&1;
	${initdpath}/${initdSDfullname} start >/dev/null 2>&1;
	if [ "$?" != "0" ]
	then
		echo "...Failed!";
		exit 1;	
	else
		echo "...OK";
	fi
}

configureNFS()
{
	echo -n "  * Setting up and starting NFS Server"; 
	
	echo "/images                        *(ro,sync,no_wdelay,insecure_locks,no_root_squash,insecure)
/images/dev                    *(rw,sync,no_wdelay,no_root_squash,insecure)" > "${nfsconfig}";
	
	sysv-rc-conf nfs-kernel-server on >/dev/null 2>&1;
	/etc/init.d/nfs-kernel-server stop >/dev/null 2>&1;
	/etc/init.d/nfs-kernel-server start >/dev/null 2>&1;
	if [ "$?" != "0" ]
	then
		echo "...Failed!";
		exit 1;	
	else
		echo "...OK";
	fi		
}

configureFTP()
{
	echo -n "  * Setting up and starting VSFTP Server";
	if [ -f "$ftpconfig" ]
	then
		mv "${ftpconfig}" "${ftpconfig}.fogbackup";
	fi
	
	echo "anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=YES
pam_service_name=vsftpd
userlist_enable=NO
tcp_wrappers=YES" > "$ftpconfig";

	sysv-rc-conf vsftpd on >/dev/null 2>&1;
	/etc/init.d/vsftpd stop >/dev/null 2>&1;
	/etc/init.d/vsftpd start >/dev/null 2>&1;
	if [ "$?" != "0" ] 
	then
		echo "...Failed!";
		exit 1;	
	else
		echo "...OK";
	fi	

}

configureTFTPandPXE()
{
	echo -n "  * Setting up and starting TFTP and PXE Servers";
	if [ -d "$tftpdirdst" ]
	then
		rm -rf "${tftpdirdst}.fogbackup" 2>/dev/null;
		cp -Rf "$tftpdirdst" "${tftpdirdst}.fogbackup" >/dev/null 2>&1;
		#if [ -d "$tftpdirdst" ]
		#then
		#	echo "...Failed!";
		#	echo "  * Failed to move $tftpdirdst to ${tftpdirdst}.fogbackup";
		#	echo "  * Make sure ${tftpdirdst}.fogbackup does NOT exists.";		
		#	echo "  * If ${tftpdirdst}.fogbackup does exist delete or rename ";	
		#	echo "    it and start over and everything should work.";
		#	exit 1;
		#fi
	fi
	
	mkdir -p "$tftpdirdst" >/dev/null 2>&1;
	cp -Rf ${tftpdirsrc}/* ${tftpdirdst}/
	
	chown -R ${username} "${tftpdirdst}";
	find "${tftpdirdst}" -type d -exec chmod 755 {} \;
	find "${tftpdirdst}" ! -type d -exec chmod 644 {} \;

	echo "DEFAULT vesamenu.c32
MENU TITLE FOG Computer Cloning Solution
MENU BACKGROUND fog/bg.png
MENU MASTER PASSWD \$1\$0123456789
\n
menu color title	1;36;44    #ffffffff #00000000 std
\n
LABEL fog.local
	localboot 0
	MENU DEFAULT
	MENU LABEL Boot from hard disk
	TEXT HELP
	Boot from the local hard drive.  
	If you are unsure, select this option.
	ENDTEXT
\n
LABEL fog.memtest
	kernel fog/memtest/memtest
	MENU LABEL Run Memtest86+
	TEXT HELP
	Run Memtest86+ on the client computer.
	ENDTEXT
\n
LABEL fog.reg
	kernel fog/kernel/bzImage
	append initrd=fog/images/init.gz root=/dev/ram0 rw ramdisk_size=127000 ip=dhcp dns=${dnsbootimage} mode=autoreg web=${ipaddress}/fog/ loglevel=4
	MENU LABEL Quick Host Registration and Inventory
	TEXT HELP
	Automatically register the client computer,
	and perform a hardware inventory.
	ENDTEXT
\n
LABEL fog.reginput
	kernel fog/kernel/bzImage
	append initrd=fog/images/init.gz root=/dev/ram0 rw ramdisk_size=127000 ip=dhcp dns=${dnsbootimage} mode=manreg web=${ipaddress}/fog/ loglevel=4
	MENU LABEL Perform Full Host Registration and Inventory
	TEXT HELP
	Perform a full host registration on the client
	computer, perform a hardware inventory, and 
	optionally image the host.
	ENDTEXT
\n
LABEL fog.quickimage
	MENU PASSWD \$1\$0123456789
	kernel fog/kernel/bzImage
	append initrd=fog/images/init.gz  root=/dev/ram0 rw ramdisk_size=127000 ip=dhcp dns=${dnsbootimage} mode=quickimage keymap= web=${ipaddress}/fog/ loglevel=4
	MENU LABEL Quick Image
	TEXT HELP
	This mode will allow you to image this host quickly with
	it's default assigned image.
	ENDTEXT		
\n
LABEL fog.sysinfo
	kernel fog/kernel/bzImage
	append initrd=fog/images/init.gz  root=/dev/ram0 rw ramdisk_size=127000 ip=dhcp dns=${dnsbootimage} mode=sysinfo loglevel=4
	MENU LABEL Client System Information
	TEXT HELP
	View basic client information such as MAC address 
	and FOG compatibility.
	ENDTEXT	

LABEL fog.debug
	MENU PASSWD \$1\$0123456789
	kernel fog/kernel/bzImage
	append initrd=fog/images/init.gz  root=/dev/ram0 rw ramdisk_size=127000 ip=dhcp dns=${dnsbootimage} mode=onlydebug
	MENU LABEL Debug Mode
	TEXT HELP
	Debug mode will load the boot image and load a prompt so
	you can run any commands you wish.
	ENDTEXT
\n
PROMPT 0
TIMEOUT 30\n" > "${tftpdirdst}/pxelinux.cfg/default";

	if [ -f "$tftpconfig" ]
	then
		mv "$tftpconfig" "${tftpconfig}.fogbackup";
	fi

	# check if this is upstart based
	blUpstart="0";
	if [ -f "$tftpconfigupstartconf" ]
	then
		blUpstart="1";
	fi

	if [ "$blUpstart" = "1" ]
	then
		echo "# /etc/default/tftpd-hpa
# FOG Modified version
TFTP_USERNAME=\"root\"
TFTP_DIRECTORY=\"/tftpboot\"
TFTP_ADDRESS=\"0.0.0.0:69\"
TFTP_OPTIONS=\"-s\"" > "${tftpconfigupstartdefaults}";
		sysv-rc-conf xinetd off >/dev/null 2>&1;
		/etc/init.d/xinetd stop >/dev/null 2>&1;
		
		sysv-rc-conf tftpd-hpa on >/dev/null 2>&1;
		service tftpd-hpa stop >/dev/null 2>&1;
		sleep 5;
		service tftpd-hpa start >/dev/null 2>&1;
		if [ "$?" != "0" ]
		then
			echo "...Failed!";
			exit 1;	
		else
			echo "...OK";	
		fi			
	else
		echo "# default: off
# description: The tftp server serves files using the trivial file transfer \
#	protocol.  The tftp protocol is often used to boot diskless \
#	workstations, download configuration files to network-aware printers, \
#	and to start the installation process for some operating systems.
service tftp
{
	socket_type		= dgram
	protocol		= udp
	wait			= yes
	user			= root
	server			= /usr/sbin/in.tftpd
	server_args		= -s /tftpboot
	disable			= no
	per_source		= 11
	cps			= 100 2
	flags			= IPv4
}" > "${tftpconfig}";	

		sysv-rc-conf xinetd on >/dev/null 2>&1;
		/etc/init.d/xinetd stop >/dev/null 2>&1;
		/etc/init.d/xinetd start >/dev/null 2>&1;
		if [ "$?" != "0" ]
		then
			echo "...Failed!";
			exit 1;	
		else
			echo "...OK";	
		fi	
	fi	
}

configureDHCP()
{
	echo -n "  * Setting up and starting DHCP Server";

	activeconfig="";
	if [ -f "$dhcpconfig" ]
	then
		mv "$dhcpconfig" "${dhcpconfig}.fogbackup"
		activeconfig="$dhcpconfig" 
	elif [ -f "$olddhcpconfig" ]
	then
		mv "$olddhcpconfig" "${olddhcpconfig}.fogbackup"
		activeconfig="$olddhcpconfig" 
	fi
	
	networkbase=`echo "${ipaddress}" | cut -d. -f1-3`;
	network="${networkbase}.0";
	startrange="${networkbase}.10";
	endrange="${networkbase}.254";
	
	echo "# DHCP Server Configuration file.
# see /usr/share/doc/dhcp*/dhcpd.conf.sample
# This file was created by FOG
use-host-decl-names on;
ddns-update-style interim;
ignore client-updates;
next-server ${ipaddress};

subnet ${network} netmask 255.255.255.0 {
        option subnet-mask              255.255.255.0;
        range dynamic-bootp ${startrange} ${endrange};
        default-lease-time 21600;
        max-lease-time 43200;
${dnsaddress}
${routeraddress} 
        filename \"pxelinux.0\";
}" > "$activeconfig";
		
	if [ "$bldhcp" = "1" ]; then	
		sysv-rc-conf ${dhcpname} on >/dev/null 2>&1;
		sysv-rc-conf ${olddhcpname} on >/dev/null 2>&1;
		
		/etc/init.d/${dhcpname} stop >/dev/null 2>&1;
		/etc/init.d/${dhcpname} start >/dev/null 2>&1;
		try1="$?";
		
		/etc/init.d/${olddhcpname} stop >/dev/null 2>&1;
		/etc/init.d/${olddhcpname} start >/dev/null 2>&1;
		try2="$?";
		if [ "$try1" != "0" -o "$try2" != "0" ]
		then
			echo "...OK";
		else
			echo "...Failed!";
			exit 1;	
		fi
	else
		echo "...Skipped";
	fi

}

configureMinHttpd()
{
	configureHttpd;
	echo "<php die( \"This is a storage node, please do not access the web ui here!\" ); ?>" > "$webdirdest/management/index.php";
}

configureHttpd()
{
	echo -n "  * Setting up and starting Apache Web Server";
	sysv-rc-conf apache2 on;
	mv /etc/apache2/mods-available/php5* /etc/apache2/mods-enabled/  >/dev/null 2>&1
	/etc/init.d/apache2  stop  >/dev/null 2>&1
	/etc/init.d/apache2 start >/dev/null 2>&1;
	if [ "$?" != "0" ]
	then
		echo "...Failed!";
		exit 1;	
	else
		if [ ! -d "$webdirdest" ]
		then
			mkdir "$webdirdest";
		else
			rm -Rf "$webdirdest";
			mkdir "$webdirdest";
		fi		
		
		cp -Rf $webdirsrc/* $webdirdest/
		
		echo "<?php
/*
 *  FOG  is a computer imaging solution.
 *  Copyright (C) 2007  Chuck Syperski & Jian Zhang
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *
 */

define( \"IS_INCLUDED\", true );
define( \"TFTP_HOST\", \"${ipaddress}\" );
define( \"TFTP_FTP_USERNAME\", \"${username}\" );
define( \"TFTP_FTP_PASSWORD\", \"${password}\" );
define( \"TFTP_PXE_CONFIG_DIR\", \"/tftpboot/pxelinux.cfg/\" );
define( \"TFTP_PXE_KERNEL_DIR\", \"/tftpboot/fog/kernel/\" );
define( \"PXE_KERNEL\", \"fog/kernel/bzImage\" );
define( \"PXE_KERNEL_RAMDISK\", 127000 ); 
define( \"USE_SLOPPY_NAME_LOOKUPS\", \"1\");
define( \"MEMTEST_KERNEL\", \"fog/memtest/memtest\" );
define( \"PXE_IMAGE\",  \"fog/images/init.gz\" );
define( \"PXE_IMAGE_DNSADDRESS\",  \"${dnsbootimage}\" );
define( \"STORAGE_HOST\", \"${ipaddress}\" );
define( \"STORAGE_FTP_USERNAME\", \"${username}\" );
define( \"STORAGE_FTP_PASSWORD\", \"${password}\" );
define( \"STORAGE_DATADIR\", \"/images/\" );
define( \"STORAGE_DATADIR_UPLOAD\", \"/images/dev/\" );
define( \"STORAGE_BANDWIDTHPATH\", \"/fog/status/bandwidth.php\" );
define( \"CLONEMETHOD\", \"ntfsclone\" );  // valid values partimage, ntfsclone
define( \"UPLOADRESIZEPCT\", 5 ); 
define( \"WEB_HOST\", \"${ipaddress}\" );
define( \"WEB_ROOT\", \"/fog/\" );
define( \"WOL_HOST\", \"${ipaddress}\" ); 	
define( \"WOL_PATH\", \"/fog/wol/wol.php\" );   
define( \"WOL_INTERFACE\", \"${interface}\" );
define( \"SNAPINDIR\", \"${snapindir}/\" );
define( \"QUEUESIZE\", \"10\" );
define( \"CHECKIN_TIMEOUT\", 600 );
define( \"MYSQL_HOST\", \"localhost\" );
define( \"MYSQL_DATABASE\", \"fog\" );
define( \"MYSQL_USERNAME\", \"root\" );
define( \"MYSQL_PASSWORD\", \"\" );
define( \"DB_TYPE\", \"mysql\" );
define( \"DB_HOST\", MYSQL_HOST );
define( \"DB_NAME\", MYSQL_DATABASE );
define( \"DB_USERNAME\", MYSQL_USERNAME );
define( \"DB_PASSWORD\", MYSQL_PASSWORD );
define( \"DB_PORT\", null );
define( \"USER_MINPASSLENGTH\", 4 );
define( \"USER_VALIDPASSCHARS\", \"1234567890ABCDEFGHIJKLMNOPQRSTUVWZXYabcdefghijklmnopqrstuvwxyz_$-()^!\" );
define( \"NFS_ETH_MONITOR\", \"${interface}\" );
define(\"UDPCAST_INTERFACE\",\"${interface}\");
define(\"UDPCAST_STARTINGPORT\", 63100 ); 					// Must be an even number! recommended between 49152 to 65535
define(\"FOG_MULTICAST_MAX_SESSIONS\", 64 );
define( \"FOG_JPGRAPH_VERSION\", \"2.3\" );
define( \"FOG_REPORT_DIR\", \"./reports/\" );
define( \"FOG_THEME\", \"blackeye/blackeye.css\" );
define( \"FOG_UPLOADIGNOREPAGEHIBER\", \"1\" );
define( \"FOG_VERSION\", \"${version}\" );
define( \"FOG_SCHEMA\", ${schemaversion});
DEFINE('BASEPATH', rtrim(\$_SERVER['DOCUMENT_ROOT'], '/') . rtrim(WEB_ROOT, '/'));
?>" > "${webdirdest}/commons/config.php";
		
		
		chown -R ${apacheuser}:${apacheuser} "$webdirdest"
		
		if [ ! -f "$webredirect" ]
		then
			echo "<?php header('Location: ./fog/index.php');?>" > $webredirect;
		fi		
		
		echo "...OK";
	fi
}

configureSudo()
{
	echo -n "  * Setting up sudo settings";
	# This is no longer required, now that we switched to wakeonlan instead of etherwake
	#ret=`cat /etc/sudoers | grep "${apacheuser} ALL=(ALL) NOPASSWD: /usr/sbin/etherwake"`
	#if [ "$ret" = "" ]
	#then
	#	 echo "${apacheuser} ALL=(ALL) NOPASSWD: /usr/sbin/etherwake" >>  "/etc/sudoers";
	#fi
	echo "...OK";	
}

configureMySql()
{
	echo -n "  * Setting up and starting MySql";
	sysv-rc-conf mysql on >/dev/null 2>&1;
	/etc/init.d/mysql stop >/dev/null 2>&1;
	/etc/init.d/mysql start >/dev/null 2>&1;
	if [ "$?" != "0" ]
	then
		echo "...Failed!";
		exit 1;	
	else
		echo "...OK";
	fi	
}

installPackages()
{
	echo "  * Preparing apt-get";
	apt-get -y -q update >/dev/null 2>&1;
	sleep 1;

	if [ "$installlang" = "1" ]
	then
		packages="$packages $langPackages"
	fi
	
	for x in $packages
	do
		echo  "  * Installing package: $x";
		if [ "$x" = "mysql-server" ]
		then
			strDummy="";

			echo "";
			echo "     We are about to install MySQL Server on ";
			echo "     this server, if MySQL isn't installed already";
			echo "     you will be prompted for a root password.  If";
			echo "     you don't leave it blank you will need to change";
			echo "     it in the config.php file located at:";
			echo "     ";
			echo "     ${webdirdest}/commons/config.php";
			echo "";
			sleep 3;
			echo "     Press enter to acknowledge this message.";
			read strDummy;
			apt-get -y -q install $x;
			echo "";
		elif [ "$x" = "$dhcpname" ]
		then			
			apt-get -y -q install $dhcpname >/dev/null 2>&1;			
			apt-get -y -q install $olddhcpname >/dev/null 2>&1;
		else
			apt-get -y -q install $x >/dev/null 2>&1;
		fi
	done
}

confirmPackageInstallation()
{
	for x in $packages
	do
		echo -n "  * Checking package: $x";
		dpkg -l $x >/dev/null 2>&1;
		if [ "$?" != "0" ]
		then
			echo "...Failed!"
			if [ "$x" = "$dhcpname" ]
			then			
				echo -n "  * Checking for legacy package: $olddhcpname";
				dpkg -l $olddhcpname >/dev/null 2>&1;
				if [ "$?" != "0" ]
				then
					echo "...Failed!"
					exit 1;
				else
					echo "...OK";
				fi
			else
				exit 1;
			fi
		else
			echo "...OK";
		fi
	done;
}

setupFreshClam()
{
	echo  -n "  * Configuring Fresh Clam";

	if [ ! -d "${freshwebroot}" ]
	then
		mkdir "${freshwebroot}"
		ln -s "${freshdb}" "${freshwebroot}"
		chown -R ${apacheuser} "${freshwebroot}"
	fi

	sysv-rc-conf clamav-freshclam on >/dev/null 2>&1;
	/etc/init.d/clamav-freshclam stop >/dev/null 2>&1;
	/etc/init.d/clamav-freshclam start >/dev/null 2>&1;
	if [ "$?" != "0" ]
	then
		echo "...Failed!";
		exit 1;	
	else
		echo "...OK";
	fi
}

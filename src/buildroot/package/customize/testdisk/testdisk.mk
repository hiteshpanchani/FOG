#############################################################
#
# testdisk
#
#############################################################
TESTDISK_VERSION:=6.11.3
TESTDISK_SOURCE:=testdisk-$(TESTDISK_VERSION).tar.bz2
TESTDISK_SITE:=http://www.cgsecurity.org/
TESTDISK_INSTALL_STAGING=YES
TESTDISK_LIBTOOL_PATCH=NO
TESTDISK_CONF_OPT= --program-transform-name=
TESTDISK_DEPENDENCIES = ncurses

$(eval $(call AUTOTARGETS,package/customize,testdisk))

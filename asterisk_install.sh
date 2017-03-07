#!/bin/bash
# ------------------------------------------------------------------
# [Andrei Kirushchanka] Title
#          Asterisk 13 and freepbx 12 installation
# ------------------------------------------------------------------

ETH_INTERFACE_NAME="$(ls /sys/class/net | grep e)"
HOST_IP="$(hostname -I)"


# Update and install packages
syst_update_install() {
   yum update -y && yum install -y epel-release &&  yum install -y sudo crontabs e2fsprogs-devel  keyutils-libs-devel krb5-devel libogg libselinux-devel libsepol-devel libxml2-devel libtiff-devel gmp php-pear php php-gd php-mysql php-pdo php-mbstring ncurses-devel mysql-connector-odbc unixODBC unixODBC-devel audiofile-devel libogg-devel openssl-devel zlib-devel perl-DateManip sox git wget net-tools psmisc gcc-c++ make gnutls-devel libxml2-devel ncurses-devel subversion doxygen texinfo curl-devel net-snmp-devel neon-devel uuid-devel libuuid-devel speex-devel gsm-devel sqlite-devel sqlite libtool libtool-ltdl libtool-ltdl-devel kernel-devel kernel-headers "kernel-devel-uname-r == $(uname -r)" htop mc vim mariadb-server mariadb mariadb-devel bind bind-utils ntp iptables-services perl perl-CPAN perl-Net-SSLeay perl-IO-Socket-SSL mod_ssl

result $? "update, install new packages"
}

result() {
    if [ $1 -eq 0 ]; then
       # echo "result saved to $2 files in $WORK_DIR"
    else
        echo "error in $2"
        exit 1
    fi
}


# 
bind_configure(){

sed -i s/"listen-on-v6 port 53 { ::1; };"/"forwarders { 8.8.8.8; 8.8.4.4; };"/g /etc/named.conf
sed -i s/"DNS1=.*"/"DNS1=127.0.0.1"/g /etc/sysconfig/network-scripts/ifcfg-$ETH_INTERFACE_NAME
systemctl enable named
systemctl start named

}


#
ntp_configure(){

sed -i s/"SYNC_HWCLOCK=.*"/"SYNC_HWCLOCK=yes"/g /etc/sysconfig/ntpdate
/etc/ntp.conf


}



#
mariaDB_configure(){

}


#
pearDB_install(){
pear uninstall db
 pear install db-1.7.14
}

#
libsrtp_install(){

}


#
pjproject_install(){

}

#
Lame_mp3_install(){

}


#
DAHDI_install(){

}


#
LibPRI_install(){

}


#
spandsp_install(){

}

#
asterisk_13_install(){

}

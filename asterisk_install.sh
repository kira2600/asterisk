#!/bin/bash
# ------------------------------------------------------------------
# [Andrei Kirushchanka] Title
#          Asterisk 13 and freepbx 12 installation
# ------------------------------------------------------------------

SUBJECT="install_asterisk"
LOCK_FILE="/tmp/${SUBJECT}.lock"
ETH_INTERFACE_NAME="$(ls /sys/class/net | grep e)"
HOST_IP="$(hostname -I)"
SCRIPT_PATH="/root/asterisk"
SCRIPT_CONF_FILES="$SCRIPT_PATH/conf_files"
MYSQL_ROOT_PASSWORD=$1


# Check arguments
if [ $# == 0 ] ; then
    echo 'You need to set Mysql password'

    exit 1;
fi


result() {
    if [ $1 -eq 0 ]; then
        echo "OK $2"
    else
        echo "error in staring $2"
        exit 1
    fi
}


# Update and install packages
syst_update_install() {
   yum update -y && yum install -y epel-release &&  yum install -y sudo crontabs e2fsprogs-devel  keyutils-libs-devel krb5-devel libogg libselinux-devel libsepol-devel libxml2-devel libtiff-devel gmp php-pear php php-gd php-mysql php-pdo php-mbstring ncurses-devel mysql-connector-odbc unixODBC unixODBC-devel audiofile-devel libogg-devel openssl-devel zlib-devel perl-DateManip sox git wget net-tools psmisc gcc-c++ make gnutls-devel libxml2-devel ncurses-devel subversion doxygen texinfo curl-devel net-snmp-devel neon-devel uuid-devel libuuid-devel speex-devel gsm-devel sqlite-devel sqlite libtool libtool-ltdl libtool-ltdl-devel kernel-devel kernel-headers "kernel-devel-uname-r == $(uname -r)" htop mc vim mariadb-server mariadb mariadb-devel bind bind-utils ntp iptables-services perl perl-CPAN perl-Net-SSLeay perl-IO-Socket-SSL mod_ssl expect

result $? "update, install new packages"

}


download_apps(){

   cd /usr/src/
   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 http://sourceforge.net/projects/souptonuts/files/souptonuts/dictionary/linuxwords.1.tar.gz

   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 http://www.digip.org/jansson/releases/jansson-2.9.tar.gz

   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 http://sourceforge.net/projects/lame/files/lame/3.99/lame-3.99.5.tar.gz

  wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz

   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz

   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 http://soft-switch.org/downloads/spandsp/spandsp-0.0.6.tar.gz

   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2  http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz

   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2  http://mirror.freepbx.org/modules/packages/freepbx/freepbx-12.0-latest.tgz

   git clone git://github.com/cisco/libsrtp libsrtp

   git clone git://github.com/asterisk/pjproject pjproject

   tar zxvf linuxwords.1.tar.gz; tar zvxf jansson-2.9.tar.gz; tar zxvf lame-3.99.5.tar.gz
   tar xvfz dahdi-linux-complete-current.tar.gz; tar xvfz libpri-current.tar.gz; tar zxvf spandsp-0.0.6.tar.gz
   tar xvfz asterisk-13-current.tar.gz; tar zxvf freepbx-12.0-latest.tgz

}

disable_servicies(){

#disable firewall
   systemctl mask firewalld && systemctl stop firewalld

#disable ipV6 and chrony
   echo "net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1" >>  /etc/sysctl.conf
   systemctl stop chronyd
   systemctl disable chronyd

}

# Configure DNS
bind_configure(){

   sed -i s/"listen-on-v6 port 53 { ::1; };"/"forwarders { 8.8.8.8; 8.8.4.4; };"/g /etc/named.conf
   sed -i s/"DNS1=.*"/"DNS1=127.0.0.1"/g /etc/sysconfig/network-scripts/ifcfg-$ETH_INTERFACE_NAME
   systemctl enable named
   systemctl start named
   result $? "named"

}


#
ntp_configure(){

   sed -i s/"SYNC_HWCLOCK=.*"/"SYNC_HWCLOCK=yes"/g /etc/sysconfig/ntpdate
   sed -i s/"interface listen.*"/"interface listen $HOST_IP"/g $SCRIPT_CONF_FILES/ntp.conf
   mv /etc/ntp.conf /etc/ntp.conf_orig
   cp $SCRIPT_CONF_FILES/ntp.conf /etc/

   systemctl enable ntpd
   systemctl start ntpd
   result $? "ntpd"

}


#
mariaDB_configure(){

   systemctl start mariadb.service
   systemctl enable mariadb.service
   mariaDB_secure_installation

}


mariaDB_secure_installation(){

   SECURE_MYSQL=$(expect -c "
   set timeout 10
   spawn mysql_secure_installation
   expect \"Enter current password for root (enter for none):\"
   send \"\r\"
   expect \"Set root password?\"
   send \"y\r\"
   expect \"New password:\"
   send \"$MYSQL_ROOT_PASSWORD\r\"
   expect \"Re-enter new password:\"
   send \"$MYSQL_ROOT_PASSWORD\r\"
   expect \"Remove anonymous users?\"
   send \"y\r\"
   expect \"Disallow root login remotely?\"
   send \"n\r\"
   expect \"Remove test database and access to it?\"
   send \"y\r\"
   expect \"Reload privilege tables now?\"
   send \"y\r\"
   expect eof
   ")

   echo "$SECURE_MYSQL"

}

#
pearDB_install(){

   pear uninstall db && pear install db-1.7.14
   result $? "pearDB"
}

#
libsrtp_install(){

   cd /usr/src/ && rm -rf linuxwords.1.tar.gz && mv linuxwords.1/linux.words  /usr/share/dict/words && cd /usr/src/libsrtp &&  autoreconf -f -i && ./configure CFLAGS=-fPIC --prefix=/usr && make && make runtest && make install
   result $? "libsrtp"

}


#
pjproject_install(){

   cd /usr/src/pjproject/ && ./configure --libdir=/usr/lib64 --prefix=/usr --enable-shared --disable-sound --disable-resample && make dep && make && make install && ldconfig
   result $? "pjproject"

}


#
jasson_install(){

   cd /usr/src/jansson-2.9 && ./configure --prefix=/usr/ && make clean && make && make install && ldconfig
   result $? "jasson"

}

#
Lame_mp3_install(){

   cd /usr/src/lame-3.99.5 && ./configure && make && make install
   result $? "Lame mp3"

}


#
DAHDI_install(){

   cd /usr/src/dahdi-linux-complete-* && make all && make install && make config
   result $? "DAHDI"

}


#
LibPRI_install(){

   cd /usr/src/libpri-1.* && make && make install
   result $? "LibPRI"

}


#
spandsp_install(){

   cd /usr/src/spandsp-0.0.6 && ./configure && make && make install && ln -s /usr/local/lib/libspandsp.so.2 /usr/lib64/libspandsp.so.2
   result $? "Spandsp"

}


#
asterisk_13_install(){

   cd /usr/src/asterisk-13.* && ./configure --libdir=/usr/lib64 && contrib/scripts/get_mp3_source.sh && make menuselect.makeopts && menuselect/menuselect --enable-category MENUSELECT_ADDONS --enable-category MENUSELECT_AGIS --enable CORE-SOUNDS-EN-WAV --enable CORE-SOUNDS-EN-ULAW --enable CORE-SOUNDS-EN-ALAW --enable CORE-SOUNDS-EN-G729 --enable CORE-SOUNDS-EN-G722 --enable CORE-SOUNDS-RU-WAV --enable CORE-SOUNDS-RU-ULAW --enable CORE-SOUNDS-RU-ALAW  --enable CORE-SOUNDS-RU-GSM --enable CORE-SOUNDS-RU-G729 --enable CORE-SOUNDS-RU-G722 --enable MOH-OPSOUND-ULAW --enable MOH-OPSOUND-ALAW --enable MOH-OPSOUND-GSM --enable MOH-OPSOUND-G729 --enable MOH-OPSOUND-G722 --enable EXTRA-SOUNDS-EN-WAV --enable EXTRA-SOUNDS-EN-ULAW --enable EXTRA-SOUNDS-EN-ALAW --enable EXTRA-SOUNDS-EN-GSM --enable EXTRA-SOUNDS-EN-G729 --enable EXTRA-SOUNDS-EN-G722 menuselect.makeopts && make && make install && make config && ldconfig && sed -i 's/ASTARGS=""/ASTARGS="-U asterisk"/g'  /usr/sbin/safe_asterisk && useradd -m asterisk && chown asterisk.asterisk /var/run/asterisk && chown -R asterisk.asterisk /etc/asterisk && chown -R asterisk.asterisk /var/{lib,log,spool}/asterisk && chown -R asterisk.asterisk /usr/lib64/asterisk

}


#
apache_tune(){

   cp /etc/php.ini /etc/php.ini_orig && sed -ie 's/\;date\.timezone\ \=/date\.timezone\ \=\ "Europe\/Minsk"/g' /etc/php.ini && sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php.ini && cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_orig && sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/httpd/conf/httpd.conf && sed -i 's/AllowOverride None/AllowOverride All/'  /etc/httpd/conf/httpd.conf && timedatectl set-timezone Europe/Minsk && systemctl restart httpd && systemctl enable httpd

}


#
mariaDB_add_bases(){

   mysqladmin -u root -p$MYSQL_ROOT_PASSWORD create asterisk
   mysqladmin -u root -p$MYSQL_ROOT_PASSWORD create asteriskcdrdb
   cd /usr/src/freepbx && mysql -u root -p$MYSQL_ROOT_PASSWORD asterisk < SQL/newinstall.sql && mysql -u root -p$MYSQL_ROOT_PASSWORD asteriskcdrdb < SQL/cdr_mysql_table.sql && mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON asterisk.* TO asteriskuser@localhost IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';" && mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO asteriskuser@localhost IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';" && mysql -u root -p$MYSQL_ROOT_PASSWORD -e "flush privileges;"

}


#
install_freepbx(){

   /usr/src/freepbx/start_asterisk start
   rm -rf /var/www/html/
   cd /usr/src/freepbx/ && ./install_amp --installdb --username=asteriskuser --password=$MYSQL_ROOT_PASSWORD

   FREEPBX_PARAMS=$(expect -c "
   set timeout 10
   spawn ./install_amp --installdb --username=asteriskuser --password=$MYSQL_ROOT_PASSWORD
   expect \"Enter your USERNAME to connect to the 'asterisk' database:\"
   send \"\r\"
   expect \"Enter your PASSWORD to connect to the 'asterisk' database:\"
   send \"\r\"
   expect \"Enter the hostname of the 'asterisk' database:\"
   send \"\r\"
   expect \"Enter a USERNAME to connect to the Asterisk Manager interface:\"
   send \"\r\"
   expect \"Enter a PASSWORD to connect to the Asterisk Manager interface:\"
   send \"\r\"
   expect \"Enter the path to use for your AMP web root:\"
   send \"\r\"
   expect \"Enter the IP ADDRESS or hostname used to access the AMP web-admin:\"
   send \"\r\"
   expect \"Use simple Extensions [extensions] admin or separate Devices and Users [deviceanduser]?\"
   send \"\r\"
   expect \"Enter directory in which to store AMP executable scripts:\"
   send \"\r\"
   expect \"Enter directory in which to store super-user scripts:\"
   send \"\r\"
   expect eof
   ")

   echo "$FREEPBX_PARAMS"

   amportal a ma reload && amportal a ma refreshsignatures && amportal chown
   ln -s /var/lib/asterisk/moh /var/lib/asterisk/mohmp3
   amportal restart

}

# Lock file
if [ -f "$LOCK_FILE" ]; then
    echo "Script is already running"
    
    exit
fi

# Remove lock file immediately before exit of script
trap "rm -f $LOCK_FILE" EXIT
touch $LOCK_FILE

main(){

   syst_update_install; download_apps; disable_servicies; bind_configure; ntp_configure; mariaDB_configure; pearDB_install
   libsrtp_install; pjproject_install; jasson_install; Lame_mp3_install; DAHDI_install; LibPRI_install; spandsp_install
   asterisk_13_install; apache_tune; mariaDB_add_bases; install_freepbx


   exit 0

}

main

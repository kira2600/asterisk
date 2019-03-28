#!/bin/bash
# ------------------------------------------------------------------
# [Andrei Kirushchanka] Title
#          Asterisk 13 and freepbx 14 installation
# ------------------------------------------------------------------

SUBJECT="install_asterisk"
LOCK_FILE="/tmp/${SUBJECT}.lock"
ETH_INTERFACE_NAME="$(ls /sys/class/net | grep e)"
HOST_IP="$(hostname -I)"
SCRIPT_PATH="/root/asterisk"
SCRIPT_CONF_FILES="$SCRIPT_PATH/conf_files"
SCRIPT_MODULES="$SCRIPT_PATH/modules"
MYSQL_ROOT_PASSWORD=$1
#GIT_REPO="https://github.com/kira2600/asterisk/archive/master.tar.gz"


# Check arguments
if [ $# == 0 ] ; then
    echo 'You need to set Mysql password'

    exit 1;
fi

# Check selinux
selinux() {
    sestatus=$(sestatus | rev | cut -d " " -f1 | rev | head -n 1)

    if  [ $sestatus == "disabled" ]; then
        echo "Selinux disabled"
    else
        echo "Need to disable selinux. It will be disabled and You need to reboot the system"
        sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
        exit 1 
    fi
}


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
   yum update -y && yum install -y epel-release &&  yum install -y sudo crontabs e2fsprogs-devel  keyutils-libs-devel krb5-devel libogg libselinux-devel libsepol-devel libtiff-devel gmp php-pear php php-gd php-mysql php-pdo php-mbstring ncurses-devel mysql-connector-odbc unixODBC unixODBC-devel audiofile-devel libogg-devel openssl-devel zlib-devel perl-DateManip sox git wget net-tools psmisc gcc-c++ make gnutls-devel libxml2-devel ncurses-devel subversion doxygen texinfo curl-devel net-snmp-devel neon-devel uuid-devel libuuid-devel speex-devel gsm-devel sqlite-devel sqlite libtool libtool-ltdl libtool-ltdl-devel kernel-devel kernel-headers "kernel-devel-uname-r == $(uname -r)" htop mc vim mariadb-server mariadb mariadb-devel bind bind-utils ntp iptables-services perl perl-CPAN perl-Net-SSLeay perl-IO-Socket-SSL mod_ssl expect ghostscript lynx tftp-server sendmail sendmail-cf newt-devel gtk2-devel cronie cronie-anacron python-devel && yum -y groupinstall core base "Development Tools"

rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

yum -y remove php*
yum -y install php56w php56w-pdo php56w-mysql php56w-mbstring php56w-pear php56w-process php56w-xml php56w-opcache php56w-ldap php56w-intl php56w-soap

curl -sL https://rpm.nodesource.com/setup_8.x | bash -
yum install -y nodejs

result $? "update, install new packages"

}


download_apps(){

   cd /usr/src/
#   wget --retry-connrefused --read-timeout=10 --timeout=10 --waitretry=2 -t 0 --continue http://sourceforge.net/projects/souptonuts/files/souptonuts/dictionary/linuxwords.1.tar.gz && \
#   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 http://www.digip.org/jansson/releases/jansson-2.9.tar.gz
#   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 http://sourceforge.net/projects/lame/files/lame/3.100/lame-3.100.tar.gz && \
   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz && \
   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz && \
   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 https://www.soft-switch.org/downloads/spandsp/spandsp-0.0.6.tar.gz && \
   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2  http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz && \
   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2  http://mirror.freepbx.org/modules/packages/freepbx/freepbx-14.0-latest.tgz && \
   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 --no-check-certificate --output-document=AsternicCallCenterStats.tar.gz https://owncloud.sysadmins.by/index.php/s/avhTbEWz8fyp6og/download && \
   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 --no-check-certificate --output-document=el_fax.tar.gz https://owncloud.sysadmins.by/index.php/s/jrHKHsVmbOJw51O/download && \
   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 --no-check-certificate --output-document=lame-3.100.tar.gz https://owncloud.sysadmins.by/index.php/s/nxx432OY5dDRqmL/download && \
   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 --no-check-certificate --output-document=linuxwords.1.tar.gz https://owncloud.sysadmins.by/index.php/s/tC6MgqfNuCqQ0Jh/download && \
   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 --no-check-certificate --output-document=sendEmail-v1.56.tar.gz https://owncloud.sysadmins.by/index.php/s/YoWkO7zTCoTDYHk/download && \
   git clone https://github.com/cisco/libsrtp libsrtp && \
   git clone https://github.com/asterisk/pjproject pjproject && \
   git clone https://github.com/akheron/jansson jansson

if [ $? != 0 ]; then
   echo "can't download"; 
   exit 1;
fi
   tar zxvf linuxwords.1.tar.gz; tar zxvf lame-3.100.tar.gz
   tar xvfz dahdi-linux-complete-current.tar.gz; tar xvfz libpri-current.tar.gz; tar zxvf spandsp-0.0.6.tar.gz
   tar xvfz asterisk-13-current.tar.gz; tar zxvf freepbx-14.0-latest.tgz; tar zxvf AsternicCallCenterStats.tar.gz
   tar zxvf el_fax.tar.gz; tar zxvf sources.tar.gz; tar zxvf sendEmail-v1.56.tar.gz




#   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 --no-check-certificate --output-document=sources.tar.gz https://owncloud.sysadmins.by/index.php/s/ASvBhKAd0LrkXO7/download
#   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 --no-check-certificate --output-document=asterisk-13-current.tar.gz https://storage.sysadmins.by/index.php/s/5cE3AFANQqMGxYq/download
#   wget --tries=4 --retry-connrefused --read-timeout=5 --timeout=10 --waitretry=2 --no-check-certificate --output-document=freepbx-12.0-latest.tgz https://storage.sysadmins.by/index.php/s/iv44kwSGFB7goS7/download


}

disable_servicies(){

#disable firewall
   systemctl mask firewalld && systemctl stop firewalld

#disable ipV6 and chrony
#  echo "net.ipv6.conf.all.disable_ipv6 = 1
#  net.ipv6.conf.default.disable_ipv6 = 1" >>  /etc/sysctl.conf
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

   #pear uninstall db && 
   pear install Console_Getopt #pear install db-1.7.14
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
jansson_install(){

   cd /usr/src/jansson && autoreconf -i && ./configure --prefix=/usr/ && make clean && make && make install && ldconfig
   result $? "jansson"

}

#
Lame_mp3_install(){

   cd /usr/src/lame* && ./configure && make && make install
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
install_freepbx14(){


   cd /usr/src/freepbx/ 
   ./start_asterisk start
   ./install -n --dbpass=$MYSQL_ROOT_PASSWORD
}
#
install_freepbx(){

   /usr/src/freepbx/start_asterisk start
   rm -rf /var/www/html/
   cd /usr/src/freepbx/ 

   FREEPBX_PARAMS=$(expect -c "
   set timeout 1
   spawn ./install_amp --installdb --username=asteriskuser --password=$MYSQL_ROOT_PASSWORD
   expect \"Enter your USERNAME to connect to the 'asterisk' database:\n\"
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
   expect \"Use simple Extensions \[extensions\] admin or separate Devices and Users \[deviceanduser\]\?\"
   send \"\r\"
   expect \"Enter directory in which to store AMP executable scripts:\"
   send \"\r\"
   expect \"Enter directory in which to store super-user scripts:\"
   send \"\r\"
   set timeout 60
   expect eof
   ")

   echo "$FREEPBX_PARAMS"

   amportal a ma reload && amportal a ma refreshsignatures && amportal chown
   ln -s /var/lib/asterisk/moh /var/lib/asterisk/mohmp3
   amportal restart

}


#
log_rotation(){

   echo "/var/log/asterisk/*log {
   missingok
   rotate 12
   weekly
   create 0640 asterisk asterisk
   postrotate
      /usr/sbin/asterisk -rx 'logger reload' > /dev/null 2> /dev/null
   endscript	
   su asterisk asterisk
}

/var/log/asterisk/full {
   missingok
   rotate 7
   daily
   create 0640 asterisk asterisk
   postrotate
      /usr/sbin/asterisk -rx 'logger reload' > /dev/null 2> /dev/null
   endscript
   su asterisk asterisk
}" > /etc/logrotate.d/asterisk

   echo "0 1 * * * /usr/sbin/logrotate -s /var/log/logrotate.state /etc/logrotate.conf" >> /var/spool/cron/root

}


#
install_asternik(){

   $SCRIPT_MODULES/asternik.sh $MYSQL_ROOT_PASSWORD

}

install_free_pbx_modules(){

   cd /usr/src/freepbx/

   amportal a ma enablerepo extended,standard

   amportal a ma download accountcodepreserve; amportal a ma download announcement; amportal a ma download areminder; amportal a ma download arimanager; amportal a ma download asteriskinfo; amportal a ma download backup; amportal a ma download blacklist; amportal a ma download bulkdids; amportal a ma download bulkextensions; amportal a ma download callback; amportal a ma download callforward; amportal a ma download callrecording; amportal a ma download callwaiting; amportal a ma download campon; amportal a ma download cdr; amportal a ma download certman; amportal a ma download cidlookup; amportal a ma download conferences; amportal a ma download conferencespro; amportal a ma download contactmanager; amportal a ma download core; amportal a ma download customappsreg; amportal a ma download dashboard; amportal a ma download daynight; amportal a ma download dictate; amportal a ma download directory; amportal a ma download disa; amportal a ma download donotdisturb; amportal a ma download endpoint; amportal a ma download extensionroutes; amportal a ma download fax; amportal a ma download featurecodeadmin; amportal a ma download findmefollow; amportal a ma download framework; amportal a ma download freepbx_ha; amportal a ma download fw_langpacks; amportal a ma download hotelwakeup; amportal a ma download infoservices; amportal a ma download ivr; amportal a ma download languages; amportal a ma download logfiles; amportal a ma download manager; amportal a ma download miscapps; amportal a ma download miscdests; amportal a ma download music; amportal a ma download outroutemsg; amportal a ma download paging; amportal a ma download parking; amportal a ma download pbdirectory; amportal a ma download phonebook; amportal a ma download pinsets; amportal a ma download presencestate; amportal a ma download queueprio; amportal a ma download queues; amportal a ma download recordings; amportal a ma download restapi; amportal a ma download restapps; amportal a ma download restart; amportal a ma download ringgroups; amportal a ma download setcid; amportal a ma download sipsettings; amportal a ma download speeddial; amportal a ma download sysadmin; amportal a ma download timeconditions; amportal a ma download ucp; amportal a ma download userman; amportal a ma download vmblast; amportal a ma download vmnotify; amportal a ma download voicemail; amportal a ma download voicemail_report 

   set timeout 1

   mportal a ma install accountcodepreserve; amportal a ma install announcement; amportal a ma install areminder; amportal a ma install arimanager; amportal a ma install asteriskinfo; amportal a ma install backup; amportal a ma install blacklist; amportal a ma install bulkdids; amportal a ma install bulkextensions; amportal a ma install callback; amportal a ma install callforward; amportal a ma install callrecording; amportal a ma install callwaiting; amportal a ma install campon; amportal a ma install cdr; amportal a ma install certman; amportal a ma install cidlookup; amportal a ma install conferences; amportal a ma install conferencespro; amportal a ma install contactmanager; amportal a ma install core; amportal a ma install customappsreg; amportal a ma install dashboard; amportal a ma install daynight; amportal a ma install dictate; amportal a ma install directory; amportal a ma install disa; amportal a ma install donotdisturb; amportal a ma install endpoint; amportal a ma install extensionroutes; amportal a ma install fax; amportal a ma install featurecodeadmin; amportal a ma install findmefollow; amportal a ma install framework; amportal a ma install freepbx_ha; amportal a ma install fw_langpacks; amportal a ma install hotelwakeup; amportal a ma install infoservices; amportal a ma install ivr; amportal a ma install languages; amportal a ma install logfiles; amportal a ma install manager; amportal a ma install miscapps; amportal a ma install miscdests; amportal a ma install music; amportal a ma install outroutemsg; amportal a ma install paging; amportal a ma install parking; amportal a ma install pbdirectory; amportal a ma install phonebook; amportal a ma install pinsets; amportal a ma install presencestate; amportal a ma install queueprio; amportal a ma install queues; amportal a ma install recordings; amportal a ma install restapi; amportal a ma install restapps; amportal a ma install restart; amportal a ma install ringgroups; amportal a ma install setcid; amportal a ma install sipsettings; amportal a ma install speeddial; amportal a ma install sysadmin; amportal a ma install timeconditions; amportal a ma install ucp; amportal a ma install userman; amportal a ma install vmblast; amportal a ma install vmnotify; amportal a ma install voicemail

   set timeout 1

   amportal a ma reload && amportal a ma refreshsignatures && amportal chown

}

elfax_install(){

   $SCRIPT_MODULES/elfax.sh $SCRIPT_PATH

}

encoding_fix(){

   mysql -u root -p$MYSQL_ROOT_PASSWORD -e 'ALTER TABLE `devices` COLLATE='utf8_general_ci', CONVERT TO CHARSET utf8;' asterisk
   mysql -u root -p$MYSQL_ROOT_PASSWORD -e 'ALTER TABLE `users` COLLATE='utf8_general_ci', CONVERT TO CHARSET utf8;' asterisk

}

startup_freepbx(){

   echo "[Unit]
Description=FreePBX VoIP Server
After=mariadb.service
 
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/fwconsole start -q
ExecStop=/usr/sbin/fwconsole stop -q
 
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/freepbx.service

   ln -s '/etc/systemd/system/freepbx.service' '/etc/systemd/system/multi-user.target.wants/freepbx.service'

   systemctl start freepbx
   
   result $? "startup freepbx"

}

install_modules(){
   fwconsole ma downloadinstall blacklist backup cidlookup contactmanager phonebook restapi announcement daynight callwaiting callforward directory donotdisturb findmefollow ivr callback asteriskinfo calendar fax hotelwakeup manager miscapps miscdests paging parking queueprio queues ringgroups setcid speeddial vmblast arimanager timeconditions
}

replace_odbc(){
   odbc_connector=$(rpm -qa | grep mysql-connector-odbc)
   rpm -e --nodeps $odbc_connector 
   echo "[sng-pkgs]
name=Sangoma-\$releasever - Sangoma Open Source Packages
mirrorlist=http://mirrorlist.sangoma.net/?release=\$releasever&arch=\$basearch&repo=sng7&dist=\$dist
#baseurl=http://package1.sangoma.net...
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Sangoma-7" >>/etc/yum.repos.d/sangoma.repo
   yum install mariadb-connector-odbc -y
   cat /etc/odbcinst.ini

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

#   curl -SL $GIT_REPO | tar -xz
#   result $? "cloning repo from git"

   selinux; syst_update_install; disable_servicies; bind_configure; ntp_configure; download_apps; mariaDB_configure; 
#  pearDB_install;
   libsrtp_install; pjproject_install; jansson_install; Lame_mp3_install; DAHDI_install; LibPRI_install; spandsp_install
   asterisk_13_install; apache_tune; install_freepbx14; startup_freepbx; install_modules
   log_rotation; install_asternik; elfax_install; replace_odbc
#mariaDB_add_bases; 
#install_freepbx; encoding_fix
#   install_free_pbx_modules; 

   service network restart

   exit 0

}

main

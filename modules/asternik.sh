#!/bin/bash
# ------------------------------------------------------------------
# [Andrei Kirushchanka] Title
#          Asternik installation
# ------------------------------------------------------------------
   cd /usr/src/AsternicCallCenterStats && mysql -u root -p$MYSQL_ROOT_PASSWORD  < sql/qstats.sql
   sed -i s/"\$dbpass =.*"/"\$dbpass = '$MYSQL_ROOT_PASSWORD';"/g /usr/src/AsternicCallCenterStats/stat/config.php
   sed -i s/"\$manager_secret =.*"/"\$manager_secret = '$MYSQL_ROOT_PASSWORD';"/g /usr/src/AsternicCallCenterStats/stat/config.php
   sed -i s/"\$dbpass =.*"/"\$dbpass = '$MYSQL_ROOT_PASSWORD';"/g /usr/src/AsternicCallCenterStats/parselog/config.php
   cp -R /usr/src/AsternicCallCenterStats/stat /var/www/html/stat && cp -R /usr/src/AsternicCallCenterStats/parselog /usr/local && chown -R asterisk.asterisk /var/www/html/stat && chown -R asterisk.asterisk /usr/local/parselog  && echo "0 * * * * php -q /usr/local/parselog/parselog.php convertlocal" >> /var/spool/cron/root


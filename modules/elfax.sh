#!/bin/bash
# ------------------------------------------------------------------
# [Andrei Kirushchanka] Title
#          elfax installation
# ------------------------------------------------------------------
cd /usr/src/elFAX
chown asterisk.asterisk -R *
chmod 755 fax.php
cp fax.php /var/www/html/
chmod 775 fax/fax-send.sh
cp -R fax /var/lib/asterisk/agi-bin/
mkdir -p /var/spool/asterisk/fax/queue
mkdir /var/spool/asterisk/fax/tmp
chown -R asterisk.asterisk /var/spool/asterisk/fax/
echo "[fax-tx]
exten => send,1,NoOP(------------------- FAX from \${CALLERID(number)} ------------------)
exten => send,n,Set(FAXOPT(headerinfo)=header for fax)
exten => send,n,Set(FAXOPT(localstationid)=my company)
exten => send,n,Set(FAXOPT(maxrate)=14400)
exten => send,n,Set(FAXOPT(minrate)=4800)

exten => send,n,WaitForSilence(500,1,15)
exten => send,n,NoOP(--- \${WAITSTATUS}  ---)
exten => send,n,Answer()
exten => send,n,Wait(3)
exten => send,n,SendFAX(\${PICTURE})
exten => send,n,NoOP(--- \${FAXSTATUS} ---\${FAXERROR} ---\${REMOTESTATIONID} ---)
exten => send,n,Hangup()

exten => h,1,NoOP(------------------- FAX to \${EXTEN} with \${FAXSTATUS} -----------------)
;exten => h,n,GotoIf(\$[\"\${FAXSTATUS}\" = \"SUCCESS\"]?h,success:h,failed)
;exten => h,n(failed),Hangup()
;exten => h,n(success),system(echo \"\${FAXSTATUS} ---\${FAXERROR} ---\${REMOTESTATIONID}\" | mail -s \"FAX to \${EXTEN}\" \${EMAIL})
exten => h,n,System(/usr/src/sendEmail-v1.56/sendEmail.pl -f from@gmail.com -t \${EMAIL} -u \"fax result\" -m \"\${FAXSTATUS} --\${FAXERROR} ---\${REMOTESTATIONID} \" -s smtp.gmail.com -o tls=yes -xu from@gmail.com -xp pass -o message-charset=UTF-8)
exten => h,n,Hangup()" >>/etc/asterisk/extensions_custom.conf

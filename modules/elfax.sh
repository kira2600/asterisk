#!/bin/bash
# ------------------------------------------------------------------
# [Andrei Kirushchanka] Title
#          elfax and queue-email installation
# ------------------------------------------------------------------

CREDENTIALS="$1/email_credentials"
MAIL_FROM=`sed -n '1p' < $CREDENTIALS`
PASSWORD=`sed -n '2p' < $CREDENTIALS`
MAIL_TO=`sed -n '3p' < $CREDENTIALS`

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
exten => h,n,System(/usr/src/sendEmail-v1.56/sendEmail.pl -f $MAIL_FROM -t \${EMAIL} -u \"fax result\" -m \"\${FAXSTATUS} --\${FAXERROR} ---\${REMOTESTATIONID} \" -s smtp.gmail.com -o tls=yes -xu $MAIL_FROM -xp $PASSWORD -o message-charset=UTF-8)
exten => h,n,Hangup()" >>/etc/asterisk/extensions_custom.conf

echo "[ext-queues]
exten => h,1,ExecIf(\$[\"\${CDR(disposition)}\"!=\"ANSWERED\"]?System(/usr/src/sendEmail-v1.56/sendEmail.pl -f $MAIL_FROM -t $MAIL_TO -u \"Пропущенный звонок с номера \${CALLERID(num)}\" -m \"Пропущенный звонок с номера \${CALLERID(num)}\" -s smtp.gmail.com -o tls=yes -xu $MAIL_FROM -xp $PASSWORD -o message-charset=UTF-8))
exten => h,n,Macro(hangupcall,)

[ext-fax]
include => ext-fax-custom
exten => s,1,Macro(user-callerid,)
exten => s,n,Noop(Receiving Fax for: \${FAX_RX_EMAIL} , From: \${CALLERID(all)})
exten => s,n(receivefax),StopPlaytones
exten => s,n,ReceiveFAX(\${ASTSPOOLDIR}/fax/\${UNIQUEID}.tif,f)
exten => s,n,ExecIf(\$[\"\${FAXSTATUS:0:6}\"=\"FAILED\" && \"\${FAXERROR}\"!=\"INIT_ERROR\"]?Set(FAXSTATUS=\"FAILED: error: \${FAXERROR} statusstr: \${FAXOPT(statusstr)}\"))
exten => s,n,Hangup

exten => h,1,GotoIf(\$[\${STAT(e,\${ASTSPOOLDIR}/fax/\${UNIQUEID}.tif)} = 0]?failed)
exten => h,n(process),GotoIf(\$[\${LEN(\${FAX_RX_EMAIL})} = 0]?noemail)
exten => h,n(delete_opt),Set(DELETE_AFTER_SEND=true)
exten => h,n,System(/usr/src/sendEmail-v1.56/sendEmail.pl -f $MAIL_FROM -t \${FAX_RX_EMAIL} -u \"Входящий fax  с номера \${STRREPLACE(CALLERID(all),',\\\\')}\" -m \" С номера \${STRREPLACE(CALLERID(all),',\\\\')} на номер \${FROM_DID}\"  -a \${ASTSPOOLDIR}/fax/\${UNIQUEID}.tif -s smtp.gmail.com -o tls=yes -xu $MAIL_FROM -xp $PASSWORD -o message-charset=UTF-8)
exten => h,n(end),Macro(hangupcall,)
exten => h,n(noemail),Noop(ERROR: No Email Address to send FAX: status: [\${FAXSTATUS}],  From: [\${CALLERID(all)}])
exten => h,n,Macro(hangupcall,)
exten => h,process+101(failed),Noop(FAX \${FAXSTATUS} for: \${FAX_RX_EMAIL} , From: \${CALLERID(all)})
exten => h,n,Macro(hangupcall,)

;--== end of [ext-fax] ==--;" >>/etc/asterisk/extensions_override_freepbx.conf



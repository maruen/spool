#!/bin/bash
ATSMS_SPOOL=/var/spool/atsms
INBOX=${ATSMS_SPOOL}/$1/inbox
CONSUMED=${ATSMS_SPOOL}/$1/consumed
SMS_MESSAGES=`ls ${INBOX}`
URL_PROD="https://www.atsms.com.br/sms?msisdn=PHONE&date=DATE&message=TEXT&line=$1"

for FILE in $SMS_MESSAGES ; do
   
   PHONE=`echo ${FILE} | cut -c17-` 
   DATE=`echo ${FILE} | cut -c1-15`
   TEXT_WITHOUT_LINE_BREAKS=`sed ':a;N;$!ba;s/\n/ATSMS_LINE_BREAK/g' <  ${INBOX}/${FILE}`
   `echo $TEXT_WITHOUT_LINE_BREAKS > ${INBOX}/${FILE}`
   TEXT_ENCODED=`${ATSMS_SPOOL}/urlencode.sh ${INBOX}/${FILE}`
   SMS_URL_PROD=`echo ${URL_PROD} | sed "s/PHONE/${PHONE}/" | sed "s/DATE/${DATE}/" | sed "s/TEXT/${TEXT_ENCODED}/"`
   echo "SMS[Telefone: ${PHONE}, Data: ${DATE}, Texto: ${TEXT_ENCODED} ]"		
   echo "Posting to URL: ${SMS_URL_PROD}" 
   POST=`curl -s --sslv3 --insecure $SMS_URL_PROD`
   echo "Result of Post was: ${POST}"
  
   if [[ "$POST" == "OK"  ||  "$POST" == "MESSAGE_ALREADY_INSERTED" ]]; then 
	MOVE_FILE="mv -f ${INBOX}/${FILE} ${CONSUMED}"
   	echo "MOVE_FILE: ${MOVE_FILE}"
	${MOVE_FILE}
   else
	if [[ "$POST" != "OK" && "$POST" != "MESSAGE_ALREADY_INSERTED" ]]; then
		echo "ATSMS Server is probably down...."
	fi		
   fi

done


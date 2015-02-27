#!/bin/bash
ATSMS_SPOOL=/var/spool/atsms
INBOX=${ATSMS_SPOOL}/$1/inbox
CONSUMED=${ATSMS_SPOOL}/$1/consumed
SMS_MESSAGES=`ls ${INBOX}`
URL="www.atsms.com.br/sms?phone=PHONE&date=DATE&message=TEXT&line=$1"
#URL="192.168.1.34:9000/sms?phone=PHONE&date=DATE&message=TEXT&line=$1"

for FILE in $SMS_MESSAGES ; do
   
   if [ `echo ${FILE} | grep -c "+55" ` -gt 0 ] 
   then
	PHONE=`echo ${FILE} | cut -c25-35` 
   else
	PHONE=`echo ${FILE} | cut -c23-33` 
   fi	

   DATE=`echo ${FILE} | cut -c3-17`
   TEXT_WITHOUT_LINE_BREAKS=`tr '\n', ' ' < ${INBOX}/${FILE}`
   `echo $TEXT_WITHOUT_LINE_BREAKS > ${INBOX}/${FILE}`
   #TEXT_ENCODED=`/bin/cat ${INBOX}/${FILE} | sed -f ${ATSMS_SPOOL}/urlencode.sed`
   #TEXT_ENCODED=`echo ${TEXT_WITHOUT_LINE_BREAKS} | sed -f ${ATSMS_SPOOL}/urlencode.sed`
   TEXT_ENCODED=`${ATSMS_SPOOL}/urlencode.sh ${INBOX}/${FILE}`
   SMS_URL=`echo ${URL} | sed "s/PHONE/${PHONE}/" | sed "s/DATE/${DATE}/" | sed "s/TEXT/${TEXT_ENCODED}/"`
   echo "SMS[Telefone: ${PHONE}, Data: ${DATE}, Texto: ${TEXT_ENCODED} ]"		
   echo "Posting to URL: ${SMS_URL}" 
      
	if [[ $PHONE =~ ^[0-9]+$ ]]; then
			 
		   POST=`curl -s $SMS_URL`
			echo "Result of Post was: ${POST}"
  
  			if [[ "$POST" == "OK" ]]; then 
   			MOVE_FILE="mv -f ${INBOX}/${FILE} ${CONSUMED}"
   			echo "MOVE_FILE: ${MOVE_FILE}"
				${MOVE_FILE}
			else
				echo "ATSMS Server is down..."
			fi
	else
			echo "SMS not posted to the server, filename does not match the standards"
   fi

done


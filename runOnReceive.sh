#!/bin/bash
ATSMS_SPOOL=/var/spool/atsms
INBOX=${ATSMS_SPOOL}/$1/inbox
CONSUMED=${ATSMS_SPOOL}/$1/consumed
SMS_MESSAGES=`ls ${INBOX}`
URL_PROD="https://www.atsms.com.br/sms?msisdn=PHONE&date=DATE&message=TEXT&line=$1"
URL_DEV="https://192.168.1.34:9443/sms?msisdn=PHONE&date=DATE&message=TEXT&line=$1"
POST_TO_DEV="FALSE"

for FILE in $SMS_MESSAGES ; do
   
   FILE_LENGTH=`echo ${FILE} | wc -c`
   if   [ ${FILE_LENGTH}  -eq 40 ]
   then
	PHONE=`echo ${FILE} | cut -c25-35` 
   elif [ ${FILE_LENGTH} -eq 39  ]
   then 
	PHONE=`echo ${FILE} | cut -c25-34` 
   fi	

   DATE=`echo ${FILE} | cut -c3-17`
   TEXT_WITHOUT_LINE_BREAKS=`tr '\n', ' ' < ${INBOX}/${FILE}`
   `echo $TEXT_WITHOUT_LINE_BREAKS > ${INBOX}/${FILE}`
   TEXT_ENCODED=`${ATSMS_SPOOL}/urlencode.sh ${INBOX}/${FILE}`
   SMS_URL_PROD=`echo ${URL_PROD} | sed "s/PHONE/${PHONE}/" | sed "s/DATE/${DATE}/" | sed "s/TEXT/${TEXT_ENCODED}/"`
   SMS_URL_DEV=`echo ${URL_DEV} | sed "s/PHONE/${PHONE}/" | sed "s/DATE/${DATE}/" | sed "s/TEXT/${TEXT_ENCODED}/"`
   echo "SMS[Telefone: ${PHONE}, Data: ${DATE}, Texto: ${TEXT_ENCODED} ]"		
      
	if [[ $PHONE =~ ^[0-9]+$ ]]; then
			 
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

	   if [[ "$POST_TO_DEV" == "TRUE" ]]; then
   	        echo "Posting to URL: ${SMS_URL_DEV}" 
	   	POST=`curl -s --sslv3 --insecure $SMS_URL_DEV`
		echo "Result of Post was: ${POST}"
		
		if [[ "$POST" == "OK" ]]; then
			echo "POSTED TO DEV SERVER"
		else
			echo "DEV SERVER IS DOWN"
		fi
	   fi

	else
		echo "SMS not posted to the server, filename does not match the standards"
   fi

done


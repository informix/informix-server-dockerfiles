#!/bin/bash
#
#  name:        informix_setup_hqagent.sh:
#  description: Setup HQ server on docker image 
#  Called by:   informix_entry.sh


PROP_PATH=$INFORMIXDIR/hq/agent.properties
HQLOG=$INFORMIXDIR/hq/hq.log

SLEEP=15
ITER=10

HQLOG ">>>  HQAGENT: " 
HQLOG ">>>     HQAGENT: HQADMIN_PASSWORD: ${env_HQADMIN_PASSWORD}" 
HQLOG ">>>     HQAGENT: INFORMIX_PASSWORD: ${env_INFORMIX_PASSWORD}" 
HQLOG ">>>     HQAGENT: HOSTNAME : $HOSTNAME" 
HQLOG ">>>     HQAGENT: HQSERVER_MAPPED_HOSTNAME: ${env_HQSERVER_MAPPED_HOSTNAME}" 
HQLOG ">>>     HQAGENT: HQSERVER_MAPPED_HTTP_PORT: ${env_HQSERVER_MAPPED_HTTP_PORT}" 
HQLOG ">>>     HQAGENT: MAPPED_HOSTNAME: ${env_MAPPED_HOSTNAME}"
HQLOG ">>>     HQAGENT: HQSERVER : $env_HQSERVER" 




HQSERVER_ID=0
HQAGENT_ID=0
GROUP_ID=0

###
### Register Server attempt(s) 
###
register_hqagent_with_hqserver() {

HQLOG ">>>        HQAGENT: REGISTERING HQAGENT with HQSERVER" 
HQLOG ">>>            HQAGENT: REGISTER ATTEMPT $i" 

for i in $(eval echo "{1..$ITER}")
do

REGISTERED_ID=`curl -basic -u admin:${env_HQADMIN_PASSWORD} -H 'Content-Type: application/json' -H 'Accept: application/json' http://${env_HQSERVER_MAPPED_HOSTNAME}:${env_HQSERVER_MAPPED_HTTP_PORT}/api/informix --data-binary "{'groupId': 0, 'alias': '${env_MAPPED_HOSTNAME}', 'hostname': '${env_MAPPED_HOSTNAME}', 'port': ${env_MAPPED_SQLI_PORT}, 'monitorUser': 'informix', 'monitorPassword': '${env_INFORMIX_PASSWORD}', 'adminUser': 'informix', 'adminPassword': '${env_INFORMIX_PASSWORD}'}" 2>/dev/null | jq '.id'`

HQLOG ">>>            HQAGENT: REGISTER ATTEMPT $i" 
   if [[ ! -z ${REGISTERED_ID} ]] 
   then
   break
   fi
   sleep $SLEEP 

done
HQAGENT_ID=$REGISTERED_ID
HQLOG ">>>        HQAGENT: HQAGENT SERVER ID $HQAGENT_ID" 
}


###
### Create Properties file
###
create_properties_file() {
sudo echo "" > $PROP_PATH
sudo chmod 644 $PROP_PATH 
sudo echo "informixServer.id=$HQAGENT_ID" >> $PROP_PATH
sudo echo "server.host=${env_HQSERVER_MAPPED_HOSTNAME}" >> $PROP_PATH
sudo echo "server.port=${env_HQSERVER_MAPPED_HTTP_PORT}" >> $PROP_PATH

cat $PROP_PATH >> $HQLOG

}


###
### Run hqagent
###
start_hqagent() {
cd $INFORMIXDIR/hq
java -jar $INFORMIXDIR/hq/informixhq-agent.jar >> $HQLOG & 
}


##
## Get Server list, find server id, pass in string
get_hqserver_id() {
SERVNAME=$1 
for i in $(eval echo "{1..$ITER}")
do
HQLOG ">>>        HQAGENT: GET server($SERVNAME) ID ATTEMPT: $i" 

GROUP_ID=`curl -basic -u admin:${env_HQADMIN_PASSWORD} -H 'Content-Type: application/json' -H 'Accept: application/json' http://${env_HQSERVER_MAPPED_HOSTNAME}:${env_HQSERVER_MAPPED_HTTP_PORT}/api/informix/groups/0 2>/dev/null |jq '.groups[] |select (.name="HQ Server") | .id'`

SERVER_LIST=`curl -basic -u admin:${env_HQADMIN_PASSWORD} -H 'Content-Type: application/json' -H 'Accept: application/json' http://${env_HQSERVER_MAPPED_HOSTNAME}:${env_HQSERVER_MAPPED_HTTP_PORT}/api/informix/groups/${GROUP_ID} 2>/dev/null `

   if [[ ! -z ${SERVER_LIST} ]] 
   then
      FOUND_SERVER_ID=`echo $SERVER_LIST| jq '.servers[] | select(.alias=="'$SERVNAME'") | .id '`
      if [[ ! -z $FOUND_SERVER_ID ]]
      then
         break 
      fi
   fi
   sleep $SLEEP 

done

HQLOG ">>>        HQAGENT: HQSERVER ($SERVNAME) GROUP ID: ${GROUP_ID}" 
HQLOG ">>>        HQAGENT: HQSERVER ($SERVNAME) ID: ${FOUND_SERVER_ID}" 
echo $FOUND_SERVER_ID
}


##
## Get Server list, find server id, pass in string
get_server_id() {
SERVNAME=$1 
for i in $(eval echo "{1..2}")
do
HQLOG ">>>        HQAGENT: GET server($SERVNAME) ID ATTEMPT: $i" 

SERVER_LIST=`curl -basic -u admin:${env_HQADMIN_PASSWORD} -H 'Content-Type: application/json' -H 'Accept: application/json' http://${env_HQSERVER_MAPPED_HOSTNAME}:${env_HQSERVER_MAPPED_HTTP_PORT}/api/informix/groups/0 2>/dev/null `

   if [[ ! -z ${SERVER_LIST} ]] 
   then
      FOUND_SERVER_ID=`echo $SERVER_LIST| jq '.servers[] | select(.alias=="'$SERVNAME'") | .id '`
      if [[ ! -z $FOUND_SERVER_ID ]]
      then
         break 
      fi
   fi
   sleep 1
done

HQLOG ">>>        HQAGENT: SERVER ($SERVNAME) ID: ${FOUND_SERVER_ID}" 
echo $FOUND_SERVER_ID
}



## Register hqserver id, as storage database server 
## and hqmon as the database 
set_server_storage() {
for i in $(eval echo "{1..$ITER}")
do
REGISTER=`curl -X PUT -basic -u admin:${env_HQADMIN_PASSWORD} -H 'Content-Type: application/json' -H 'Accept: application/json' http://${env_HQSERVER_MAPPED_HOSTNAME}:${env_HQSERVER_MAPPED_HTTP_PORT}/api/informix/${HQAGENT_ID}/agent --data-binary "{'config': { 'repositoryServerId' : ${HQSERVER_ID}, 'database' : 'hqmon' }}" 2>/dev/null`


   if [[ ! -z ${REGISTER} ]] 
   then
   break
   fi
   sleep $SLEEP 

done

#sudo echo "HQAGENT: REGISTER Storage:  $REGISTER" >> $HQLOG
HQLOG ">>>        HQAGENT: REGISTER Storage: $REGISTER" 
}


### main

waitForHQSERVER

HQSERVER_ID=$(get_hqserver_id ${env_HQSERVER_MAPPED_HOSTNAME}) 
if [[ `echo ${env_HQSERVER}|tr /a-z/ /A-Z/` == "START" ]]  
then
   HQAGENT_ID=$HQSERVER_ID
else
   HQLOG ">>>        HQGENT: register hqagent with hqserver"
   # See if Agent already registered
   tmp_ID=$(get_server_id ${env_MAPPED_HOSTNAME})
   if [[ $tmp_ID ]] 
   then
      HQLOG ">>>        HQAGENT ${env_MAPPED_HOSTNAME} Already Registered"
   else
      HQLOG ">>>        HQAGENT ${env_MAPPED_HOSTNAME} Registering Agent"
      register_hqagent_with_hqserver
   fi
fi

if [[ $tmp_ID ]] 
then
   HQLOG ">>>        HQAGENT ${env_MAPPED_HOSTNAME} Properties file should exist"
else
   HQLOG ">>>        HQAGENT ${env_MAPPED_HOSTNAME} Creating Properties File"
   create_properties_file
fi


if [[ `echo ${env_HQAGENT}|tr /a-z/ /A-Z/` = "START" ]]  
then
   HQLOG ">>>        HQAGENT: hqagent = start" 
   start_hqagent
   if [[ $tmp_ID ]] 
   then
      HQLOG ">>>        HQAGENT ${env_MAPPED_HOSTNAME} Server Storage Already Registered"
   else
      HQLOG ">>>        HQAGENT ${env_MAPPED_HOSTNAME} Registering Agent Server Storage "
      set_server_storage
   fi
fi
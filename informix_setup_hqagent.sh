#!/bin/bash
#
#  name:        informix_setup_hqagent.sh:
#  description: Setup HQ server on docker image 
#  Called by:   informix_entry.sh


PROP_PATH=$INFORMIXDIR/hq/agent.properties
HQLOG=$INFORMIXDIR/hq/hq.log

SLEEP=60
ITER=10

HQLOG ">>>  HQAGENT: " 
HQLOG ">>>     HQADMIN_PASSWORD: ${env_HQADMIN_PASSWORD}" 
HQLOG ">>>     INFORMIX_PASSWORD: ${env_INFORMIX_PASSWORD}" 
HQLOG ">>>     HOSTNAME : $HOSTNAME" 
HQLOG ">>>     HQSERVER_MAPPED_HOSTNAME: ${env_HQSERVER_MAPPED_HOSTNAME}" 
HQLOG ">>>     HQSERVER_MAPPED_HTTP_PORT: ${env_HQSERVER_MAPPED_HTTP_PORT}" 
HQLOG ">>>     MAPPED_HOSTNAME: ${env_MAPPED_HOSTNAME}"
HQLOG ">>>     HQSERVER : $env_HQSERVER" 




uHQSERVER_ID=0
uHQAGENT_ID=0

###
### Register Server attempt(s) 
###
register_server() {

HQLOG ">>>        REGISTERING HQAGENT with HQSERVER" 
HQLOG ">>>           REGISTER ATTEMPT $i" 

for i in $(eval echo "{1..$ITER}")
do

SERVER_ID=`curl -basic -u admin:${env_HQADMIN_PASSWORD} -H 'Content-Type: application/json' -H 'Accept: application/json' http://${env_HQSERVER_MAPPED_HOSTNAME}:${env_HQSERVER_MAPPED_HTTP_PORT}/api/informix --data-binary "{'groupId': 0, 'alias': '${env_MAPPED_HOSTNAME}', 'hostname': '${env_MAPPED_HOSTNAME}', 'port': ${env_MAPPED_SQLI_PORT}, 'monitorUser': 'informix', 'monitorPassword': '${env_INFORMIX_PASSWORD}', 'adminUser': 'informix', 'adminPassword': '${env_INFORMIX_PASSWORD}'}" 2>/dev/null | jq '.id'`

HQLOG ">>>           REGISTER ATTEMPT $i" 
   if [[ ! -z ${SERVER_ID} ]] 
   then
   break
   fi
   sleep $SLEEP 

done
uHQAGENT_ID=$SERVER_ID
HQLOG ">>>     HQAGENT SERVER_ID $uHQAGENT_ID" 
}


###
### Create Properties file
###
create_properties_file() {
sudo echo "" > $PROP_PATH
sudo chmod 644 $PROP_PATH 
sudo echo "informixServer.id=$uHQAGENT_ID" >> $PROP_PATH
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
get_server_id() {
SERVNAME=$1 
for i in $(eval echo "{1..$ITER}")
do
HQLOG "GET server($SERVNAME) ID ATTEMPT: $i" 

SERVER_LIST=`curl -basic -u admin:${env_HQADMIN_PASSWORD} -H 'Content-Type: application/json' -H 'Accept: application/json' http://${env_HQSERVER_MAPPED_HOSTNAME}:${env_HQSERVER_MAPPED_HTTP_PORT}/api/informix/groups/0 2>/dev/null `

   if [[ ! -z ${SERVER_LIST} ]] 
   then
      SERVER_ID=`echo $SERVER_LIST| jq '.servers[] | select(.alias=="'$SERVNAME'") | .id '`
      if [[ ! -z $SERVER_ID ]]
      then
         break 
      fi
   fi
   sleep $SLEEP 

done

HQLOG ">>>        HQSERVER ($SERVNAME) ID: ${SERVER_ID}" 
echo $SERVER_ID
}



## Register hqserver id, as storage database server 
## and hqmon as the database 
set_server_storage() {
for i in $(eval echo "{1..$ITER}")
do
REGISTER=`curl -X PUT -basic -u admin:${env_HQADMIN_PASSWORD} -H 'Content-Type: application/json' -H 'Accept: application/json' http://${env_HQSERVER_MAPPED_HOSTNAME}:${env_HQSERVER_MAPPED_HTTP_PORT}/api/informix/${uHQAGENT_ID}/agent --data-binary "{'config': { 'repositoryServerId' : ${uHQSERVER_ID}, 'database' : 'hqmon' }}" 2>/dev/null`


   if [[ ! -z ${REGISTER} ]] 
   then
   break
   fi
   sleep $SLEEP 

done

sudo echo "REGISTER Storage:  $REGISTER" >> $HQLOG
}



#uHQSERVER_ID=$(get_server_id "hqserver") 
uHQSERVER_ID=$(get_server_id ${env_HQSERVER_MAPPED_HOSTNAME}) 
register_server
create_properties_file

if [[ `echo ${env_HQAGENT}|tr /a-z/ /A-Z/` = "START" ]]  
then
   start_hqagent
   #get_hqserver_id
   #get_server_id hqserver
   set_server_storage
fi
#!/bin/bash
#
#  name:        informix_setup_hqserver.sh:
#  description: Setup HQ server on docker image 
#  Called by:   informix_entry.sh

PROP_PATH=$INFORMIXDIR/hq/informixhq-server.properties
HQLOG=$INFORMIXDIR/hq/hq.log

SLEEP=15
ITER=40

HQLOG ">>>  HQSERVER: " 
HQLOG ">>>     HQSERVER: HQADMIN_PASSWORD: ${env_HQADMIN_PASSWORD}" 
HQLOG ">>>     HQSERVER: INFORMIX_PASSWORD: ${env_INFORMIX_PASSWORD}" 
HQLOG ">>>     HQSERVER: HQSERVER_MAPPED_HOSTNAME: ${env_HQSERVER_MAPPED_HOSTNAME}" 
HQLOG ">>>     HQSERVER: HQSERVER_MAPPED_HTTP_PORT: ${env_HQSERVER_MAPPED_HTTP_PORT}" 
HQLOG ">>>     HQSERVER: MAPPED_HOSTNAME: ${env_MAPPED_HOSTNAME}" 

dbaccess - <<!
create database if not exists hqmon;
!

sudo echo "" > $PROP_PATH
sudo chmod 644 $PROP_PATH 
sudo echo "initialAdminPassword=${env_HQADMIN_PASSWORD}" >> $PROP_PATH
sudo echo "httpPort=8080" >> $PROP_PATH

cat $PROP_PATH >> $HQLOG

cd $INFORMIXDIR/hq
java -jar $INFORMIXDIR/hq/informixhq-server.jar >> $HQLOG & 

sleep $SLEEP

waitForHQSERVER

HQLOG ">>>     HQSERVER: Creating HQ Server Group " N

for i in $(eval echo "{1..$ITER}") 
do
GROUP_ID=`curl -basic -u admin:${env_HQADMIN_PASSWORD} -H 'Content-Type: application/json' -H 'Accept: application/json' http://${env_HQSERVER_MAPPED_HOSTNAME}:${env_HQSERVER_MAPPED_HTTP_PORT}/api/informix/groups/0 --data-binary "{'name': 'HQ Server'}" 2>/dev/null | jq '.id'`


HQLOG ">>>        HQSERVER: CREATE ATTEMPT $i" N
   if [[ ! -z ${GROUP_ID} ]] 
   then
   break
   fi
   sleep $SLEEP 
done
HQLOG ">>>           HQSERVER: HQSERVER GROUP Created - GROUP ID: $GROUP_ID" N 


HQLOG ">>>     HQSERVER: REGISTERING HQ Server " N

for i in $(eval echo "{1..$ITER}") 
do
SERVER_ID=`curl -basic -u admin:${env_HQADMIN_PASSWORD} -H 'Content-Type: application/json' -H 'Accept: application/json' http://${env_HQSERVER_MAPPED_HOSTNAME}:${env_HQSERVER_MAPPED_HTTP_PORT}/api/informix --data-binary "{'groupId': ${GROUP_ID}, 'alias': '${env_MAPPED_HOSTNAME}', 'hostname': '${env_MAPPED_HOSTNAME}', 'port': ${env_MAPPED_SQLI_PORT}, 'monitorUser': 'informix', 'monitorPassword': '${env_INFORMIX_PASSWORD}', 'adminUser': 'informix', 'adminPassword': '${env_INFORMIX_PASSWORD}'}" 2>/dev/null | jq '.id'`


HQLOG ">>>        HQSERVER: REGISTER ATTEMPT $i" N
   if [[ ! -z ${SERVER_ID} ]] 
   then
   break
   fi
   sleep $SLEEP 
done
HQLOG ">>>           HQSERVER: HQSERVER REGISTERED - SERVER_ID: $SERVER_ID" N 



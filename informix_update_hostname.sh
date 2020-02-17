#!/bin/bash
#
#  name:        informix_update_hostname.sh:
#  description: Update the hostname in various file(s) in the docker image 
#  Called by:   informix_entry.sh


### Update HOSTNAME in SQLHOST file
### SQLHOSTS file contains the previous HOSTNAME value
###
MSGLOG ">>>    Updating HOSTNAME in $INFORMIXSQLHOSTS"
old_hostname=`grep "HOST NAME" $INFORMIXSQLHOSTS |awk '{print $5}' ` 
SED "s/${old_hostname}/${HOSTNAME}/g" $INFORMIXSQLHOSTS


### Update HOSTNAME in WL config file
###
REST_PROP=$INFORMIX_CONFIG_DIR/$REST_PROP_FILENAME
if ( ifFileExists $REST_PROP )
then
   MSGLOG ">>>    Updating HOSTNAME in $REST_PROP"
   old_hostname=`grep "HOST NAME" $REST_PROP|awk '{print $5}' ` 
   SED "s/${old_hostname}/${HOSTNAME}/g" $REST_PROP
fi

MONGO_PROP=$INFORMIX_CONFIG_DIR/$MONGO_PROP_FILENAME
if ( ifFileExists $MONGO_PROP )
then
   MSGLOG ">>>    Updating HOSTNAME in $MONGO_PROP"
   old_hostname=`grep "HOST NAME" $MONGO_PROP|awk '{print $5}' ` 
   SED "s/${old_hostname}/${HOSTNAME}/g" $MONGO_PROP
fi

MQTT_PROP=$INFORMIX_CONFIG_DIR/$MQTT_PROP_FILENAME
if ( ifFileExists $MQTT_PROP )
then
   MSGLOG ">>>    Updating HOSTNAME in $MQTT_PROP"
   old_hostname=`grep "HOST NAME" $MQTT_PROP|awk '{print $5}' ` 
   SED "s/${old_hostname}/${HOSTNAME}/g" $MQTT_PROP
fi

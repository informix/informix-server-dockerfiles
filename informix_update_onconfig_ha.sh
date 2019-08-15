#!/bin/bash
#
#  name:        informix_udpate_onconfig_ha.sh:
#  description: Make modifications to onconfig file 
#  Called by:   informix_entry.sh

AUTHFILE=authfile
AUTHFILE_PATH=$INFORMIX_CONFIG_DIR/$AUTHFILE


## Update $ONCONFIG
##
SED "s#^ENABLE_SNAPSHOT_COPY.*#ENABLE_SNAPSHOT_COPY 1#g"   $INFORMIXDIR/etc/$ONCONFIG 
SED "s#^CDR_AUTO_DISCOVER.*#CDR_AUTO_DISCOVER 1#g"         $INFORMIXDIR/etc/$ONCONFIG 
SED "s#^REMOTE_SERVER_CFG.*#REMOTE_SERVER_CFG authfile#g"  $INFORMIXDIR/etc/$ONCONFIG 


## Create authfile 
##
touch $AUTHFILE
sudo chown informix:informix $AUTHFILE
chmod 755 $AUTHFILE
ln -s $AUTHFILE_PATH $INFORMIXDIR/etc/$AUTHFILE
echo "pri" >> $AUTHFILE_PATH
echo "sec" >> $AUTHFILE_PATH



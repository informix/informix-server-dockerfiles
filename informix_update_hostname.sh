#!/bin/bash
#
#  name:        informix_update_hostname.sh:
#  description: Update the hostname in various file(s) in the docker image 
#  Called by:   informix_entry.sh


### Update HOSTNAME in SQLHOST file
### SQLHOSTS file contains the previous HOSTNAME value
###
old_hostname=`grep "HOST NAME" $INFORMIXSQLHOSTS |awk '{print $5}' ` 
#sed -i "s/${old_hostname}/${HOSTNAME}/g" $INFORMIXSQLHOSTS
sed -i "s/${old_hostname}/${HOSTNAME}/g" $INFORMIX_CONFIG_DIR/sqlhosts


### Update HOSTNAME in WL config file
###
#sed -i "s/${old_hostname}/${HOSTNAME}/g" $INFORMIXSQLHOSTS

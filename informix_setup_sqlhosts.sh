#!/bin/bash
#
#  name:        informix_setup_sqlhosts.sh:
#  description: Setup the sqlhosts file in the docker image 
#  Called by:   informix_entry.sh

if [ ! -z $env_SQLHOSTS_FILE ]
then
SQLHOSTS_PATH=$INFORMIX_CONFIG_DIR/$env_SQLHOSTS_FILE
else
SQLHOSTS_PATH=$INFORMIX_CONFIG_DIR/sqlhosts
fi

#if [ -e $INFORMIX_DATA_DIR/sqlhosts ]
if [ ! -z $env_SQLHOSTS_FILE ]
then
   MSGLOG ">>>      Using sqlhosts supplied by user" N
   #mv $INFORMIX_DATA_DIR/sqlhosts $SQLHOSTS_PATH
   sudo chown informix:informix $SQLHOSTS_PATH
   sudo chmod 744 $SQLHOSTS_PATH
else
   sudo echo "############################################################" > ${SQLHOSTS_PATH}
   sudo echo "### DO NOT MODIFY THIS COMMENT SECTION " >> ${SQLHOSTS_PATH}
   sudo echo "### HOST NAME = ${HOSTNAME} " >> ${SQLHOSTS_PATH}
   sudo echo "############################################################" >> ${SQLHOSTS_PATH}
   sudo echo "${INFORMIXSERVER}        onsoctcp        ${HOSTNAME}         9088" >> "${SQLHOSTS_PATH}"
   sudo echo "${INFORMIXSERVER}_dr     drsoctcp        ${HOSTNAME}         9089" >> "${SQLHOSTS_PATH}"
   sudo chown informix:informix $SQLHOSTS_PATH
   sudo chmod 744 $SQLHOSTS_PATH
fi



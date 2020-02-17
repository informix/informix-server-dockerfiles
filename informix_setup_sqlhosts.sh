#!/bin/bash
#
#  name:        informix_setup_sqlhosts.sh:
#  description: Setup the sqlhosts file in the docker image 
#  Called by:   informix_entry.sh

TRUE=1
FALSE=0

if ( ifFileExists $INFORMIX_CONFIG_DIR/sqlhosts )
then
      MSGLOG ">>>      DEBUG: FILEEXISTS=1" N
   FILEEXISTS=1
else
      MSGLOG ">>>      DEBUG: FILEEXISTS=0" N
   FILEEXISTS=0
fi

if ( $(isEnvSet $env_SQLHOSTS_FILE) ) 
then
   MSGLOG ">>>      Using sqlhosts supplied by user" N
   if [[ $env_STORAGE == "LOCAL" ]]
   then
      cp $INFORMIX_CONFIG_DIR/$env_SQLHOSTS_FILE $INFORMIXSQLHOSTS
   else
      ln -s $INFORMIX_CONFIG_DIR/$env_SQLHOSTS_FILE $INFORMIXSQLHOSTS
   fi
else
   MSGLOG ">>>      Creating DEFAULT sqlhosts " N
   if [[ $env_STORAGE == "LOCAL" ]]
   then
      touch $INFORMIXSQLHOSTS
   else
      MSGLOG ">>>      touch $INFORMIX_CONFIG_DIR/sqlhosts" N
      touch $INFORMIX_CONFIG_DIR/sqlhosts
      ln -s $INFORMIX_CONFIG_DIR/sqlhosts $INFORMIXSQLHOSTS
   fi
fi


if [[ -z $env_SQLHOSTS_FILE && $FILEEXISTS -eq $FALSE ]]
then
   RUNAS root "cat /dev/null > $INFORMIXSQLHOSTS "
   RUNAS root "echo '############################################################' >> ${INFORMIXSQLHOSTS}"
   RUNAS root "echo '### DO NOT MODIFY THIS COMMENT SECTION '>> ${INFORMIXSQLHOSTS}"
   RUNAS root "echo '### HOST NAME = ${HOSTNAME} ' >> ${INFORMIXSQLHOSTS}"
   RUNAS root "echo '############################################################' >> ${INFORMIXSQLHOSTS}"
   RUNAS root "echo '${INFORMIXSERVER}        onsoctcp        *${HOSTNAME}         9088' >> ${INFORMIXSQLHOSTS}"
   RUNAS root "echo '${INFORMIXSERVER}_dr     drsoctcp        *${HOSTNAME}         9089' >> ${INFORMIXSQLHOSTS}"
else
      MSGLOG ">>>      Using Exiting SQLHOSTS $INFORMIX_CONFIG_DIR/sqlhosts" N
fi

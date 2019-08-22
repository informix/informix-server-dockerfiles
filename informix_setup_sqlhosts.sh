#!/bin/bash
#
#  name:        informix_setup_sqlhosts.sh:
#  description: Setup the sqlhosts file in the docker image 
#  Called by:   informix_entry.sh


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

#sudo touch ${SQLHOSTS_PATH}
#sudo chown informix:informix $SQLHOSTS_PATH
#sudo chmod 744 $SQLHOSTS_PATH
#[[ $env_STORAGE != "LOCAL" ]] && ln -s $SQLHOSTS_PATH $INFORMIXSQLHOSTS




if [ -z $env_SQLHOSTS_FILE ]
then
   sudo echo "############################################################" >> ${INFORMIXSQLHOSTS}
   sudo echo "### DO NOT MODIFY THIS COMMENT SECTION " >> ${INFORMIXSQLHOSTS}
   sudo echo "### HOST NAME = ${HOSTNAME} " >> ${INFORMIXSQLHOSTS}
   sudo echo "############################################################" >> ${INFORMIXSQLHOSTS}
   sudo echo "${INFORMIXSERVER}        onsoctcp        ${HOSTNAME}         9088" >> "${INFORMIXSQLHOSTS}"
   sudo echo "${INFORMIXSERVER}_dr     drsoctcp        ${HOSTNAME}         9089" >> "${INFORMIXSQLHOSTS}"
   #sudo echo "${INFORMIXSERVER}_dr     drsoctcp        ${HOSTNAME}         9089" >> "${SQLHOSTS_PATH}"
fi

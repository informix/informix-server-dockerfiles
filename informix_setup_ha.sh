#!/bin/bash
#
#  name:        informix_setup_ha.sh:
#  description: Setup HA server on docker image 
#  Called by:   informix_entry.sh




if [[ $env_HA = "PRI" ]]
then
   MSGLOG ">>>  HA_PRI:  Setting up PRIMARY"
   touch $INFORMIXDIR/etc/trusted.hosts
   chmod 640 $INFORMIXDIR/etc/trusted.hosts
   onmode -wf REMOTE_SERVER_CFG=trusted.hosts
   onmode -wf CDR_AUTO_DISCOVER=1
   onmode -wf TEMPTAB_NOLOG=1
   onmode -wf ENABLE_SNAPSHOT_COPY=1
   onmode -wf LOG_INDEX_BUILDS=1
   dbaccess sysadmin <<!
   execute function sysadmin:admin ('cdr add trustedhost', '${HOSTNAME} informix')
!

fi

if [[ $env_HA = "SEC" || $env_HA = "RSS" ]]
then
   DOMAIN_NAME=$(getDomain ${env_HA_PRIMARY})
   MSGLOG ">>> HA:  DOMAIN: $DOMAIN_NAME"
   [[ $env_HA = "SEC" ]] && HA_TYPE="HDR" || HA_TYPE="RSS"

   MSGLOG ">>>  HA_SEC/RSS:  Setting up SEC/RSS: $HA_TYPE"
   waitForHAWL
   if ( $(isEnvSet $env_HA_PRIMARY) )
   then
      curl -G http://${env_HA_PRIMARY}:27018/sysadmin/%24cmd --data-urlencode "query={'runFunction':'admin', 'arguments':['cdr add trustedhost','${HOSTNAME} informix, ${HOSTNAME}.${DOMAIN_NAME} informix, ${env_HA_PRIMARY}.${DOMAIN_NAME} informix']}"

      curl -G http://${env_HA_PRIMARY}:27018/sysadmin/system.sql?query="{'$SQL':'execute function admin ('cdr add trustedhost')        '" 

      onmode -ky
      rm $INFORMIX_DATA_DIR/spaces/root*
      MSGLOG ">>> HA: HA_TYPE: ${HA_TYPE}"
      MSGLOG ">>> HA: HA: ${env_HA}"
      MSGLOG ">>> HA: HA_PRIMARY: ${env_HA_PRIMARY}"
      MSGLOG ">>> HA: HA_PRI_DBSERVERNAME: ${env_HA_PRI_DBSERVERNAME}"
      while true 
      do
         echo "Running ifxclone"
         ifxclone --source=${env_HA_PRI_DBSERVERNAME} --sourceIP=${env_HA_PRIMARY} --sourcePort=9088  --target=${env_DBSERVERNAME} --targetIP=${HOSTNAME} --targetPort=9088  --trusted  --createchunkfile  --disposition=${HA_TYPE}  --autoconf 
         rc=$?
         if [[ $rc == "0" ]]
         then
            echo "ifxclone SUCCESS"
            break
         else
            sleep 5
         fi
      done
   else
      MSGLOG ">>>  ERROR:  HA $env_HA is set but HA_PRIMARY is not set"
   fi
fi


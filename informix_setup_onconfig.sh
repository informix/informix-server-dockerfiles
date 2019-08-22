#!/bin/bash
#
#  name:        informix_setup_onconfig.sh:
#  description: Setup the onconfig file 
#  Called by:   informix_entry.sh


E_TAPEDEV="/dev/null"
E_LTAPEDEV="/dev/null"
E_LOCKMODE="row"
E_SBSPACE="sbspace"
E_ROOTPATH="$INFORMIX_DATA_DIR/spaces/rootdbs.000"
E_CONSOLE="$INFORMIX_DATA_DIR/logs/console.log"
E_MSGPATH="$INFORMIX_DATA_DIR/logs/online.log"
( $(isEnvSet $env_DBSERVERNAME) ) && E_DBSERVERNAME=$env_DBSERVERNAME || E_DBSERVERNAME="informix"

if ( $(isEnvSet $env_ONCONFIG_FILE) ) 
then
   MSGLOG ">>>        Using onconfig supplied by user" N
   if [[ $env_STORAGE == "LOCAL" ]]
   then
      cp $INFORMIX_CONFIG_DIR/$env_ONCONFIG_FILE $INFORMIXDIR/etc/$ONCONFIG
      #ONCONFIG_PATH=$INFORMIXDIR/etc/$ONCONFIG
   else
      ln -s $INFORMIX_CONFIG_DIR/$env_ONCONFIG_FILE $INFORMIXDIR/etc/$ONCONFIG
      #ONCONFIG_PATH=$INFORMIX_CONFIG_DIR/$env_ONCONFIG_FILE
   fi    
else
   MSGLOG ">>>        Creating DEFAULT onconfig" N
   if [[ $env_STORAGE == "LOCAL" ]]
   then
      cp $INFORMIXDIR/etc/onconfig.std $INFORMIXDIR/etc/$ONCONFIG
   else
      MSGLOG ">>>        Copy onconfig.std  $INFORMIX_CONFIG_DIR/$ONCONFIG" N
      cp $INFORMIXDIR/etc/onconfig.std $INFORMIX_CONFIG_DIR/$ONCONFIG
      ln -s $INFORMIX_CONFIG_DIR/$ONCONFIG $INFORMIXDIR/etc/$ONCONFIG
   fi
fi

#sudo chown informix:informix "${ONCONFIG_PATH}"
#sudo chmod 660 "${ONCONFIG_PATH}"


SED "s#^ROOTPATH .*#ROOTPATH $E_ROOTPATH#g"  $INFORMIXDIR/etc/$ONCONFIG        
SED "s#^CONSOLE .*#CONSOLE $E_CONSOLE#g"     $INFORMIXDIR/etc/$ONCONFIG 
SED "s#^MSGPATH .*#MSGPATH $E_MSGPATH#g"     $INFORMIXDIR/etc/$ONCONFIG 
SED "s#^TAPEDEV .*#TAPEDEV   $E_TAPEDEV#g"                $INFORMIXDIR/etc/$ONCONFIG 
SED "s#^LTAPEDEV .*#LTAPEDEV $E_LTAPEDEV#g"               $INFORMIXDIR/etc/$ONCONFIG 
SED "s#^SBSPACENAME.*#SBSPACENAME $E_SBSPACE#g"           $INFORMIXDIR/etc/$ONCONFIG 
SED "s#^DBSERVERNAME.*#DBSERVERNAME $E_DBSERVERNAME#g"    $INFORMIXDIR/etc/$ONCONFIG 
SED "s#^DEF_TABLE_LOCKMODE page#DEF_TABLE_LOCKMODE $E_LOCKMODE#g" $INFORMIXDIR/etc/$ONCONFIG 


[[ $env_PORT_DRDA == "ON" ]] && SED "s#^DBSERVERALIASES.*#DBSERVERALIASES ${E_DBSERVERNAME}_dr#g" $INFORMIXDIR/etc/$ONCONFIG 
( $(isEnvSet $env_LICENSE_SERVER) ) && SED "s#^LICENSE_SERVER.*#LICENSE_SERVER $env_LICENSE_SERVER#g"      $INFORMIXDIR/etc/$ONCONFIG 

#if [[ $env_PORT_DRDA == "ON" ]]
#then
#   MSGLOG ">>>        Setting dbserveraliases" N 
#   SED "s#^DBSERVERALIASES.*#DBSERVERALIASES ${E_DBSERVERNAME}_dr#g" $INFORMIXDIR/etc/$ONCONFIG 
#fi


#if [[ ! -z $env_LICENSE_SERVER ]]
#then
#   SED "s#^LICENSE_SERVER.*#LICENSE_SERVER $env_LICENSE_SERVER#g"      $INFORMIXDIR/etc/$ONCONFIG 
#fi


if [[ $env_SIZE = "SMALL" ]]
then
  MSGLOG ">>>        Setting up Small System" n
  . $SCRIPTS/informix_update_onconfig.sh $SCRIPTS/informix_config.small
elif [[ $env_SIZE = "MEDIUM" ]]
then
  MSGLOG ">>>        Setting up Medium System" n
  . $SCRIPTS/informix_update_onconfig.sh $SCRIPTS/informix_config.medium
elif [[ $env_SIZE = "LARGE" ]]
then
  MSGLOG ">>>        Setting up Large System" n
  . $SCRIPTS/informix_update_onconfig.sh $ONCONFIG_PATH $SCRIPTS/informix_config.large
else
   ### env_SIZE not set or set to a number (Percentage) 
   . $SCRIPTS/informix_calculate_onconfig.sh $INFORMIXDIR/etc/$ONCONFIG  
fi


if [[ ! -z $env_HA ]] 
then
   MSGLOG ">>>        Updating ONCONFIG for HA " N
   . $SCRIPTS/informix_update_onconfig_ha.sh  
fi
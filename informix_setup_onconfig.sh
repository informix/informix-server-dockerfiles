#!/bin/bash
#
#  name:        informix_setup_onconfig.sh:
#  description: Setup the onconfig file 
#  Called by:   informix_entry.sh


if [[ ! -z $env_ONCONFIG_FILE ]]
then
   ONCONFIG_PATH=$INFORMIX_CONFIG_DIR/$env_ONCONFIG_FILE
else
   ONCONFIG_PATH=$INFORMIX_CONFIG_DIR/$ONCONFIG
fi


if [ ! -z $env_ONCONFIG_FILE ]
then
   MSGLOG ">>>        Using $ONCONFIG supplied by user" N
   #mv $INFORMIX_DATA_DIR/$ONCONFIG $ONCONFIG_PATH
   sudo chown informix:informix $ONCONFIG_PATH
   sudo chmod 660 $ONCONFIG_PATH
else
   MSGLOG ">>>        Using default $ONCONFIG" N
   cp $INFORMIXDIR/etc/onconfig.std $ONCONFIG_PATH
fi

E_ROOTPATH="$INFORMIX_DATA_DIR/spaces/rootdbs.000"
E_CONSOLE="$INFORMIX_DATA_DIR/logs/console.log"
E_MSGPATH="$INFORMIX_DATA_DIR/logs/online.log"
E_DBSERVERNAME="informix"
E_TAPEDEV="/dev/null"
E_LTAPEDEV="/dev/null"
E_LOCKMODE="row"
E_SBSPACE="sbspace"

sed -i "s#^ROOTPATH .*#ROOTPATH $E_ROOTPATH#g"               "${ONCONFIG_PATH}"
sed -i "s#^CONSOLE .*#CONSOLE $E_CONSOLE#g"                  "${ONCONFIG_PATH}"
sed -i "s#^MSGPATH .*#MSGPATH $E_MSGPATH#g"                  "${ONCONFIG_PATH}"
sed -i "s#^DBSERVERNAME.*#DBSERVERNAME $E_DBSERVERNAME#g"    "${ONCONFIG_PATH}"

if [[ $env_PORT_DRDA == "ON" ]]
then
sed -i "s#^DBSERVERALIASES.*#DBSERVERALIASES ${E_DBSERVERNAME}_dr#g" "${ONCONFIG_PATH}" 
   MSGLOG ">>>        Setting dbserveraliases" N 
fi

sed -i "s#^TAPEDEV .*#TAPEDEV   $E_TAPEDEV#g"                "${ONCONFIG_PATH}"
sed -i "s#^LTAPEDEV .*#LTAPEDEV $E_LTAPEDEV#g"               "${ONCONFIG_PATH}"
sed -i "s#^DEF_TABLE_LOCKMODE page#DEF_TABLE_LOCKMODE $E_LOCKMODE#g" "${ONCONFIG_PATH}"
sed -i "s#^SBSPACENAME.*#SBSPACENAME $E_SBSPACE#g"               "${ONCONFIG_PATH}"

if [[ ! -z $env_LICENSE_SERVER ]]
then
   sed -i "s#^LICENSE_SERVER.*#LICENSE_SERVER $env_LICENSE_SERVER#g"               "${ONCONFIG_PATH}"
fi

sudo chown informix:informix "${ONCONFIG_PATH}"
sudo chmod 660 "${ONCONFIG_PATH}"


# if [[ -z ${env_TYPE} ]]
# then
#     if [[ $env_SIZE = "SMALL" ]]
#     then
#     MSGLOG ">>>        Setting up Small System" n
#     . $SCRIPTS/informix_update_onconfig.sh $ONCONFIG_PATH $SCRIPTS/informix_config.small
#     fi

#     if [[ $env_SIZE = "MEDIUM" ]]
#     then
#     MSGLOG ">>>        Setting up Medium System" N
#     . $SCRIPTS/informix_update_onconfig.sh $ONCONFIG_PATH $SCRIPTS/informix_config.medium
#     fi

#     if [[ $env_SIZE = "LARGE" ]]
#     then
#     MSGLOG ">>>        Setting up Large System" N
#     . $SCRIPTS/informix_update_onconfig.sh $ONCONFIG_PATH $SCRIPTS/informix_config.large
#     fi

#     if [[ $env_SIZE = "CUSTOM" ]]
#     then
#     MSGLOG ">>>        Setting up Custom System" N
#     . $SCRIPTS/informix_update_onconfig.sh $ONCONFIG_PATH $INFORMIX_DATA_DIR/informix_config.custom
#     fi

#     if [[ -z ${env_SIZE} ]]
#     then
#     MSGLOG ">>>        Setting up OLTP/Default system" N
#     . $SCRIPTS/informix_calculate_onconfig.sh $ONCONFIG_PATH oltp 
#     fi
# else
#     if [[ $env_TYPE = "DSS" ]]
#     then
#     MSGLOG ">>>        Setting up DSS system" N
#     . $SCRIPTS/informix_calculate_onconfig.sh $ONCONFIG_PATH dss 
#     fi

#     if [[ $env_TYPE = "OLTP" ]]
#     then
#     MSGLOG ">>>        Setting up OLTP system" N
#     . $SCRIPTS/informix_calculate_onconfig.sh $ONCONFIG_PATH oltp 
#     fi

#     if [[ $env_TYPE = "HYBRID" ]]
#     then
#     MSGLOG ">>>        Setting up HYBRID system" N
#     . $SCRIPTS/informix_calculate_onconfig.sh $ONCONFIG_PATH hybrid 
#     fi
# fi

###
### Call informix_calculate_onconfig to adjust onconfig shm parameters based on
### $env_TYPE  Buffers, SHMVIRT, NONPDQ  
###      OLTP=80,19,1
###      DSS=20,75,5
###      HYBRID=50,49,1

if [[ $env_SIZE = "SMALL" ]]
then
  MSGLOG ">>>        Setting up Small System" n
  . $SCRIPTS/informix_update_onconfig.sh $ONCONFIG_PATH $SCRIPTS/informix_config.small
elif [[ $env_SIZE = "MEDIUM" ]]
then
  MSGLOG ">>>        Setting up Medium System" n
  . $SCRIPTS/informix_update_onconfig.sh $ONCONFIG_PATH $SCRIPTS/informix_config.medium
elif [[ $env_SIZE = "LARGE" ]]
then
  MSGLOG ">>>        Setting up Large System" n
  . $SCRIPTS/informix_update_onconfig.sh $ONCONFIG_PATH $SCRIPTS/informix_config.large
else
   ### env_SIZE not set or set to a number (Percentage) 
   . $SCRIPTS/informix_calculate_onconfig.sh $ONCONFIG_PATH  
fi


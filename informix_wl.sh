#!/bin/bash
#
#  name:        informix_wl.sh:
#  description: Starts WL in Docker container
#

OPT=$1
TRUE=1
FALSE=0


main()
{
###
###  Setup environment
###
. /usr/local/bin/informix_inf.env

dt=`date`
MSGLOG ">>>    Starting WL ($dt) ... $OPT" N

if [[ $env_PORT_MONGO == "ON" ]]
then
   setupMongoProp
fi
if [[ $env_PORT_REST == "ON" ]]
then
   setupRestProp
fi
if [[ $env_PORT_MQTT == "ON" ]]
then
   setupMqttProp
fi

startWL $OPT


if [[ $env_PORT_MONGO == "ON" ]]
then
   checkMongoRunning
fi
if [[ $env_PORT_REST == "ON" ]]
then
   checkRestRunning
fi
if [[ $env_PORT_MQTT == "ON" ]]
then
   checkMqttRunning
fi



MSGLOG ">>>    [COMPLETED]" N

}


#####################################################################
### FUNCTION DEFINITIONS
#####################################################################

SUCCESS=0
FAILURE=1

TCP_PORT=9088
MONGO_PORT=27017
REST_PORT=27018
MQTT_PORT=27883

MONGO_PROP=$INFORMIXDIR/etc/$MONGO_PROP_FILENAME
REST_PROP=$INFORMIXDIR/etc/$REST_PROP_FILENAME
MQTT_PROP=$INFORMIXDIR/etc/$MQTT_PROP_FILENAME

WL_LOG=$INFORMIXDIR/etc/json_listener_logging.log

###
### isMongoListening - Determine if mongo WL port is in use 
###
function isMongoListening()
{
sudo netstat -npl | grep -E "^.*:${MONGO_PORT}.+LISTEN.*"
mongoListening=$?

if [[ "${mongoListening}" -eq 0 ]]
then
   return $FAILURE
else
   return $SUCCESS
fi

}

###
### checkMongoRunning- Determine if mongo WL is running 
###
function checkMongoRunning()
{

MONGOANS=$(ps -aef | grep -c $MONGO_PROP) 
if [[ "${MONGOANS}" -eq 2 ]];
then
	sudo netstat -npl | grep ${MONGO_PORT}
	if [ $? -eq 0 ]
	then
		MSGLOG " Wire Listener Mongo Port : ${MONGO_PORT}" N
	fi
fi

}

###
### isRestListening - Determine if rest WL port is in use 
###
function isRestListening()
{
sudo netstat -npl | grep -E "^.*:${REST_PORT}.+LISTEN.*"
restListening=$?

if [[ "${restListening}" -eq 0 ]]
then
   return $FAILURE
else
   return $SUCCESS
fi

}

###
### checkRestRunning - Determine if rest WL is running 
###
function checkRestRunning()
{
RESTANS=$(ps -aef | grep -c $REST_PROP)
if [ "${RESTANS}" -eq 2 ]
then
	sudo netstat -npl | grep ${REST_PORT}
	if [ $? -eq 0 ]
	then
		MSGLOG " Wire Listener Rest Port : ${REST_PORT}" N
	fi
fi	

}

###
### isMqttListening - Determine if mqtt port is in use 
###
function isMqttListening()
{
sudo netstat -npl | grep -E "^.*:${MQTT_PORT}.+LISTEN.*"
mqttListening=$?

if [[ "${mqttListening}" -eq 0 ]]
then
   return $FAILURE
else
   return $SUCCESS
fi

}

###
### checkMqttRunning - Determine if mqtt WL is running 
###
function checkMqttRunning()
{
MQTTANS=$(ps -aef | grep -c $MQTT_PROP)
MSGLOG ">>> DEBUG: MQTTANS: $MQTTANS"
if [ "${MQTTANS}" -eq 2 ]
then
	sudo netstat -npl | grep ${MQTT_PORT}
	if [ $? -eq 0 ]
	then
		MSGLOG " Wire Listener MQTT Port : ${MQTT_PORT}" N
	fi
fi	

}


###
###
### startWL - Start the WL 
###
function startWL()
{
if (! isMongoListening) || (! isRestListening) || (! isMqttListening)
then
	MSGLOG "${MONGO_PORT}, ${REST_PORT}, ${MQTT_PORT} Port is bound to some other service" N
else

	# Starting listener types
   cmd="java -jar '${INFORMIXDIR}'/bin/jsonListener.jar  "
   if [[ $env_PORT_REST == "ON" ]]
   then
	   PORT_ON="T"
      cmd+=" -config $REST_PROP " 
   fi
   if [[ $env_PORT_MONGO == "ON" ]]
   then
	   PORT_ON="T"
      cmd+=" -config $MONGO_PROP " 
   fi
   if [[ $env_PORT_MQTT == "ON" ]]
   then
	   PORT_ON="T"
      cmd+=" -config $MQTT_PROP" 
   fi
   cmd+=" -logfile $WL_LOG" 
   cmd+=" -loglevel info -start &" 

	# java -jar "${INFORMIXDIR}"/bin/jsonListener.jar  \
	# 	-config $REST_PROP \
	# 	-config $MONGO_PROP \
	# 	-config $MQTT_PROP \
	# 	-logFile $WL_LOG \
	# 	-loglevel info \
	# 	-start &

   MSGLOG ">>>    WL CMD: $cmd " N
   if [[ $PORT_ON == "T" ]]
	then
      eval $cmd 
	fi
fi

}


### setupMongoProp- Setup mongo properties file 
###
function setupMongoProp()
{

( ifFileExists $INFORMIX_CONFIG_DIR/$MONGO_PROP_FILENAME) && FILEEXISTS=1 || FILEEXISTS=0

if ( $(isEnvSet $env_MONGO_PROP_FILE) )
then
    MSGLOG ">>>      Using WL rest properties file supplied by user." N
    if [[ $env_STORAGE == "LOCAL" ]]
    then
      cp $INFORMIX_CONFIG_DIR/$env_MONGO_PROP_FILE $MONGO_PROP
    else
      ln -s $INFORMIX_CONFIG_DIR/$env_MONGO_PROP_FILE $MONGO_PROP
    fi
else
   MSGLOG ">>>      Creating DEFAULT WL mongo properties" N
   if [[ $env_STORAGE == "LOCAL" ]]
   then
      touch $MONGO_PROP
   else
      touch $INFORMIX_CONFIG_DIR/$MONGO_PROP_FILENAME
      ln -s $INFORMIX_CONFIG_DIR/$MONGO_PROP_FILENAME $MONGO_PROP
   fi 
fi

MSGLOG ">>>      WL-mongo: $FILEEXISTS $FALSE" N
if ( isEnvNotSet $env_MONGO_PROP_FILE ) && [[ $FILEEXISTS -eq $FALSE ]] 
then
MSGLOG ">>>      WL-debug : $FALSE" N
   RUNAS root "cat /dev/null > ${MONGO_PROP}"
   
   RUNAS root "echo '############################################################' >> ${MONGO_PROP}"
   RUNAS root "echo '### DO NOT MODIFY THIS COMMENT SECTION '>> ${MONGO_PROP}"
   RUNAS root "echo '### HOST NAME = ${HOSTNAME} ' >> ${MONGO_PROP}"
   RUNAS root "echo '############################################################' >> ${MONGO_PROP}"

   RUNAS root "echo 'database.log.enable=false' >> ${MONGO_PROP}"
   RUNAS root "echo 'listener.type=mongo' >> ${MONGO_PROP}"
   RUNAS root "echo 'listener.port=${MONGO_PORT}' >> ${MONGO_PROP}"
   RUNAS root "echo 'listener.hostName=*' >> ${MONGO_PROP}"
   RUNAS root "echo 'url=jdbc:informix-sqli://${HOSTNAME}:${TCP_PORT}/${DB_NAME:=sysmaster}:INFORMIXSERVER=${INFORMIXSERVER};USER=${DB_USER:=informix};PASSWORD=${env_INFORMIX_PASSWORD}'  >> ${MONGO_PROP}"
else
MSGLOG ">>>      WL-debug : $FALSE" N
   MSGLOG ">>>      Using Exiting Mongo properties file $INFORMIX_CONFIG_DIR/$MONGO_PROP_FILENAME" N
fi

MSGLOG ">>>      WL-debug bef: $FALSE" N
if ( ifFileExists $INFORMIX_FILES_DIR/${MONGO_PROP_FILENAME}.mod )
then
  MSGLOG ">>>        Modifying $MONGO_PROP_FILENAME " n
  . $SCRIPTS/informix_update_config_file.sh $INFORMIX_FILES_DIR/${MONGO_PROP_FILENAME}.mod $MONGO_PROP "="
elif ( ifFileExists $INFORMIX_CONFIG_DIR/${MONGO_PROP_FILENAME}.mod )
then
  MSGLOG ">>>        Modifying $MONGO_PROP_FILENAME " n
  . $SCRIPTS/informix_update_config_file.sh $INFORMIX_CONFIG_DIR/${MONGO_PROP_FILENAME}.mod $MONGO_PROP "="
fi
MSGLOG ">>>      WL-debug aft: $FALSE" N


}


###
### setupRestProp- setup rest properties file 
###
function setupRestProp()
{

#( ifFileExists $INFORMIX_CONFIG_DIR/$REST_PROP_FILENAME) && FILEEXISTS=1 || FILEEXISTS=0
MSGLOG ">>>      WL-debug : $FALSE" N
if ( ifFileExists $INFORMIX_CONFIG_DIR/$REST_PROP_FILENAME) 
then
FILEEXISTS=1
MSGLOG ">>> WL: rest file exists"
ls $INFORMIX_CONFIG_DIR
else
FILEEXISTS=0
MSGLOG ">>> WL: rest file does not exist"
fi

if ( $(isEnvSet $env_REST_PROP_FILE) )
then
    MSGLOG ">>>      Using WL rest properties file supplied by user." N
    if [[ $env_STORAGE == "LOCAL" ]]
    then
      cp $INFORMIX_CONFIG_DIR/$env_REST_PROP_FILE $REST_PROP
    else
      ln -s $INFORMIX_CONFIG_DIR/$env_REST_PROP_FILE $REST_PROP
    fi
else
   MSGLOG ">>>      Creating DEFAULT WL rest properties" N
   if [[ $env_STORAGE == "LOCAL" ]]
   then
      touch $REST_PROP
   else
      touch $INFORMIX_CONFIG_DIR/$REST_PROP_FILENAME
      ln -s $INFORMIX_CONFIG_DIR/$REST_PROP_FILENAME $REST_PROP
   fi 
fi

MSGLOG ">>>      WL-rest: $FILEEXISTS $FALSE" N
if ( isEnvNotSet $env_REST_PROP_FILE ) && [[ $FILEEXISTS -eq $FALSE ]] 
then
   RUNAS root "cat /dev/null > ${REST_PROP}"
   
   RUNAS root "echo '############################################################' >> ${REST_PROP}"
   RUNAS root "echo '### DO NOT MODIFY THIS COMMENT SECTION '>> ${REST_PROP}"
   RUNAS root "echo '### HOST NAME = ${HOSTNAME} ' >> ${REST_PROP}"
   RUNAS root "echo '############################################################' >> ${REST_PROP}"
   
   RUNAS root "echo 'listener.type=rest' >> ${REST_PROP}"
   RUNAS root "echo 'listener.port=${REST_PORT}' >> ${REST_PROP}"
   RUNAS root "echo 'listener.hostName=*' >> ${REST_PROP}"
   RUNAS root "echo 'security.sql.passthrough=true' >> ${REST_PROP}"
   RUNAS root "echo 'url=jdbc:informix-sqli://${HOSTNAME}:${TCP_PORT}/${DB_NAME:=sysmaster}:INFORMIXSERVER=${INFORMIXSERVER};USER=${DB_USER:=informix};PASSWORD=${env_INFORMIX_PASSWORD}'  >> ${REST_PROP}"
else
   MSGLOG ">>>      Using Exiting REST properties file $INFORMIX_CONFIG_DIR/$REST_PROP_FILENAME" N
fi

if ( ifFileExists $INFORMIX_FILES_DIR/${REST_PROP_FILENAME}.mod )
then
  MSGLOG ">>>        Modifying $REST_PROP_FILENAME " n
  . $SCRIPTS/informix_update_config_file.sh $INFORMIX_FILES_DIR/${REST_PROP_FILENAME}.mod $REST_PROP "="
elif ( ifFileExists $INFORMIX_CONFIG_DIR/${REST_PROP_FILENAME}.mod )
then
  MSGLOG ">>>        Modifying $REST_PROP_FILENAME " n
  . $SCRIPTS/informix_update_config_file.sh $INFORMIX_CONFIG_DIR/${REST_PROP_FILENAME}.mod $REST_PROP "="
fi
MSGLOG ">>>      WL-debug : $FALSE" N
}



###
### setupMqttProp- setup mqtt properties file 
###
function setupMqttProp()
{

( ifFileExists $INFORMIX_CONFIG_DIR/$MQTT_PROP_FILENAME) && FILEEXISTS=1 || FILEEXISTS=0

if ( $(isEnvSet $env_MQTT_PROP_FILE) )
then
    MSGLOG ">>>      Using WL rest properties file supplied by user." N
    if [[ $env_STORAGE == "LOCAL" ]]
    then
      cp $INFORMIX_CONFIG_DIR/$env_MQTT_PROP_FILE $MQTT_PROP
    else
      ln -s $INFORMIX_CONFIG_DIR/$env_MQTT_PROP_FILE $MQTT_PROP
    fi
else
   MSGLOG ">>>      Creating DEFAULT WL mqtt properties" N
   if [[ $env_STORAGE == "LOCAL" ]]
   then
      touch $MQTT_PROP
   else
      touch $INFORMIX_CONFIG_DIR/$MQTT_PROP_FILENAME
      ln -s $INFORMIX_CONFIG_DIR/$MQTT_PROP_FILENAME $MQTT_PROP
   fi 
fi

MSGLOG ">>>      WL-mqtt: $FILEEXISTS $FALSE" N
if ( isEnvNotSet $env_MQTT_PROP_FILE ) && [[ $FILEEXISTS -eq $FALSE ]] 
then
   RUNAS root "cat /dev/null > ${MQTT_PROP}"
   
   RUNAS root "echo '############################################################' >> ${MQTT_PROP}"
   RUNAS root "echo '### DO NOT MODIFY THIS COMMENT SECTION '>> ${MQTT_PROP}"
   RUNAS root "echo '### HOST NAME = ${HOSTNAME} ' >> ${MQTT_PROP}"
   RUNAS root "echo '############################################################' >> ${MQTT_PROP}"
   
   RUNAS root "echo 'listener.type=mqtt' >> ${MQTT_PROP}"
   RUNAS root "echo 'listener.port=${MQTT_PORT}' >> ${MQTT_PROP}"
   RUNAS root "echo 'listener.hostName=*' >> ${MQTT_PROP}"
   RUNAS root "echo 'url=jdbc:informix-sqli://${HOSTNAME}:${TCP_PORT}/${DB_NAME:=sysmaster}:INFORMIXSERVER=${INFORMIXSERVER};USER=${DB_USER:=informix};PASSWORD=${env_INFORMIX_PASSWORD}'  >> ${MQTT_PROP}"
else
   MSGLOG ">>>      Using Exiting MQTT properties file $INFORMIX_CONFIG_DIR/$MONGO_PROP_FILENAME" N
fi

if ( ifFileExists $INFORMIX_FILES_DIR/${MQTT_PROP_FILENAME}.mod )
then
  MSGLOG ">>>        Modifying $MQTT_PROP_FILENAME " n
  . $SCRIPTS/informix_update_config_file.sh $INFORMIX_FILES_DIR/${MQTT_PROP_FILENAME}.mod $MQTT_PROP "="
elif ( ifFileExists $INFORMIX_CONFIG_DIR/${MQTT_PROP_FILENAME}.mod )
then
  MSGLOG ">>>        Modifying $MQTT_PROP_FILENAME " n
  . $SCRIPTS/informix_update_config_file.sh $INFORMIX_CONFIG_DIR/${MQTT_PROP_FILENAME}.mod $MQTT_PROP "="
fi
}

###
### MSGLOG
###
function MSGLOG()
{
if [[ $2 = "N" ]]
then
   #printf "%s\n" "$1" |tee -a $INIT_LOG
   printf "%s\n" "$1" >> $INIT_LOG
   echo "$1" >&2
else
   #printf "%s" "$1" |tee -a $INIT_LOG
   printf "%s" "$1" >> $INIT_LOG
   echo "$1" >&2
fi
}


###
###  Call to main
###
main "$@"

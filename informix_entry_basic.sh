#!/bin/bash
#
#  name:        informix_entry_basic.sh:
#  description: Starts Informix in Docker container
#
#  Basic script to bring the Informix server online and
#  start the Wire Listener.
#  COMMENT out whatever you don't want to start.



main()
{

ENVFILE=/usr/local/bin/informix_inf.env
. $ENVFILE

dt=`date`
MSGLOG ">>>    Starting container/image ($dt) ..." N

###
###  Check LICENSE 
###
if (! isLicenseAccepted)  
then
   MSGLOG ">>>    License was not accepted Exiting! ..." N
   exit
fi

###
### Bring Server Online  
### 
MSGLOG ">>>    Informix SHM Initialization ..." N
oninit
MSGLOG "       [COMPLETED]" N


###
### Start Wire Listeners  - 
### 
MSGLOG ">>>    Starting WL! ..." N
java -jar $INFORMIXDIR/bin/jsonListener.jar \
   -config $INFORMIXDIR/etc/json_rest.properties  \
   -config $INFORMIXDIR/etc/mongo_rest.properties \
   -config $INFORMIXDIR/etc/mqtt_rest.properties  \
   -logFile $INFORMIXDIR/etc/json_listener.log    \
   -loglevel info                                 \
   -start &

MSGLOG "       [COMPLETED]" N



finish_org
finish_shutdown

}



#####################################################################
### FUNCTION DEFINITIONS
#####################################################################

SUCCESS=0
FAILURE=1


function isLicenseAccepted()
{
env_LICENSE=`echo $LICENSE|tr /a-z/ /A-Z/`
if [[ $env_LICENSE = "ACCEPT" ]];
then
   return $SUCCESS
else
   return $FAILURE 
fi
}

###
### MSGLOG 
###
function MSGLOG()
{

if [ ! -e $INIT_LOG ]
then
   touch $INIT_LOG
fi

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


function finish_org()
{
#trap finish_shutdown SIGHUP SIGINT SIGTERM SIGKILL
trap finish_shutdown SIGHUP SIGINT SIGTERM 
#tail -f  $INFORMIX_DATA_DIR/logs/online.log
tail -f  /dev/null 
wait $!

}

function finish_shutdown()
{
MSGLOG ">>> " N
MSGLOG ">>>    SIGNAL received - Shutdown:" N
MSGLOG ">>> " N
. $BASEDIR/scripts/informix_stop.sh
}





###
###  Call to main
###
main "$@"

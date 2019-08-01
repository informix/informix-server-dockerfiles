#!/bin/bash
#
#  name:        informix_stop.sh:
#  description: Stops Informix in Docker container
#

main()
{
###
###  Setup environment
###
. /usr/local/bin/informix_inf.env

#MSGLOG ">>>    Stopping the IBM Informix Database (${INFORMIXSERVER}) ... " N
#cp $INFORMIXDIR/etc/$ONCONFIG $INFORMIX_DATA_DIR/tmp
#cp $INFORMIXDIR/etc/sqlhosts $INFORMIX_DATA_DIR/tmp


[[ ! -z $CONFIGURE_INIT ]] && exit 


onmode -kuy &
exec_K_initdb

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
### exec_K_initdb 
###
function exec_K_initdb()
{
MSGLOG ">>> " N
MSGLOG ">>> Execute init-shutdown scripts" N
MSGLOG ">>> " N

if [ -d $INFORMIX_DATA_DIR/init.d ]
then
   filelist=`ls -x $INFORMIX_DATA_DIR/init.d/K*`
   for f in $filelist
   do
   MSGLOG ">>> Processing: $f" N
   done
   MSGLOG ">>> " N
fi
}






###
### Call to main
###
main "$@" 

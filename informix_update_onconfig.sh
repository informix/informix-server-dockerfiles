#!/bin/bash
#
#  name:        informix_udpate_onconfig.sh:
#  description: Make modifications to onconfig file 
#  Called by:   informix_entry.sh
#  ONCONFIG_PATH = $1 - ONCONFIG FILE 
#  MODFILE = $2 - the modification file to use 

ADD=1
UPDATE=2
DELETE=3
MOD=0
ONCONFIG_PATH=$1
MODFILE=$2

IFS=" "


while IFS= read -r line || [ -n "$line" ]
do
   toks=( $line )
   if [[ $line == "" ]]
   then
      continue
   fi
   if [[ ${line:0:1} == "#" ]]
   then
      continue
   fi

   if [[ ${toks[0]} == "[ADD]" ]]
   then
   MOD=$ADD
   continue
   fi
   if [[ ${toks[0]} == "[UPDATE]" ]]
   then
   MOD=$UPDATE
   continue
   fi
   if [[ ${toks[0]} == "[DELETE]" ]]
   then
   MOD=$DELETE
   continue
   fi

   if [[ $MOD == $DELETE ]]
   then
   sed -i "/^${toks[0]}/d" $ONCONFIG_PATH
   fi

   if [[ $MOD == $ADD ]]
   then
   cnt=`sed -n "/^${line}/p" $ONCONFIG_PATH |wc -l`
      if [[ $cnt == "0" ]]
      then
         echo $line >> $ONCONFIG_PATH
      fi
   fi

   if [[ $MOD == $UPDATE ]]
   then
   sed -i "s/^${toks[0]}.*/${toks[0]} ${toks[1]}/g" $ONCONFIG_PATH
   fi

done < $MODFILE 


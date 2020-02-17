#!/bin/bash
#
#  name:        informix_udpate_onconfig.sh:
#  description: Make modifications to onconfig file 
#  Called by:   informix_entry.sh
#  MODFILE = $1 - the modification file to use 

ADD=1
UPDATE=2
DELETE=3
MOD=0
MODFILE=$1
FILENAME=$2

IFS=" "

MSGLOG ">>>    MODIFY ONCONFIG: $MODFILE" N
MSGLOG ">>>    MODIFY ONCONFIG: $FILENAME" N

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
   MSGLOG ">>>>   ONCONFIG DEL: ${toks[0]}" N
   SED "/^${toks[0]} /d" $FILENAME
   fi

   if [[ $MOD == $ADD ]]
   then
   cnt=`sed -n "/^${line}/p" $FILENAME |wc -l`
         MSGLOG ">>>>   ONCONFIG ADD1: $line" N
      if [[ $cnt == "0" ]]
      then
         MSGLOG ">>>>   ONCONFIG ADD2: $line" N
         echo $line >> $FILENAME
      fi
   fi

   if [[ $MOD == $UPDATE ]]
   then
      MSGLOG ">>>>   ONCONFIG UPDATE: ${toks[0]} - ${toks[1]}" N
      SED "s/^${toks[0]} .*/${toks[0]} ${toks[1]}/g" $FILENAME
   fi

done < $MODFILE 


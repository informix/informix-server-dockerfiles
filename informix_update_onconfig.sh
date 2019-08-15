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
   SED "/^${toks[0]}/d" $INFORMIXDIR/etc/$ONCONFIG
   fi

   if [[ $MOD == $ADD ]]
   then
   cnt=`sed -n "/^${line}/p" $INFORMIXDIR/etc/$ONCONFIG |wc -l`
      if [[ $cnt == "0" ]]
      then
         echo $line >> $$INFORMIXDIR/etc/$ONCONFIG
      fi
   fi

   if [[ $MOD == $UPDATE ]]
   then
      SED "s/^${toks[0]}.*/${toks[0]} ${toks[1]}/g" $INFORMIXDIR/etc/$ONCONFIG
   fi

done < $MODFILE 


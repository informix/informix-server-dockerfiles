#!/bin/bash
#
#  name:        informix_udpate_onconfig.sh:
#  description: Make modifications to onconfig file 
#  Called by:   informix_entry.sh
#  MODFILE = $1 - the modification file to use 
#  FILENAME = $1 - the configuration file to modify 

ADD=1
UPDATE=2
DELETE=3
MOD=0
MODFILE=$1
FILENAME=$2
SEP=$3
SUCCESS=0
FAILURE=1

PARAM_LIST=""

IFS=" "

MSGLOG ">>>    MODIFY CONFIG: $MODFILE" N
MSGLOG ">>>    MODIFY CONFIG: $FILENAME" N


function deleteLine()
{
   LINE=$1
   MSGLOG ">>>    CONFIG MOD DEL = $LINE" N
   SED "/^${LINE}/d" $FILENAME
}

function getLineNumber()
{
   LINE=$1
   ln=`grep -n -m 1 "^${LINE}" $FILENAME |cut -f1 -d:`
   if [[ $ln == "" ]]
   then
      ln="-1"
   fi
   echo $ln
}

function addLine()
{
   LINE=$1
   LNUM=$2
   wcl=`wc -l $FILENAME|awk '{print $1}'`
   MSGLOG ">>>    CONFIG MOD wcl = $wcl LNUM = $LNUM" N 
   [[ $wcl -ge $LNUM ]] && LNUM=-1
   MSGLOG ">>>    CONFIG MOD wcl = $wcl LNUM = $LNUM" N 

   MSGLOG ">>>    CONFIG MOD ADD = $LINE" N 
   if [[ $LNUM == "-1" ]]
   then
      MSGLOG ">>>    CONFIG MOD ADD - Append end" N 
      RUNAS root "echo '$LINE' >> $FILENAME"
   else
      MSGLOG ">>>    CONFIG MOD ADD - Inserting LN=$LNUM" N 
      SED "${LNUM}i${LINE}" $FILENAME
   fi
}

function paramAlreadySeen()
{
   PARAM=$1
   for i in $PARAM_LIST
   do
      if [[ $i == "$PARAM" ]]
      then
         MSGLOG ">>>        CONFIG MOD: PARAM $PARAM ALready seen"
         return $SUCCESS
      fi
   done
   return $FAILURE
}



######################################

while IFS= read -r line || [ -n "$line" ]
do
   #toks=( $line )
   IFS="$SEP"
   read -ra toks <<< "$line"
   PARAM=${toks[0]}
   if [[ $line == "" ]]
   then
      continue
   fi
   if [[ ${line:0:1} == "#" ]]
   then
      continue
   fi

   if ( paramAlreadySeen $PARAM)
   then
      LN=$(getLineNumber ${PARAM})
      addLine "$line" "$LN"
   else
      PARAM_LIST=${PARAM_LIST}" $PARAM"
      LN=$(getLineNumber ${PARAM})
      deleteLine $PARAM 
      addLine "$line" "$LN"
   fi 
   MSGLOG ">>> CONFIG MOD: PARAM_LIST = $PARAM_LIST"

done < $MODFILE 


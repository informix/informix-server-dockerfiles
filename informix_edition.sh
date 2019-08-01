#!/bin/bash
#
#  name:        informix_edition.sh:
#  description: Run the Edition installer - Set the edition accordingly 
. /usr/local/bin/informix_inf.env

if [[ -f $INFORMIXDIR/edition.jar && -s $INFORMIXDIR/edition.jar ]]
then
   $INFORMIXDIR/jvm/jre/bin/java -jar $INFORMIXDIR/edition.jar  -DUSER_INSTALL_DIR=$INFORMIXDIR -DLICENSE_ACCEPTED=TRUE -i silent
fi
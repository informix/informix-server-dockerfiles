#!/bin/bash
#
#  name:        informix_setup_links.sh:
#  description: Setup tmp files for sqlhosts and onconfig 
#  Called by:   informix_entry.sh


## sqlhosts to get recreated each start/run due to hostname changes
#cp $INFORMIX_DATA_DIR/tmp/sqlhosts $INFORMIXDIR/etc/sqlhosts
#cp $INFORMIX_DATA_DIR/tmp/$ONCONFIG $INFORMIXDIR/etc/$ONCONFIG


if [ ! -e $INFORMIXDIR/etc/$ONCONFIG ]
then
   if [ ! -z $env_ONCONFIG_FILE ]
   then
     ln -s $INFORMIX_CONFIG_DIR/$env_ONCONFIG_FILE $INFORMIXDIR/etc/$ONCONFIG
   else
     ln -s $INFORMIX_CONFIG_DIR/$ONCONFIG $INFORMIXDIR/etc/$ONCONFIG
   fi
fi

if [ ! -e $INFORMIXDIR/etc/sqlhosts ]
then
   if [ ! -z $env_SQLHOSTS_FILE ]
   then
     ln -s $INFORMIX_CONFIG_DIR/$env_SQLHOSTS_FILE $INFORMIXDIR/etc/sqlhosts
   else
     ln -s $INFORMIX_CONFIG_DIR/sqlhosts $INFORMIXDIR/etc/sqlhosts
   fi
fi


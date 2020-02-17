#!/bin/bash
#
#  name:        informix_setup_msgpath.sh:
#  description: Setup and create dir and msgpath 
#  Called by:   informix_entry.sh


touch $INFORMIX_DATA_DIR/logs/online.log
chown informix:informix $INFORMIX_DATA_DIR/logs/online.log
chmod 660 $INFORMIX_DATA_DIR/logs/online.log

cat /dev/null > $INFORMIX_DATA_DIR/logs/online.log



#!/bin/bash
#
#  name:        informix_setup_user_db.sh:
#  description: Setup the database
#  Called by:   informix_entry.sh


dbaccess sysmaster /home/informix/vol1/$DB_SCHEMA >> $INIT_LOG 2>&1

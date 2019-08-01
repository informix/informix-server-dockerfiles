#!/bin/bash
#
#  name:        informix_setup_iot_db.sh:
#  description: Setup the database
#  Called by:   informix_entry.sh


dbaccess sysmaster $INFORMIX_DATA_DIR/iot_db.sql >> $INIT_LOG 2>&1

#!/bin/bash
#
#  name:        informix_setup_rootdbs.sh:
#  description: Setup and create directories and files 
#  Called by:   informix_entry.sh


touch $INFORMIX_DATA_DIR/spaces/rootdbs.000
chown informix:informix $INFORMIX_DATA_DIR/spaces/rootdbs.000
chmod 660 $INFORMIX_DATA_DIR/spaces/rootdbs.000

cat /dev/null > $INFORMIX_DATA_DIR/spaces/rootdbs.000



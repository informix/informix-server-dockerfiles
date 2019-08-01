#!/bin/bash
#
#  name:        informix_setup_datadir.sh:
#  description: Create dirs for logs and spaces 
#  Called by:   informix_entry.sh


mkdir -p $INFORMIX_DATA_DIR/logs
mkdir -p $INFORMIX_DATA_DIR/spaces

mkdir -p $BASEDIR/config




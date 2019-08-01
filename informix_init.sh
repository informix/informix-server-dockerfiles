#!/bin/bash
#
#  name:        informix_init.sh:
#  description: Initialize informix - first time initialize disk space 
#  Called by:   informix_entry.sh

###
### Check to see if informix already disk initialized
###

	# Initialize shared memmory and data structure
	# and kill server
	oninit -ivwy  >> $INIT_LOG
	
	ONLINE_LOG="${INFORMIX_DATA_DIR}/logs/online.log"
	iter=0
	while [ ${iter} -lt 120 ]; do
		grep -i "sysadmin" ${ONLINE_LOG} 2>&1 1>/dev/null
		if [ $? -eq 0 ]; then break; fi
		iter=$((iter+1));
		sleep 1;
	done
	if [ ${iter} -gt 120 ];then
	  printf "\n\tProblem creating sysadmin with oninit\n"
          exit
	fi
	
        dbaccess sysadmin $INFORMIX_DATA_DIR/extend_root.sql >> $INIT_LOG 2>&1

        if [ $DB_SBSPACE ];
        then
           dbaccess sysadmin $INFORMIX_DATA_DIR/sbspace.sql >> $INIT_LOG 2>&1
        fi 

#!/bin/bash
#
#  name:        informix_sizing_onconfig.sh:
#  description: Make modifications to onconfig file  based on container 
#               resources
#  Called by:   informix_setup_onconfig.sh
#   Params:
#       onconfig path (absolute path)
#       Amount of Memory % to use
#       Amount of CPU % to use


main()
{
ONCONFIG_PATH=$1
#env_TYPE=`echo $2|tr /a-z/ /A-Z/`

if [[ $env_SIZE = [0-9]* ]]
then
   vMEM_USE_PERCENTAGE=` echo "scale=2; ${env_SIZE}/100" |bc -l`
else
   vMEM_USE_PERCENTAGE=.80
fi


MSGLOG ">>> vMEM_USE_PERCENTAGE:    $vMEM_USE_PERCENTAGE" N
MSGLOG ">>> env_BUFFERS_PERCENTAGE: $env_BUFFERS_PERCENTAGE" N
MSGLOG ">>> env_SHMVIRT_PERCENTAGE: $env_SHMVIRT_PERCENTAGE" N
MSGLOG ">>> env_NONPDQ_PERCENTAGE:  $env_NONPDQ_PERCENTAGE" N

SUCCESS=0
FAILURE=-1

## Resource Limit files.  
CPUFILE="/sys/fs/cgroup/cpu/cpu.cfs_quota_us"
MEMFILE="/sys/fs/cgroup/memory/memory.limit_in_bytes"

vSYSTEM_MEM_LIMIT_B=`cat $MEMFILE`
vSYSTEM_MEM_LIMIT_MB=`echo "($vSYSTEM_MEM_LIMIT_B / 1024) / 1024" | bc`

vCPUS_CONTAINER=`cat $CPUFILE`

vMEM_HOST_MB=`free -m |grep Mem|awk '{print $2}'`
vCPUS_HOST=`lscpu |grep "CPU(s):"|grep -v node|awk '{print $2}'`

###
### Set the amount of CPU's available to the docker container
###
if [[ $vCPUS_CONTAINER == "-1" ]]
then
   vCPUS=$vCPUS_HOST
else
   vCPUS=`echo "$vCPUS_CONTAINER / 100000" | bc`
fi

###
### Set the amount of Memory available to the docker container
###
if (useSystemMemorySize) 
then
   vMEM_MB=`echo "scale=2; $vMEM_HOST_MB * $vMEM_USE_PERCENTAGE" |bc -l`
else
   vMEM_MB=`echo "scale=2; $vSYSTEM_MEM_LIMIT_MB * $vMEM_USE_PERCENTAGE" |bc -l `
fi


MSGLOG ">>> vMEM_MB:         $vMEM_MB" N
MSGLOG ">>> vCPUS_HOST:      $vCPUS_HOST"
MSGLOG ">>> vCPUS_CONTAINER: $vCPUS_CONTAINER "
MSGLOG ">>> vCPUS:           $vCPUS" N

setCPUResources
setMEMResources
setGenericResources

}



function useSystemMemorySize()
{



   if [ `expr $vSYSTEM_MEM_LIMIT_MB` -gt `expr $vMEM_HOST_MB` ]
   then
      return $SUCCESS 
   else
      return $FAILURE 
   fi
   
}


function setCPUResources()
{




   if [ `expr $vCPUS` -gt 1 ]
   then
      E_NUMCPU=`expr $vCPUS - 1`
      E_MULTI=1
   else
      E_NUMCPU=$vCPUS
      E_MULTI=0
   fi

   if (isDE || isIE)
   then
      E_NUMCPU=1
      E_MULTI=0
      MSGLOG ">>>    OVERRIDE CPUs set to 1 ..." N 
   fi

   sed -i "s#^VPCLASS cpu.*#VPCLASS cpu,num=$E_NUMCPU,noage#g" "${ONCONFIG_PATH}"
   sed -i "s#^MULTIPROCESSOR.*#MULTIPROCESSOR $E_MULTI#g" "${ONCONFIG_PATH}"




   ### Small System
   ### Relate to informix_config.small
   if [ `expr $E_NUMCPU` -lt 4 ]
   then
      sed -i "s#^LOCKS.*#LOCKS 50000#g" "${ONCONFIG_PATH}"
      sed -i "s#^LOGBUFF.*#LOGBUFF 128#g" "${ONCONFIG_PATH}"
      sed -i "s#^NETTYPE.*#NETTYPE soctcp,1,200,CPU#g" "${ONCONFIG_PATH}"
      sed -i "s#^PHYSBUFF.*#PHYSBUFF 128#g" "${ONCONFIG_PATH}"
      sed -i "s#^VP_MEMORY_CACHE_KB.*#VP_MEMORY_CACHE_KB 0#g" "${ONCONFIG_PATH}"

   ### Medium System
   ### Relate to informix_config.medium
   elif [ `expr $E_NUMCPU` -lt 8 ]
   then
      sed -i "s#^LOCKS.*#LOCKS 100000#g" "${ONCONFIG_PATH}"
      sed -i "s#^LOGBUFF.*#LOGBUFF 256#g" "${ONCONFIG_PATH}"
      sed -i "s#^NETTYPE.*#NETTYPE soctcp,4,200,CPU#g" "${ONCONFIG_PATH}"
      sed -i "s#^PHYSBUFF.*#PHYSBUFF 256#g" "${ONCONFIG_PATH}"
      sed -i "s#^VP_MEMORY_CACHE_KB.*#VP_MEMORY_CACHE_KB 2048#g" "${ONCONFIG_PATH}"

   ### Large System
   ### Relate to informix_config.large
   else
      sed -i "s#^LOCKS.*#LOCKS 250000#g" "${ONCONFIG_PATH}"
      sed -i "s#^LOGBUFF.*#LOGBUFF 512#g" "${ONCONFIG_PATH}"
      sed -i "s#^NETTYPE.*#NETTYPE soctcp,8,200,CPU#g" "${ONCONFIG_PATH}"
      sed -i "s#^PHYSBUFF.*#PHYSBUFF 512#g" "${ONCONFIG_PATH}"
      sed -i "s#^VP_MEMORY_CACHE_KB.*#VP_MEMORY_CACHE_KB 4096#g" "${ONCONFIG_PATH}"

   fi

}


function setMEMResources()
{

   ###
   ### Override vMEM_MB if > Edition Limits; DE (1GB), IE (2GB)  

   vMEM_MB_USEABLE=`awk -vp=${vMEM_MB} -vq=.80 'BEGIN{printf "%d", p * q}'`

   if (isDE)
   then
      if [ $vMEM_MB_USEABLE -gt 1000 ]
      then
      MSGLOG ">>>    OVERRIDE MEMORY USEABLE ($vMEM_MB_USEABLE) ..." N 
      vMEM_MB_USEABLE=1000
      MSGLOG ">>>    OVERRIDE MEMORY DE Setting ($vMEM_MB_USEABLE) ..." N 
      fi
   fi

   if (isIE)
   then
      if [ $vMEM_MB -gt 2000 ]
      then
      MSGLOG ">>>    OVERRIDE MEMORY USEABLE ($vMEM_MB_USEABLE) ..." N 
      vMEM_MB_USEABLE=2000
      MSGLOG ">>>    OVERRIDE MEMORY IE Setting ($vMEM_MB_USEABLE) ..." N 
      fi
   fi  


   vMEMUSE_BUF=`echo "scale=2; (( $vMEM_MB_USEABLE) * ($env_BUFFERS_PERCENTAGE / 100))" | bc`
   vMEMUSE_SHM=`echo "scale=2; (( $vMEM_MB_USEABLE) * ($env_SHMVIRT_PERCENTAGE / 100))" | bc`
   vMEMUSE_NONPDQ=`echo "scale=2; (( $vMEM_MB_USEABLE) * ($env_NONPDQ_PERCENTAGE / 100))" | bc`



   vBUFFERS=`echo "$vMEMUSE_BUF * 500 "|bc`
   vSHMVIRTSIZE=`echo "$vMEMUSE_SHM * 1000 "|bc`
   vSHMTOTAL=`echo "($vMEM_MB_USEABLE) * 1000" | bc`
   vNONPDQ=`echo "$vMEMUSE_NONPDQ * 1000" |bc`




   vNONPDQ=${vNONPDQ%.*}
   vSHMTOTAL=${vSHMTOTAL%.*}
   vSHMVIRTSIZE=${vSHMVIRTSIZE%.*}
   vBUFFERS=${vBUFFERS%.*}


   sed -i "s#^BUFFERPOOL size=2k.*#BUFFERPOOL size=2k,buffers=$vBUFFERS,lrus=8,lru_min_dirty=50,lru_max_dirty=60#g" "${ONCONFIG_PATH}"
   sed -i "s#^SHMTOTAL.*#SHMTOTAL $vSHMTOTAL#g" "${ONCONFIG_PATH}"
   sed -i "s#^SHMVIRTSIZE.*#SHMVIRTSIZE $vSHMVIRTSIZE#g" "${ONCONFIG_PATH}"
   sed -i "s#^DS_NONPDQ_QUERY_MEM.*#DS_NONPDQ_QUERY_MEM $vNONPDQ#g" "${ONCONFIG_PATH}"



   #echo "vMEM_MB = $vMEM_MB"
   #echo "vMEMUSE_BUF    = $vMEMUSE_BUF"
   #echo "vMEMUSE_SHM    = $vMEMUSE_SHM"
   MSGLOG ">>>        Setting DS_NONPDQ_QUERY_MEM = $vNONPDQ" N
   MSGLOG ">>>        Setting BUFFERS = $vBUFFERS" N
   MSGLOG ">>>        Setting SHMVIRTSIZE = $vSHMVIRTSIZE" N
   MSGLOG ">>>        Setting SHMTOTAL = $vSHMTOTAL" N



}

function setGenericResources()
{
### Sets the following onconfig params:
###
### AUTO_TUNE 1 
### DIRECT_IO 1
### DUMPSHMEM 0
### RESIDENT -1

   sed -i "s#^AUTO_TUNE.*#AUTO_TUNE 1#g" "${ONCONFIG_PATH}"
   sed -i "s#^DIRECT_IO.*#DIRECT_IO 1#g" "${ONCONFIG_PATH}"
   sed -i "s#^DUMPSHMEM.*#DUMPSHMEM 0#g" "${ONCONFIG_PATH}"
   sed -i "s#^RESIDENT.*#RESIDENT -1#g" "${ONCONFIG_PATH}"

}


### xperf2 
###   9,223,372,036,854,771,712 mem value when not set
###   -1 cpu value when not set
###
###   800000 cpu value when set to 8
###   4194304000 mem value when set to 4000m
###
###   free -m   48095
###   



###
### Call to main
###

main "$@"
#!/bin/bash

# License: https://github.com/influxdata/azure-resource-manager-influxdb-enterprise/blob/master/LICENSE
#
# Configure InfluxEnterprise from deployed ARM templates
#
# 01/2020 Initial Version
#--------------------------
#

help()
{
    echo " "
    echo "This script configures a new InfluxEnterpise cluster deployed with Azure ARM templates."
    echo "Parameters:"
    echo "-m  Metanode configuration"
    echo "-d  Datanode configuration [requires -c parameter]"
    echo "-j  Join cluster nodes [requires -m:-c parameters]"
    echo "-c  Number of datanodes to configure"
    echo "-h  view this help content"
}

#########################
# Logging func
#########################

# Custom logging with time so we can easily relate running times, also log to separate file so order is guaranteed.
# The Script extension output the stdout/err buffer in intervals with duplicates.
log()
{
     echo \[$(date +%d%m%Y-%H:%M:%S)\] "$1"
     echo \[$(date +%d%m%Y-%H:%M:%S)\] "$1" >> /var/log/cluster-configuration.log
}


log "Begin execution of Cluster Configuration script extension on ${HOSTNAME}"
START_TIME=$SECONDS


#########################
# Check user access
#########################

if [ "${UID}" -ne 0 ];
  then
    log "[preconditions] Script executed without root permissions"
    echo "You must be root to run this program." >&2
    exit 3
fi

#Script Parameters
META_GEN_FILE="/etc/influxdb/influxdb-meta-generated.conf"
DATA_GEN_FILE="/etc/influxdb/influxdb-generated.conf"
META_CONFIG_FILE="/etc/influxdb/influxdb-meta.conf"
DATA_CONFIG_FILE="/etc/influxdb/influxdb.conf"
TEMP_LICENSE="d2951f76-a329-4bd9-b9bc-12984b897031"
ETC_HOSTS="/etc/hosts"


#Loop through options passed
while getopts :m:d:c:j:h optname; do
  log "Option $optname set"
  case $optname in
    m)  #configure metanodes
      METANODE="${OPTARG}"
      ;;
    d) #configure datanodes 
      DATANODE="${OPTARG}"
      ;;
    c) #number os datanodes (need for datanode configure and cluster join)
      COUNT="${OPTARG}"
      ;;
    j) #join cluster
      JOIN="${OPTARG}"
      ;;
    h) #show help
      help
      exit 2
      ;;
    \?) #unrecognized option - show help
      echo -e \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
      help
      exit 2
      ;;
  esac
done

#########################
# Configuration functions
#########################

setup_metanodes()
{
  # TEMP-SOLUTION: Hard coded privateIP's
  # Append metanode vm hostname  to the hsots file

  log "[setup_metanodes] adding all metanodes to the /etc/hosts file"
  if [ -n "$(grep ${HOSTNAME} /etc/hosts)" ]
    then
      log "[setup_metanodes] hostname already exists : $(grep $HOSTNAME $ETC_HOSTS)"
    else
        for i in $(seq 0 2); do 
          echo "10.0.0.1${i} metanode-vm${i}" >> /etc/hosts
        done        
  fi
}

setup_datanodes()
{
  # TEMP-SOLUTION: Hard coded privateIP's
  # Append metanode vm hostname  to the hsots file

  if [ -z "${COUNT}" ]; then
    log  "err: missing datanode count parameter..."
    exit 2
  fi

  END=`expr ${COUNT} - 1`

  log "[setup_datanodes] adding all datanodes to the /etc/hosts file"

  if [ -n "$(grep ${HOSTNAME} /etc/hosts)" ]
    then
      log "[setup_datanodes] hostname already exists : $(grep $HOSTNAME $ETC_HOSTS)"
    else
        for i in $(seq 0 "${END}"); do 
          echo "10.0.1.1${i} datanode-vm${i}" >> /etc/hosts
        done        
  fi
}

join_metanodes()
{
  #joining meatanodes
  log "[influxd-ctl_add-meta] joining 3 metanodes to cluster"
  for i in $(seq 0 2); do 
    influxd-ctl add-meta  "metanode-vm${i}:8091"
  done
}

join_datanodes()
{
  #joining datanodes
  log "[influxd-ctl_add-data] joining ${COUNT} datanodes to cluster"

  END=`expr ${COUNT} - 1`
  for i in $(seq 0 "${END}"); do
    influxd-ctl add-data  "datanode-vm${i}:8088"
  done
}

configure_metanodes()
{
  #generate and stage new configuration file
  log "[influxd-meta] generating new metanode configuration file at ${META_GEN_FILE}"
  influxd-meta config > "${META_GEN_FILE}"

  if [ -f "${META_GEN_FILE}" ]; then
    cp -p  "${META_GEN_FILE}" "${META_CONFIG_FILE}"
    EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
       log "err: could not copy new "${META_CONFIG_FILE}" file to /etc/influxdb"
      exit $EXIT_CODE
    fi
    
    #need to update the influxdb-meta.conf default values
    log  "[sed_cmd] updated ${META_CONFIG_FILE} default file values"

    chown influxdb:influxdb "${META_CONFIG_FILE}"
    sed -i "s/\(hostname *= *\).*/\1\"$HOSTNAME\"/" "${META_CONFIG_FILE}"
    sed -i "s/\(license-key *= *\).*/\1\"$TEMP_LICENSE\"/" "${META_CONFIG_FILE}"
    sed -i "s/\(dir *= *\).*/\1\"\/influxdb\/meta\"/" "${META_CONFIG_FILE}"


    #create working dir for meatanode service
    log "[mkdir_cmd] creating metanode directory structure"

    mkdir -p "/influxdb/meta"
    chown -R influxdb:influxdb "/influxdb/"

  else
     log  "err: creating file ${META_GEN_FILE}. you will need to manually configure the metanode..."
     exit 1
  fi
}

configure_datanodes()
{
  #generate and stage new configuration file
  log "[configure_datanodes] generating new datanode configuration file at ${DATA_GEN_FILE}"
  influxd config > "${DATA_GEN_FILE}"

  if [ -f "${DATA_GEN_FILE}" ]; then

    cp -p  "${DATA_GEN_FILE}" "${DATA_CONFIG_FILE}"
    EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
       log "err: could not copy new "${DATA_GEN_FILE}" file to file to /etc/influxdb"
      exit $EXIT_CODE
    fi

    #need to update the influxdb.conf default values
    log  "[sed_cmd] updated ${META_CONFIG_FILE} default file values"

    chown influxdb:influxdb "${DATA_CONFIG_FILE}"
    sed -i "s/\(hostname *= *\).*/\1\"$HOSTNAME\"/" "${DATA_CONFIG_FILE}"
    sed -i "s/\(license-key *= *\).*/\1\"$TEMP_LICENSE\"/" "${DATA_CONFIG_FILE}"
    sed -i "s/\(auth-enabled *= *\).*/\1false/" "${DATA_CONFIG_FILE}"

    #create working dirs and file for datanode service
    log "[mkdir_cmd] creating datanode directory structure"

    mkdir -p "/influxdb/meta"
    mkdir -p "/influxdb/data"
    mkdir -p "/influxdb/wal"
    mkdir -p "/influxdb/hh"
    chown -R influxdb:influxdb "/influxdb/"

  else
     log  "err: creating file ${DATA_GEN_FILE}. you will need to manually configure the metanode..."
     exit 1
  fi
}
datanode_count()
{
    #checking to see if the $COUNT parameter is set 
  log "[datanode_count] checking COUNT parameter"

  if [ -z "${COUNT}" ]; then
    log "err: please set \$_COUNT parameter..."

    exit 1
  fi
}

start_systemd()
{
  if [ "${METANODE}" == 1 ]; then
    log "[start_systemd] starting metanode"
    systemctl start influxdb-meta
  elif [ "${DATANODE}" == 1 ]; then
    log "[start_systemd] starting datanode"
    systemctl start influxdb
  fi
}

process_check()
{
  #check service status
  log "[process_check] check service process started"

  PROC_CHECK=`ps aux | grep -v grep | grep influxdb`
  EXIT_CODE=$?
  if [[ $EXIT_CODE -ne 0 ]]; then
    log "err: could not copy new "${DATA_GEN_FILE}" file to file to /etc/influxdb"
    exit $EXIT_CODE
  fi
}

install_ntp()
{
    log "installing ntp deamon"
    apt-get -y install ntp
    ntpdate pool.ntp.org
    log "installed ntp deamon and ntpdate"
}

#########################
# Primary Install Tasks
#########################

log "[apt-get] updating apt-get"
(apt-get -y update || (sleep 15; apt-get -y update))
EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  log "[apt-get] failed updating apt-get. exit code: $EXIT_CODE"
  exit $EXIT_CODE
fi
log "[apt-get] updated apt-get"


#format data disk (Find data disks then partition, format, and mount it
# as seperate drive under /influxdb/* )_
#------------------------
log "[autopart] running auto partitioning & mounting"

bash autopart.sh


if [ "${METANODE}" == 1 ]; then
    log "[metanode_funcs] executing metanode configuration functions"

    setup_metanodes

    configure_metanodes

elif [ "${DATANODE}" == 1 ]; then
    log "[datanode_funcs] executing datanode configuration functions"
    
    datanode_count

    setup_datanodes

    configure_datanodes
else 

  help

  exit 2
fi


#start service & check process
#------------------------
start_systemd

process_check


#master metanode funcs to join all nodes to cluster 
#------------------------
if [ "${JOIN}" == 1 ];then
  log "[join_funcs] executing cluster join commands on master metanode"

  datanode_count

  join_metanodes

  join_datanodes
fi

ELAPSED_TIME=$(($SECONDS - $START_TIME))
PRETTY=$(printf '%dh:%dm:%ds\n' $(($ELAPSED_TIME/3600)) $(($ELAPSED_TIME%3600/60)) $(($ELAPSED_TIME%60)))

log "End execution of InfluxEnterprise cluster congifuration script extension on ${HOSTNAME} in ${PRETTY}"
exit 0
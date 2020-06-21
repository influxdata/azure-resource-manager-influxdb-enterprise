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
    echo "-n  Configure specific service [meta || data || leader]"
    echo "-u  Supply influxdb admin username enterprise  - used in case of [leader] node only"
    echo "-p  Supply influxdb admin password enterprise  - used in case of [leader] node only"
    echo "-c  Number of datanodes to configure - used in case of [data||leader] node configurations"
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
     echo \[$(date +%d%m%Y-%H:%M:%S)\] "$1" >> /var/log/enterprise-configuration.log
}


log "Begin execution of Enterpise Cluster script extension on ${HOSTNAME}"
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
META_ENV_FILE="/etc/default/influxdb-meta"
DATA_ENV_FILE="/etc/default/influxdb"
TELEGRAF_CONFIG_FILE="/etc/telegraf/telegraf.conf"

#Loop through options passed
while getopts :n:c:u:p:h optname; do
  log "Option $optname set"
  case $optname in
    s)  #configure [meta||data||leader] nodes
      SERVICE="${OPTARG}"
      ;;
    c) #number os datanodes - used in case of [data||leader] nodes configurations
      COUNT="${OPTARG}"
      ;;
    u) #influxdb admin username - used in case of [leader] node configurations only
      INFLUXDB_USER="${OPTARG}"
      ;;
    p) #influxdb admin password - used in case of [leader] node configurations only
      INFLUXDB_PWD="${OPTARG}"
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

join_metanodes()
{
  #joining meatanodes
  log "[influxd-ctl_add-meta] joining 3 metanodes to cluster"
  for i in $(seq 0 2); do 
    influxd-ctl add-meta  "vmmeta-${i}:8091"
  done
}

join_datanodes()
{
  #joining datanodes
  log "[influxd-ctl_add-data] joining ${COUNT} datanodes to cluster"

  END=`expr ${COUNT} - 1`
  for i in $(seq 0 "${END}"); do
    influxd-ctl add-data  "vmdata-${i}:8088"
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
       log "err: could not copy new ${META_CONFIG_FILE} file to /etc/influxdb"
      exit $EXIT_CODE
    fi
    
    #need to update the influxdb-meta.conf default values
    log  "[sed_cmd] updated ${META_CONFIG_FILE} default file values"

    chown influxdb:influxdb "${META_CONFIG_FILE}"

    #create etc/default/influxdb file to over-ride configuration defaults
    touch "${META_ENV_FILE}"
    if [ $? -eq 0 ]; then
      cat > "${META_ENV_FILE}" <<-EOF
        INFLUXDB_HOSTNAME="${HOSTNAME}"
        INFLUXDB_ENTERPRISE_MARKETPLACE_ENV="azure"
        INFLUXDB_META_DIR="/influxdb/meta"
        INFLUXDB_DATA_QUERY_LOG_ENABLED="false"
EOF
    else
      log  "err: cannot create /etc/default/influxdb file. you will need to manually configure the metanode"
      exit 1
    fi

    #create working dir for meatanode service
    log "[mkdir_cmd] creating metanode directory structure"

    mkdir -p "/influxdb/meta"
    chown -R influxdb:influxdb "/influxdb/"

  else
     log  "err: creating file ${META_GEN_FILE}. you will need to manually configure the metanode"
     exit 1
  fi

  start_service influxdb-meta 

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
       log "err: could not copy new ${DATA_GEN_FILE} file to /etc/influxdb"
      exit $EXIT_CODE
    fi

    #need to update the influxdb.conf default values
    log  "[sed_cmd] updated ${META_CONFIG_FILE} default file values"

    chown influxdb:influxdb "${DATA_CONFIG_FILE}"

    #create etc/default/influxdb file to over-ride configuration defaults
    touch "${DATA_ENV_FILE}"
    if [ $? -eq 0 ]; then
      cat > "${DATA_ENV_FILE}" <<-EOF
        INFLUXDB_HOSTNAME="${HOSTNAME}"
        INFLUXDB_ENTERPRISE_MARKETPLACE_ENV="azure"
        INFLUXDB_META_DIR="/influxdb/meta"
        INFLUXDB_DATA_DIR="/influxdb/data"
        INFLUXDB_DATA_WAL_DIR="/influxdb/wal"
        INFLUXDB_DATA_QUERY_LOG_ENABLED="false"
        INFLUXDB_DATA_INDEX_VERSION="tsi1"
        INFLUXDB_HTTP_FLUX_ENABLED="true"
        INFLUXDB_CLUSTER_LOG_QUERIES_AFTER="10s"
        INFLUXDB_HINTED_HANDOFF_DIR="/influxdb/hh"
EOF
    else
      log  "err: cannot create /etc/default/influxdb file. you will need to manually configure the datanode"
      exit 1
    fi

    #create working dirs and file for datanode service
    log "[mkdir_cmd] creating datanode directory structure"

    mkdir -p "/influxdb/meta"
    mkdir -p "/influxdb/data"
    mkdir -p "/influxdb/wal"
    mkdir -p "/influxdb/hh"
    chown -R influxdb:influxdb "/influxdb/"

  else
     log  "err: creating file ${DATA_GEN_FILE}. you will need to manually configure the metanode"
     exit 1
  fi
  start_service influxdb 
}
datanode_count()
{
    #checking to see if the $COUNT parameter is set 
  log "[datanode_count] checking COUNT parameter"

  if [ -z "${COUNT}" ]; then
    log "err: please set -c \$_COUNT parameter..."

    exit 1
  fi
}
telegraf()
{
  #generate and stage new telegraf configuration file
  log "[configure_telegraf] generating new telegraf configuration file at ${TELEGRAF_CONFIG_FILE}"

    touch "${TELEGRAF_CONFIG_FILE}"
    if [ $? -eq 0 ]; then
      cat > "${TELEGRAF_CONFIG_FILE}" <<-EOF
      #Global Agent Configuration
          [agent]
            hostname = "${HOSTNAME}"

          # Input Plugins
          [[inputs.cpu]]
              percpu = true
              totalcpu = true
              collect_cpu_time = false
              report_active = false
          [[inputs.disk]]
              ignore_fs = ["tmpfs", "devtmpfs", "devfs"]
          [[inputs.diskio]]
          [[inputs.mem]]
          [[inputs.net]]
          [[inputs.system]]
          [[inputs.swap]]
          [[inputs.netstat]]
          [[inputs.processes]]

          # Output Plugin InfluxDB
          [[outputs.influxdb]]
            database = "telegraf"
            urls = [ "http://vmmonitor:8086" ]
            username = "${INFLUXDB_USER}"
            password = "${INFLUXDB_PWD}"
EOF
    else
      log  "err: cannot create /etc/telegraf/telegraf.conf file. you will need to manually configure telegraf"
      exit 1
    fi
    
    chown telegraf:telegraf "${TELEGRAF_CONFIG_FILE}"

    start_service telegraf 
}
start_service()
{
   # s stores $1 service argument passed to start_service()
   s=$1
    #start service 
    systemctl start ${s}
    sleep 5

    if (systemctl -q is-active ${s}); then 
      log "info: ${s} service running."
    else
      log "err:  ${s} did not start, please check and restart manually."
      exit 1
    fi
}

create_user()
{
#check service status
log "[create_user] create influxdb admin user"

payload="q=CREATE USER ${INFLUXDB_USER} WITH PASSWORD '${INFLUXDB_PWD}' WITH ALL PRIVILEGES"

curl -s -k -X POST \
    -d "${payload}" \
    "http://vmdata-0:8086/query"
    
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


# format data disk (Find data disks then partition, format, and mount it
# as seperate drive under /influxdb/* )_
#------------------------
log "[autopart] running auto partitioning & mounting"

bash autopart.sh


if [[ ${SERVICE} == "meta" ]] || [[ ${SERVICE} == "leader" ]]; then
    log "[metanode_funcs] executing metanode configuration functions"

    configure_metanodes

elif [[ ${SERVICE} == "data" ]]; then
    log "[datanode_funcs] executing datanode configuration functions"
    
    configure_datanodes
else 
    log "err: service type unknown, please set a valid service"

    help
    exit 2
fi

#start telegraf service
#------------------------
telegraf


#leader funcs to join all nodes to cluster 
#------------------------
if [[ ${SERVICE} == "leader" ]];then
  log "[leader_metanode] executing cluster join commands on leader metanode"

  datanode_count

  join_metanodes

  join_datanodes

  create_user
fi

ELAPSED_TIME=$(($SECONDS - $START_TIME))
PRETTY=$(printf '%dh:%dm:%ds\n' $(($ELAPSED_TIME/3600)) $(($ELAPSED_TIME%3600/60)) $(($ELAPSED_TIME%60)))

log "End execution of InfluxEnterprise cluster congifuration script extension on ${HOSTNAME} in ${PRETTY}"
exit 0
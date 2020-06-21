#!/bin/bash

# License: https://github.com/influxdata/azure-resource-manager-influxdb-enterprise/blob/master/LICENSE
#
# Install IndluxDB OSS  ARM template cluster
#
# 06/2020 Initial Version
#--------------------------

help()
{
    echo " "
    echo "This script configures a new InfluxDB OSS node for monitoring the enterprise cluster deployed with Azure ARM templates."
    echo "Parameters:"
    echo "-u  Supply influxdb admin username"
    echo "-p  Supply influxdb admin password"
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
     echo \[$(date +%d%m%Y-%H:%M:%S)\] "$1" >> /var/log/oss-install.log
}

log "Begin execution of InfluxDB OSS script extension on ${HOSTNAME}"
START_TIME=$SECONDS

#########################
# Check user access
#########################

if [ "${UID}" -ne 0 ];
then
    log "Script executed without root permissions"
    echo "You must be root to run this program." >&2
    exit 3
fi

#Loop through options passed
while getopts :c:u:p:h optname; do
  log "Option $optname set"
  case $optname in
    c) #number os datanodes
      COUNT="${OPTARG}"
      ;;
    u) #influxdb admin username
      INFLUXDB_USER="${OPTARG}"
      ;;
    p) #influxdb admin password
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
# Parameter handling
#########################

#Script Parameters
OSS_VERSION="1.8.0"

#########################
# Installation func
#########################

install_chronograf()
{
    local PACKAGE="chronograf_${OSS_VERSION}_amd64.deb"
    local DOWNLOAD_URL="https://dl.influxdata.com/influxdb/releases/influxdb_${OSS_VERSION}_amd64.deb"

    log "[install_influxdb_oss] download InfluxDB $OSS_VERSION"
    log "[install_influxdb_oss] download location $DOWNLOAD_URL"

    wget --retry-connrefused --waitretry=1 -q "$DOWNLOAD_URL" -O $PACKAGE
    EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
        log "err: downloading InfluxDB $OSS_VERSION..."
        exit $EXIT_CODE
    fi
    log "[install_influxdb_oss] downloaded InfluxDB $OSS_VERSION"

    log "[install_chroinstall_influxdb_ossnorgaf] installing InfluxDB $OSS_VERSION"
    dpkg -i $PACKAGE
    log "[install_influxdb_oss] installed InfluxDB $OSS_VERSION"
}
create_user()
{
#check service status
log "[create_user] create influxdb admin user"

payload="q=CREATE USER ${INFLUXDB_USER} WITH PASSWORD '${INFLUXDB_PWD}' WITH ALL PRIVILEGES"

curl -s -k -X POST \
    -d "${payload}" \
    "http://vmmonitor:8086/query"
    
}
configure_systemd()
{
    log "[configure_systemd] configure systemd to start InfluxDB service automatically when system boots"
    systemctl daemon-reload
    systemctl enable chronograf.service
}

start_systemd()
{
    log "[start_systemd] starting InfluxDB"
    systemctl start influxdb.service
    log "[start_systemd] started InfluxDB"
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

install_chronograf

configure_systemd

start_systemd

ELAPSED_TIME=$(($SECONDS - $START_TIME))
PRETTY=$(printf '%dh:%dm:%ds\n' $(($ELAPSED_TIME/3600)) $(($ELAPSED_TIME%3600/60)) $(($ELAPSED_TIME%60)))
log "End execution of InfluxDB script extension in ${PRETTY}"
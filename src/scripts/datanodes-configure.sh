#!/bin/bash

# License: https://github.com/influxdata/azure-resource-manager-influxdb-enterprise/blob/master/LICENSE
#
# Install Chronorgaf InfluxEnterprise ARM template cluster
# Initial Version

help()
{
    echo "This script finishes the datanode configuration for the  InfluxEnterprise cluster on Ubuntu"
    echo "Parameters:"
    echo "-h view this help content"
}

# Log method to control/redirect log output
log()
{
    # If you want to enable this logging add a un-comment the line below and add your account id
    #curl -X POST -H "content-type:text/plain" --data-binary "${HOSTNAME} - $1" https://logs-01.loggly.com/inputs/<key>/tag/es-extension,${HOSTNAME}
    echo "$1"
}

log "Begin execution of InfluxEnterprise script extension on ${HOSTNAME}"

if [ "${UID}" -ne 0 ];
then
    log "Script executed without root permissions"
    echo "You must be root to run this program." >&2
    exit 3
fi


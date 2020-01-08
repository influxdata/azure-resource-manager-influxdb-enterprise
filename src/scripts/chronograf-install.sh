#!/bin/bash

# License: https://github.com/influxdata/azure-resource-manager-influxdb-enterprise/blob/master/LICENSE.txt
#
# Craig Hobbs, InfluxData Inc.
# Initial Version
#

#########################
# HELP
#########################

help()
{
    echo "This script installs Chronograf on a dedicated VM in the InfluxEnterprise ARM template cluster"
    echo ""
    echo " -h      view this help content"
}

# Custom logging with time so we can easily relate running times, also log to separate file so order is guaranteed.
# The Script extension output the stdout/err buffer in intervals with duplicates.
log()
{

     echo \[$(date +%d%m%Y-%H:%M:%S)\] "$1"
     echo \[$(date +%d%m%Y-%H:%M:%S)\] "$1" >> /var/log/arm-install.log
}

log "Begin execution of Chronograf script extension on ${HOSTNAME}"
START_TIME=$SECONDS

#########################
# Preconditions
#########################

if [ "${UID}" -ne 0 ];
then
    log "Script executed without root permissions"
    echo "You must be root to run this program." >&2
    exit 3
fi

#########################
# Parameter handling
#########################

#Script Parameters
CHRONOGRAF_VERSION="1.7.16"

#########################
# Installation steps as functions
#########################

random_password()
{
  < /dev/urandom tr -dc '!@#$%_A-Z-a-z-0-9' | head -c${1:-64}
  echo
}

install_chronograf()
{
    local PACKAGE="chronograf_1.7.16_amd64.deb"
    local DOWNLOAD_URL="https://dl.influxdata.com/chronograf/releases/chronograf_1.7.16_amd64.deb"

    log "[install_chronograf] download Chronograf $CHRONOGRAF_VERSION"
    log "[install_chronograf] download location $DOWNLOAD_URL"

    wget --retry-connrefused --waitretry=1 -q "$DOWNLOAD_URL" -O $PACKAGE
    EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
        log "[install_chronograf] error downloading Chronograf $CHRONOGRAF_VERSION"
        exit $EXIT_CODE
    fi
    log "[install_chronograf] downloaded Chronograf $CHRONOGRAF_VERSION"

    log "[install_chronorgaf] installing Chronorgaf $CHRONOGRAF_VERSION"
    dpkg -i $PACKAGE
    log "[install_chronograf] installed Chronograf $CHRONOGRAF_VERSION"
}


install_apt_package()
{
  local PACKAGE=$1
  if [ $(dpkg-query -W -f='${Status}' $PACKAGE 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    log "[install_$PACKAGE] installing $PACKAGE"
    (apt-get -yq install $PACKAGE || (sleep 15; apt-get -yq install $PACKAGE))
    local EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
      "[install_$PACKAGE] installing $PACKAGE returned non-zero exit code: $EXIT_CODE"
      exit $EXIT_CODE
    fi
    log "[install_$PACKAGE] installed $PACKAGE"
  else
    log "[install_$PACKAGE] already installed $PACKAGE"
  fi
}

configure_systemd()
{
    log "[configure_systemd] configure systemd to start Chronograf service automatically when system boots"
    systemctl daemon-reload
    systemctl enable chronograf.service
}

start_systemd()
{
    log "[start_systemd] starting Chronorgaf"
    systemctl start chronograf.service
    log "[start_systemd] started Chronograf"
}

#########################
# Installation sequence
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
log "End execution of Chronorgaf script extension in ${PRETTY}"
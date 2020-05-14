#!/usr/bin/env bash

set -euxo pipefail

curl -s "https://dl.influxdata.com/enterprise/releases/influxdb-data_$1-c$1_amd64.deb" --output "influxdb-data_$1-c$1_amd64.deb"
sudo dpkg -i "influxdb-data_$1-c$1_amd64.deb"
rm "influxdb-data_$1-c$1_amd64.deb"
sudo systemctl stop influxdb.service
sudo systemctl disable influxdb.service
cat /tmp/config/influxdb-data.conf /etc/influxdb/influxdb.conf > influxdb.conf.temp
sudo rm /etc/influxdb/influxdb.conf
sudo mv influxdb.conf.temp /etc/influxdb/influxdb.conf
sudo chown -R influxdb:influxdb /etc/influxdb/influxdb.conf

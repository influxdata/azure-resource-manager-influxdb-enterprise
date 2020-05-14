#!/usr/bin/env bash

set -euxo pipefail

curl -s "https://dl.influxdata.com/chronograf/releases/chronograf-$1.x86_64.deb" --output "chronograf-$1.x86_64.deb"
sudo dpkg -i "chronograf-$1.x86_64.deb"
rm "chronograf-$1.x86_64.deb"
sudo systemctl stop chronograf.service
sudo systemctl disable chronograf.service

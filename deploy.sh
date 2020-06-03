#!/usr/bin/env bash

set -euxo pipefail

# If this script fails, check whether the current Azure CLI subscription ID the
# same one used to created the managed disk. The following command will show the
# current subscription.
#
# az account show --query "id" --output tsv
#
# The following command can be used to update the subscription ID.
#
# az account set --subscription <subscription-id>

# check if resource group exist, if not proceed with creating a resource group for this deployment

readonly resource_group="${1}"
readonly location="${2:-$(az configure --list-defaults --output tsv --query "[?starts_with(name, 'location')].value")}"

if ! (az group show --name "${resource_group}"); then
      echo -e "Creating new resource group: \"${resource_group}\"\n"
      az group create --name "${resource_group}" --location "${location}" --output table
fi

# Accept the legal terms for the influxdata offer skus (only needs ti be run once for your sunscritopn ID)
if ! (az vm image terms show --urn influxdata:influxdb-enterprise-vm:data:latest --query "accepted"); then
      az vm image terms accept --urn influxdata:influxdb-enterprise-vm:data:latest
      az vm image terms accept --urn influxdata:influxdb-enterprise-vm:meta:latest
fi

az deployment group create \
      --resource-group "${resource_group}" \
      --template-file src/mainTemplate.json \
      --verbose \
      --mode Complete \
      --parameters parameters/parameters.json

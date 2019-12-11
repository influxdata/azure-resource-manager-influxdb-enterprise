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

readonly deployment_name="${1}"
readonly region="${2:-$(az configure --list-defaults --query "[?starts_with(name, 'location')].value" --output tsv)}"
readonly group="${3:-$(az configure --list-defaults --query "[?starts_with(name, 'group')].value" --output tsv)}"

readonly template="packer/vm-test.json"

# az group create --name "${group}" --location "${region}" --output table

az group deployment create \
    --name "${deployment_name}" \
    --resource-group "${group}" \
    --mode Incremental \
    --verbose \
    --template-file "${template}" \
    --parameters @parameters/parameters.json \
    --output table

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

readonly snapshot_name="${1}"
readonly destination_VHD_file_name="${1}.vhd"
readonly resource_group="partnerEng"
readonly storage_account="influxdata"
readonly storage_container="vhds"
readonly storage_account_key="${2:-$(az storage account keys list --account-name "${storage_account}" --resource-group "${resource_group}" --output "tsv" --query "[0].value")}"
readonly sas_duration="3600"

sas=$(az snapshot grant-access --duration-in-seconds "${sas_duration}" --name "${snapshot_name}" --resource-group "${resource_group}" --query "accessSas" --output "tsv")

az storage blob copy start \
    --account-name "${storage_account}" \
    --account-key "${storage_account_key}" \
    --source-uri "${sas}" \
    --destination-blob "${destination_VHD_file_name}" \
    --destination-container "${storage_container}"

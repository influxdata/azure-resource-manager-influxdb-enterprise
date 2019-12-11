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

readonly source_VHD_file_name="${1}"
readonly resource_group="partnerEng"
readonly storage_account="influxdata"
readonly storage_container="vhds"
readonly storage_account_key="$(az storage account keys list --account-name "${storage_account}" --resource-group "${resource_group}" --output "tsv" --query "[0].value")"
readonly start="$(gdate --utc -d '-1 days' +%Y-%m-%dT%H:%M:%SZ)"
readonly expiry="$(gdate --utc -d '+21 days' +%Y-%m-%dT%H:%M:%SZ)"

# sas=$(az snapshot grant-access --duration-in-seconds "${sas_duration}" --name "${snapshot_name}" --resource-group "${resource_group}" --query "accessSas" --output tsv)

sas=$( \
az storage container generate-sas \
    --account-name "${storage_account}" \
    --account-key "${storage_account_key}" \
    --https-only \
    --permissions "rl" \
    --name "${storage_container}" \
    --start "${start}" \
    --expiry "${expiry}" \
    --output "tsv" \
)

az storage blob url \
    --account-name "${storage_account}" \
    --account-key "${storage_account_key}" \
    --container-name "${storage_container}" \
    --sas-token "${sas}" \
    --name "${source_VHD_file_name}" \
    --output "tsv"

# OSDiskData201912090825.vhd
# https://influxdata.blob.core.windows.net/vhds/OSDiskData201912090825.vhd
# --connection-string 'DefaultEndpointsProtocol=https;AccountName=st00009;AccountKey=6L7OWFrlabs7Jn23OaR3rvY5RykpLCNHJhxsbn9ONc+bkCq9z/VNUPNYZRKoEV1FXSrvhqq3aMIDI7N3bSSvPg==;EndpointSuffix=core.windows.net' \
# https://influxdata.blob.core.windows.net/vhds/OSDiskData201912090825.vhd.vhd?se=2019-12-30T11%3A26%3A20Z&sp=rl&spr=https&sv=2018-11-09&sr=c&sig=Bcnlz1e7ObhXtv4uDp7akpQ2qLom7mAzVNnWsRASSwg%3D

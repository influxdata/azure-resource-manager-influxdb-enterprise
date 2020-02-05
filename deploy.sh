#!/usr/bin/env bash

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


echo "Enter the Resource Group name:" &&
read resourceGroupName &&
echo "Enter the location [ie centralus, westus]:" &&
read location &&

rgvar="$((az group show --name $resourceGroupName 2>&1) | grep 'could not be found')"
if [ -n "$rgvar" ]
then
      echo -e "\nThe resourceGroup $resourceGroupName does not exist and will be created\n"
      az group create --name "${resourceGroupName}" --location "${location}" --output table
else
      echo -e "Confirmed resourceGroup $resourceGroupName exist and will be used\n"
fi
# accept the legal terms for the influxdata offer skus (only needs ti be run once for your sunscritopn ID)
echo -e "\nRuning Azure commands to accepting 'Legal Terms' for InfliuxData offer data-node sku\n" 
az vm image terms accept --urn influxdata:influxdb-enterprise-vm:data:1.7.90
echo -e "\nRuning Azure commands to accepting 'Legal Terms' for InfliuxData offer meta-node sku\n" 
az vm image terms accept --urn influxdata:influxdb-enterprise-vm:meta:1.7.90

az group deployment create \
--template-file src/mainTemplate.json \
--verbose \
--resource-group "${resourceGroupName}" \
--mode Incremental \
--parameters parameters/password.parameters.json
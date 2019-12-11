# InfluxDB Enterprise Azure Resource Manager Templates

__Note: These templates are still under active development. They are not recommended for production.__

## Publishing a new image

### Generate a SAS

A Shared Access Signature (SAS) URL is required by the Partner Portal to import a VHD ([official guide](https://docs.microsoft.com/en-us/azure/marketplace/cloud-partner-portal/virtual-machine/cpp-get-sas-uri)).
Packer is used to build the images and will only create managed disks.
In order to create the SAS URL, the underlying VHD of the managed disk needs to be extracted and put in a storage account.
The  script that handles the steps in [this guide](https://docs.microsoft.com/en-us/azure/virtual-machines/scripts/virtual-machines-linux-cli-sample-copy-managed-disks-vhd) provides instructions on how to extract the VHD and create the SAS URL.

## Links

## Video explanation of Azure Application development
https://docs.microsoft.com/en-us/azure/marketplace/cloud-partner-portal/azure-applications/cpp-create-technical-assets
https://www.youtube.com/watch?time_continue=1&v=GdcmjIiK0Vk

## Azure portal management
[partner portal](https://cloudpartner.azure.com/#alloffers)
[old version](https://docs.microsoft.com/en-us/azure/marketplace/cloud-partner-portal-orig/cloud-partner-portal-getting-started-with-the-cloud-partner-portal)
[current version](https://docs.microsoft.com/en-us/azure/marketplace/cloud-partner-portal/portal-manage/cpp-portal-management)

## VM instructions
https://docs.microsoft.com/en-us/azure/marketplace/cloud-partner-portal/virtual-machine/cpp-virtual-machine-offer
https://docs.microsoft.com/en-us/azure/marketplace/cloud-partner-portal/virtual-machine/cpp-create-technical-assets#52-get-the-shared-access-signature-uri-for-your-vm-images
[SAS URL instructions](https://docs.microsoft.com/en-us/azure/marketplace/cloud-partner-portal/virtual-machine/cpp-get-sas-uri)

## VM Security
https://docs.microsoft.com/en-us/azure/security/fundamentals/azure-marketplace-images

## Ubuntu on Azure
[Prepare Ubuntu for Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-upload-ubuntu)
[Ubuntu Bionic 18.04 VHDs for Azure](https://cloud-images.ubuntu.com/bionic/current/)

## Instance metadata
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service#getting-more-information-about-the-vm-during-support-case
[issue to add metadata support to go SDK](https://github.com/Azure/azure-sdk-for-go/issues/982)
[issue to document metadata rest api spec](https://github.com/Azure/azure-rest-api-specs/issues/4408)

## Packer docs
https://www.packer.io/docs/builders/azure-arm.html#storage_account
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer
[Packer Azure examples](https://github.com/hashicorp/packer/tree/master/examples/azure)
[Deprecation issue](https://github.com/hashicorp/packer/issues/8217)
[Issue](https://github.com/hashicorp/packer/issues/6752)
[Azure docs issue](https://github.com/MicrosoftDocs/azure-docs/issues/37716)
[Shared Image Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/shared-image-galleries)

## Scripts
[Export/Copy a managed disk to a storage account using the Azure CLI](https://docs.microsoft.com/en-us/azure/virtual-machines/scripts/virtual-machines-linux-cli-sample-copy-managed-disks-vhd?toc=%2fcli%2fmodule%2ftoc.json)
[Deploy a virtual machine from the Azure Marketplace](https://docs.microsoft.com/en-us/azure/marketplace/cloud-partner-portal/virtual-machine/cpp-deploy-vm-marketplace)
[Create a managed disk from a snapshot with PowerShell](https://docs.microsoft.com/en-us/azure/virtual-machines/scripts/virtual-machines-windows-powershell-sample-create-managed-disk-from-snapshot)
[create managed disk from snapshot and attach it to the VM](https://github.com/KacperMucha/random-powershell-scripts/blob/master/New-AzureRmVmFromSnapshot.ps1)
[Copy a managed disk](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disks-upload-vhd-to-managed-disk-cli#copy-a-managed-disk)
[Export/Copy the VHD of a managed disk to a storage account in different region with PowerShell](https://docs.microsoft.com/en-us/azure/virtual-machines/scripts/virtual-machines-windows-powershell-sample-copy-managed-disks-vhd)

# ARM templates

## AWS to Azure mappings
https://docs.microsoft.com/en-us/azure/architecture/aws-professional/services

## Azure Applications Solution Template Offer Publishing Guide
https://docs.microsoft.com/en-us/azure/marketplace/marketplace-solution-templates

## ARM Quickstarts
https://github.com/Azure/azure-quickstart-templates
https://github.com/couchbase-partners/azure-resource-manager-couchbase/tree/master/marketplace

## ARM Template Best Practices
https://docs.microsoft.com/en-us/azure/azure-resource-manager/template-best-practices

## How to managed disks in ARM
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/using-managed-disks-template-deployments

# Post launch

## Customer usage attribution (GUID)
https://docs.microsoft.com/en-us/azure/marketplace/azure-partner-customer-usage-attribution

## Microsoft Partner portal
https://partner.microsoft.com/en-US/

## Azure Marketplace forum
https://www.microsoftpartnercommunity.com/t5/Microsoft-AppSource-and-Azure/bd-p/2222

## Azure Marketplace support
https://support.microsoft.com/en-us/supportforbusiness/requests


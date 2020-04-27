# InfluxEnterprise Azure Marketplace offering

__Note: These templates are still under active development. They are not recommended for production.__

## Publishing a new image

This repository consists of:

* [ARM templates for InfluxDB Enterprise](src/)
* [Packer templates for Azure images](packer/)

* [src/mainTemplate.json](src/mainTemplate.json) - Entry Azure Resource Management (ARM) template.
* [src/createUiDefinition](src/createUiDefinition.json) - UI definition file for our market place offering. This file produces an output JSON that the ARM template can accept as input parameters JSON.

## ARM template

The output from the market place UI is fed directly to the ARM template. You can use the ARM template on its own without going through the market place.

### Parameters

<table>
  <tr><th>Parameter</td><th>Type</th><th>Description</th></tr>
  <tr><td>loadBalancerType</td><td>string</td>
    <td>Whether the loadbalancer should be <code>internal</code> or <code>external</code>
    </td></tr>

  <tr><td>chronograf</td><td>string</td>
    <td>Either <code>Yes</code> or <code>No</code> provision an extra machine with a public IP tha thas Chronograf installed on it.
    This can also be used as a jumpbox to connect and manage other virtual machines on the internal network.
    </td></tr>

  <tr><td>vmSizeDataNodes</td><td>string</td>
    <td>Azure VM size of the data nodes see <a href="https://github.com/influxdata/azure-resource-manager-influxdb-enterprise/blob/master/src/mainTemplate.json#L69">this list for supported sizes</a>
    </td></tr>

  <tr><td>vmDataNodeCount</td><td>int</td>
    <td>The number of datanodes you wish to deploy. (Min: 2 | Max: 8).
    </td></tr>

  <tr><td>vmDataNodeDiskSize</td><td>string</td>
    <td>The disk size of the attached data disk. Choose <code>1TiB</code>, <code>512GiB</code>, <code>256GiB</code>, <code>128GiB</code>, <code>64GiB</code> or <code>32GiB</code>.
    </td>

  <tr><td>vmSizeMetaNodes</td><td>string</td>
    <td>Azure VM size of the meta nodes. The template will provision (3) nodes, please see <a href="https://github.com/influxdata/azure-resource-manager-influxdb-enterprise/blob/master/src/mainTemplate.json#L91"> for list of recommended sizes</a>
    </td></tr>

  <tr><td>adminUsername</td><td>string</td>
    <td>Admin username used when provisioning virtual machines
    </td></tr>

  <tr><td>password</td><td>object</td>
    <td>Password is a complex object parameter, we support both authenticating through username/pass or ssh keys. See the <a href="https://github.com/influxdata/azure-resource-manager-influxdb-enterprise/tree/master/parameters"> parameters example folder</a> for an example of what to pass for either option.
    </td></tr>

  <tr><td>influxdbUsername</td><td>securestring</td>
    <td>InfluxDB username for the <code>admin</code> user with all privileges
    </td></tr>

  <tr><td>influxdbPassword</td><td>securestring</td>
    <td>InfluxDB password for the <code>admin</code> user with all privileges, must be &gt; 6 characters
    </td></tr>

  <tr><td>location</td><td>string</td>
    <td>The location where to provision all the items in this template. Defaults to the special <code>ResourceGroup</code> value which means it will inherit the location
    from the resource group see <a href="https://github.com/influxdata/azure-resource-manager-influxdb-enterprise/blob/master/src/mainTemplate.json#L197">this list for supported locations</a>.
    </td></tr>

</table>

### Command line deploy

The `deploy.sh` script in the root of this repo can be used to easily deploy an InfluxDB Enterprise cluster via the Azure CLI.

Begin by [installing the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) and logging in.

```shell
$ az login
```

**Note: The `deploy.sh` script will automatically accept terms for and deploy paid InfluxDB Enterprise images in your Azure Marketplace account.**

Create a new configuration file called `parameters/parameters.json` for your deployment by copying one of the example files provided in the [`parameters/`](parameters/) directory.

```shell
$ cp parameters/ssh.parameters.json parameters/parameters.json
```

Edit the configuration file parameters you'd like to use for your deployment. Don't forget to update the `password` object with a new password or your SSH key.

Now run the `deploy.sh <resource-group-name>` script in the root of this repo to create a cluster in the specified resource group. A new resource group will be created automatically if it doesn't exist.

```shell
$ ./deploy.sh test-cluster
```

After the initial creation, you can continue to publish *Incremental* deployments using one of the following commands.
You can published this repo template directly using `--template-uri`

> az group deployment create --template-uri https://raw.githubusercontent.com/influxdata/azure-resource-manager-influxdb-enterprise/master/src/mainTemplate.json --verbose --resource-group "${group}" --mode Incremental --parameters parameters/password.parameters.json

or if your are executing commands from a clone of this repo using `--template-file`

> az group deployment create --template-file src/mainTemplate.json --verbose --resource-group "${group}" --mode Incremental --parameters parameters/password.parameters.json

`<group>` in these last two examples refers to the resource group created by the deploy.sh script.

**NOTE**

The `--parameters` can specify a different location for the items that get provisioned inside of the resource group. Make sure these are the same prior to deploying if you need them to be. Omitting location from the parameters file is another way to make sure the resources get deployed in the same location as the resource group.


### Web based deploy

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Finfluxdata%2Fazure-resource-manager-influxdb-enterprise%2Fmaster%2Fsrc%2FmainTemplate.json" target="_blank">
   <img alt="Deploy to Azure" src="http://azuredeploy.net/deploybutton.png"/>
</a>

The above button will take you to the autogenerated web based UI based on the parameters from the ARM template.

It should be pretty self explanatory except for password which only accepts a json object. Luckily the web UI lets you paste json in the text box. Here's an example:

> {"sshPublicKey":null,"authenticationType":"password", "password":"Password1234"}

### What's deployed

The ARM template will deploy a number of resources.

Generally, all resource naming follows the [Azure resource naming recommendations](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging) provided by Microsoft.

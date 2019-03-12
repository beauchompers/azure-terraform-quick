# Azure Quick Terraform Plan

Quick Terraform plan to provision a number of Linux and/or Windows VMs on Azure.

The machine types are hard coded to Ubuntu 18.04 LTS and Windows 2016 DC, but other things like location, size,etc are paramaterized.  In addition the script creates a Network Security Group with port 22 and 3389 open to an IP or IP range(s) of your choosing.

## Pre-Reqs

You'll need to set your variables in terraform.tfvars, see variables.tf for what is required.  In addition this makes use of the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest), so you'll need to install that too.  You can use this little script to login to your Azure subscription as well once you've got the CLI installed:

```console
#! /bin/bash
az login
az account set --subscription Name-Of-Your-Subscription
az account show
```

## Usage

Set the number of instances for linux or windows using the linux_instances or windows_instances variable.

```console
terraform init     # initialize terraform
terraform plan     # to see what it will do
terraform apply    # to build stuff
terraform destroy  # to blow up
```

# Variables 

# common prefix for things, used in tags and resource group name
variable "prefix" {
  default = "playground"
}

# azure location
variable "location" {
    default = "eastus"
}

# source ip addresses for nsg, list of ips like ["1.1.1.1", "2.2.2.2"]
variable "nsgsourceips" {
    type = "list"
}

# number of linux instances to provision
variable "linux_instances" {
    default = 1
}

# number of windows instances to provision
variable "windows_instances" {
    default = 0
}

# linux vm information
variable "linuxvmsize" {
    default = "Standard_B1ms"
}

# storage type, i.e. Premium_LRS or Standard_LRS
variable "linuxvmdisktype" {
    default = "Premium_LRS"
}

# windows vm information
variable "winvmsize" {
    default = "Standard_B1ms"
}

# storage type, i.e. Premium_LRS or Standard_LRS
variable "winvmdisktype" {
    default = "Premium_LRS"
}

# username, sshkey, and/or password for the linux and windows vms
variable "username" {
    default = "azureuser"
}

# password for windows, or key for linux
variable "password" {}
  
variable "sshkey" {}

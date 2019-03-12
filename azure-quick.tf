# terraform plan to provision test linux/windows machines on azure

# Configure the Microsoft Azure Provider
provider "azurerm" {
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "main" {
    name     = "${var.prefix}-resources"
    location = "${var.location}"

    tags {
        environment = "${var.prefix}"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "main" {
    name                = "${var.prefix}-vNet"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.main.name}"

    tags {
        environment = "${var.prefix}"
    }
}

# Create subnet
resource "azurerm_subnet" "public" {
    name                 = "${var.prefix}-public"
    resource_group_name  = "${azurerm_resource_group.main.name}"
    virtual_network_name = "${azurerm_virtual_network.main.name}"
    address_prefix       = "10.0.8.0/24"
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "main" {
    name                = "${var.prefix}-nsg"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.main.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefixes     = ["${var.nsgsourceips}"]
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "RDP"
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefixes     = ["${var.nsgsourceips}"]
        destination_address_prefix = "*"
    }

    tags {
        environment = "${var.prefix}"
    }
}


# Virtual machine specific configuration

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "main" {
    #count                       = "${var.number}"
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.main.name}"
    location                    = "${var.location}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "${var.prefix}"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.main.name}"
    }

    byte_length = 8
}

# VM Specific 

# Create public IPs for Linux Machines
resource "azurerm_public_ip" "linux" {
    count                        = "${var.linux_instances}"
    name                         = "${var.prefix}-linPublicIp-${count.index+1}"
    location                     = "${var.location}"
    resource_group_name          = "${azurerm_resource_group.main.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "${var.prefix}"
        os = "linux"
    }
}

# Create network interfaces for Linux Machines
resource "azurerm_network_interface" "linux" {
    count                     = "${var.linux_instances}"
    name                      = "${var.prefix}-linNic-${count.index+1}"
    location                  = "${var.location}"
    resource_group_name       = "${azurerm_resource_group.main.name}"
    network_security_group_id = "${azurerm_network_security_group.main.id}"

    ip_configuration {
        name                          = "${var.prefix}-linNicConfiguration-0${count.index+1}"
        subnet_id                     = "${azurerm_subnet.public.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${element(azurerm_public_ip.linux.*.id, count.index)}"
    }

    tags {
        environment = "${var.prefix}"
        os = "linux"
    }
}

# Create Linux virtual machines
resource "azurerm_virtual_machine" "linux" {
    count                 = "${var.linux_instances}"
    name                  = "${var.prefix}-linux-0${count.index+1}"
    location              = "${var.location}"
    resource_group_name   = "${azurerm_resource_group.main.name}"
    network_interface_ids = ["${element(azurerm_network_interface.linux.*.id, count.index)}"]
    vm_size               = "${var.linuxvmsize}"

    storage_os_disk {
        name              = "${var.prefix}-linOsDisk-0${count.index+1}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "${var.linuxvmdisktype}"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "linux-0${count.index+1}"
        admin_username = "${var.username}"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${var.sshkey}"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.main.primary_blob_endpoint}"
    }

    tags {
        environment = "${var.prefix}"
        os = "linux"

    }
}

# Windows VMs

# Create public IPs for Windows Machines
resource "azurerm_public_ip" "windows" {
    count                        = "${var.windows_instances}"
    name                         = "${var.prefix}-winPublicIp-${count.index+1}"
    location                     = "${var.location}"
    resource_group_name          = "${azurerm_resource_group.main.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "${var.prefix}"
        os = "windows"
    }
}

# Create network interfaces for Windows Machines
resource "azurerm_network_interface" "windows" {
    count                     = "${var.windows_instances}"
    name                      = "${var.prefix}-winNic-${count.index+1}"
    location                  = "${var.location}"
    resource_group_name       = "${azurerm_resource_group.main.name}"
    network_security_group_id = "${azurerm_network_security_group.main.id}"

    ip_configuration {
        name                          = "${var.prefix}-winNicConfiguration-0${count.index+1}"
        subnet_id                     = "${azurerm_subnet.public.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${element(azurerm_public_ip.windows.*.id, count.index)}"
    }

    tags {
        environment = "${var.prefix}"
        os = "windows"
    }
}

# Create Windows virtual machines
resource "azurerm_virtual_machine" "windows" {
    count                 = "${var.windows_instances}"
    name                  = "${var.prefix}-windows-0${count.index+1}"
    location              = "${var.location}"
    resource_group_name   = "${azurerm_resource_group.main.name}"
    network_interface_ids = ["${element(azurerm_network_interface.windows.*.id, count.index)}"]
    vm_size               = "${var.winvmsize}"

    storage_os_disk {
        name              = "${var.prefix}-winOsDisk-0${count.index+1}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "${var.winvmdisktype}"
    }

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
    }

    os_profile {
        computer_name  = "windows-0${count.index+1}"
        admin_username = "${var.username}"
        admin_password = "${var.password}"
    }

    os_profile_windows_config {

    }
    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.main.primary_blob_endpoint}"
    }

    tags {
        environment = "${var.prefix}"
        os = "windows"
    }
}

# outputs
# run terraform refresh after apply to get the azure public ips, it's a feature.

output "ansible_linux_hosts" {
  description = "List of hosts for Ansible Hosts File"
  value = "\n[azure]\n${join("\n", azurerm_public_ip.linux.*.ip_address)}"
}

output "linux_public_ip_addresses" {
  description = "Public IP addresses for Linux Servers"
  value = ["${azurerm_public_ip.linux.*.ip_address}"]
}

output "linux_private_ip_addresses" {
  description = "Private IP addresses for Linux Servers"
  value       = "${azurerm_network_interface.linux.*.private_ip_address}"
}

output "windows_public_ip_addresses" {
  description = "IP addresses for Windows Servers"
  value = ["${azurerm_public_ip.windows.*.ip_address}"]
}

output "windows_private_ip_addresses" {
  description = "Private IP addresses for Windows Servers"
  value       = "${azurerm_network_interface.windows.*.private_ip_address}"
}
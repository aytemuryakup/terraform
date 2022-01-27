provider "azurerm" {
  features {}
}
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.39.0"
    }
  }
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_prefix}-rg"
  location = var.location
  tags = {
    "Environment" = "Dev"
    "Team"        = "DevOps"
  }
}

# Create a VNet within the resource group
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_prefix}-vnet"
  address_space       = var.address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a subnets withing the VNet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.address_prefix
}

# Create Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.resource_prefix}-publicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label   = "${var.resource_prefix}"
  tags = {
    "environment" = "dev"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                = "${var.resource_prefix}-NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Creating NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.resource_prefix}-NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Inbound-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Outbound-all"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    "environment" = "dev"
  }
}

# Subnet and NSG association
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_folder" {
    content  = tls_private_key.example_ssh.private_key_pem
    filename = "ssh-login.pem"
    file_permission = "0400"
}
# Virtual machine creation - Linux
resource "azurerm_linux_virtual_machine" "linux-vm" {
  name                             = "${var.resource_prefix}"
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
  network_interface_ids            = [azurerm_network_interface.nic.id]
  size                             = "${var.vm_size}"
  source_image_reference {
    publisher = "${var.vmOSpublisher}"
    offer     = "${var.vmOSoffer}"
    sku       = "${var.vmOSsku}"
    version   = "${var.vmOSversion}"
  }
  os_disk {
    name              = "myosdisk"
    caching           = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  admin_ssh_key {
    username   = var.username
    public_key = tls_private_key.example_ssh.public_key_openssh
  }
    computer_name  = "jenkins"
    admin_username = var.username
    disable_password_authentication = true

  tags = {
    environment = "dev"
  }
  connection {
    type        = "ssh"
    host        = azurerm_public_ip.public_ip.ip_address
    private_key = tls_private_key.example_ssh.private_key_pem
    user        = var.username
    timeout     = "1m"
  }

  provisioner "file" {
    source      = "./install-jenkins.sh"
    destination = "/home/${var.username}/install-jenkins.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /home/${var.username}/install-jenkins.sh",
      "sudo /home/${var.username}/install-jenkins.sh"
    ]
  }
}
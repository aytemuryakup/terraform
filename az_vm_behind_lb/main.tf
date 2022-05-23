provider "azurerm" {
  features {}
}
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.7.0"
    }
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_prefix}-rg"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_prefix}-vnet"
  address_space       = var.address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.address_prefix
  #service_endpoints    = ["Microsoft.Storage","Microsoft.Sql"]
}

# Create public IP for lb
resource "azurerm_public_ip" "publicip" {
    name                         = "${var.resource_prefix}-publicIP"
    location                     = azurerm_resource_group.rg.location
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Static"
    domain_name_label            = "${var.resource_prefix}-lb"
    tags                         = var.tags
    sku                          = var.lb_sku
}

# Creating NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.resource_prefix}-NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

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
}

resource "azurerm_linux_virtual_machine" "linux-vm" {
  count                            = var.node_count
  name                             = "${var.resource_prefix}-${format("%02d", count.index)}"
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
  network_interface_ids            = [element(azurerm_network_interface.nic.*.id, count.index)]
  tags                             = var.tags
  size                             = "${var.vm_size}"
  source_image_reference {
    publisher = "${var.vmOSpublisher}"
    offer     = "${var.vmOSoffer}"
    sku       = "${var.vmOSsku}"
    version   = "${var.vmOSversion}"
  }
  os_disk {
    name              = "myosdisk-${count.index}"
    caching           = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  
  computer_name  = "${var.resource_prefix}-${format("%02d", count.index)}"
  admin_username = var.username
  admin_password = var.password
  disable_password_authentication = false

}

# Create network interface
resource "azurerm_network_interface" "nic" {
  count               = var.node_count
  name                = "${var.resource_prefix}-${format("%02d", count.index)}-NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id          = element(azurerm_public_ip.publicip_vm.*.id, count.index)
  }
}
# Subnet and NSG association
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# create nat rule association
# resource "azurerm_network_interface_nat_rule_association" "natrule" {
#     network_interface_id  = element(azurerm_network_interface.nic.*.id, count.index)
#     ip_configuration_name = "internal"
#     nat_rule_id           = element(azurerm_lb_nat_rule.tcp.*.id, count.index)
#     count                 = var.node_count
# }

# create load balancer backend pool association with VM NICs
resource "azurerm_network_interface_backend_address_pool_association" "backendassociation" {
  network_interface_id    = element(azurerm_network_interface.nic.*.id, count.index)
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  count                   = var.node_count
}

#create load balance

resource "azurerm_lb" "lb" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "LB-${var.resource_prefix}"
  location            = var.location
  sku                 = var.lb_sku
  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "BackendPool1"
}


resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule-${var.resource_prefix}"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  enable_floating_ip             = false
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.backend_pool.id]
  idle_timeout_in_minutes        = 5
  probe_id                       = azurerm_lb_probe.lb_probe.id
  depends_on                     = [azurerm_lb_probe.lb_probe]
}

resource "azurerm_lb_probe" "lb_probe" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "tcpProbe"
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

#Custom script to install apache on all VMS
resource "azurerm_virtual_machine_extension" "ApacheInstall" {
  name                 = "hostname"
  virtual_machine_id   = element(azurerm_linux_virtual_machine.linux-vm.*.id, count.index)
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  count                = var.node_count

settings = <<SETTINGS
    {   
    "commandToExecute": "apt-get -y update && apt-get install -y apache2"
    }
SETTINGS
}

#get public IP address data
data "azurerm_public_ip" "test" {
  name                = azurerm_public_ip.publicip.name
  resource_group_name = azurerm_resource_group.rg.name
}
# Example used:
# https://github.com/kumarvna/terraform-azurerm-virtual-machine/blob/master/variables.tf
# https://learn.microsoft.com/en-us/azure/load-balancer/quickstart-load-balancer-standard-internal-terraform
#---------------------------------------------------------------
# Locals (if needed)
#---------------------------------------------------------------




#---------------------------------------------------------------
# Resource Group
#---------------------------------------------------------------

# Using this, so that user have to enter the name of resource group
#   For the project, we are using the "AzureDevOps" resource group defined in default value of variable
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Data block to reference the custom image created by Packer
data "azurerm_image" "packer_image" {
  name                = "Sina_PackerImage_V${var.image_version}" # Replace with your Packer image name
  resource_group_name = data.azurerm_resource_group.main.name
}

#---------------------------------------------------------------
# Network
#---------------------------------------------------------------

#Vnet
resource "azurerm_virtual_network" "vnet1" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/24"]
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}

#Subnet
resource "azurerm_subnet" "subnet1" {
  name                 = "subent_1"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.0.0/25"]
}

#Public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-public-ip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static" # Use "Static" if you want a static public IP
}

#NIC
resource "azurerm_network_interface" "nic" {
  count               = var.instances_count
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  ip_configuration {
    name                          = "NIC-ipconfig-${count.index}"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

#---------------------------------------------------------------
# Load Balancer
#---------------------------------------------------------------

# Create an Internal Load Balancer to distribute traffic to the
# Virtual Machines in the Backend Pool
resource "azurerm_lb" "lb1" {
  name                = "Sina-Udacity-LB"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "LB-frontend-ip"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create a Backend Address Pool for the Load Balancer
resource "azurerm_lb_backend_address_pool" "lb1-backend-pool" {
  loadbalancer_id = azurerm_lb.lb1.id
  name            = "sina-lb-backend-pool"
}

# Associate Network Interface to the Backend Pool of the Load Balancer
#   The Network Interface will be used to route traffic to the Virtual
#     Machines in the Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "example" {
  count                   = 2
  network_interface_id    = element(concat(azurerm_network_interface.nic.*.id, [""]), count.index) #azurerm_network_interface.example[count.index].id
  ip_configuration_name   = "NIC-ipconfig-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb1-backend-pool.id
}


# Create a Load Balancer Probe to check the health of the 
# Virtual Machines in the Backend Pool
# resource "azurerm_lb_probe" "example" {
#   loadbalancer_id = azurerm_lb.example.id
#   name            = "test-probe"
#   port            = 80
# }

#---------------------------------------------------------------
# Availablity Set
#---------------------------------------------------------------

resource "azurerm_availability_set" "aset" {
  count               = var.instances_count
  name                = "${var.prefix}-availability-set"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  #   platform_fault_domain_count  = var.platform_fault_domain_count
  #   platform_update_domain_count = var.platform_update_domain_count
  #   proximity_placement_group_id = var.enable_proximity_placement_group ? azurerm_proximity_placement_group.appgrp.0.id : null
  managed = true
}

#---------------------------------------------------------------
# NSG
#---------------------------------------------------------------

#NSG
# This is used to create the NSG for the NICs created above
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  # Deny all inbound traffic from the internet (lowest priority)
  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    description                = "Deny all inbound traffic from the internet"
  }

  # Allow inbound traffic within the same virtual network
  security_rule {
    name                       = "allow-inbound-same-vnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
    description                = "Allow inbound traffic within the same virtual network"
  }

  # Allow outbound traffic within the same virtual network
  security_rule {
    name                       = "allow-outbound-same-vnet"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
    description                = "Allow outbound traffic within the same virtual network"
  }
}

# Allow HTTP traffic from Load Balancer to VMs
resource "azurerm_network_security_group_rule" "lb_rule" {
  name                        = "http_traffic_from_lb"
  priority                    = 200
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_id   = azurerm_network_security_group.nsg.id
  description                 = "Allow HTTP traffic from Azure Load Balancer"
}

# NSG Association
# This is used to associate the NSG with the NICs created above
resource "azurerm_network_interface_security_group_association" "nsgassoc" {
  count                     = var.instances_count
  network_interface_id      = element(concat(azurerm_network_interface.nic.*.id, [""]), count.index)
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#---------------------------------------------------------------
# Virtual Machine
#---------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "main" {
    count                           = var.instances_count
    name                            = "${var.prefix}-vm-${count.index}"
    computer_name                   = "vm${count.index}" # Ensure a valid computer name
    resource_group_name             = data.azurerm_resource_group.main.name
    location                        = data.azurerm_resource_group.main.location
    size                            = "Standard_D2s_v3"
    admin_username                  = var.admin_username
    admin_password                  = var.admin_password
    disable_password_authentication = false
    network_interface_ids           = [element(concat(azurerm_network_interface.nic.*.id, [""]), count.index)]

    # Reference the custom image created by Packer
    source_image_id = data.azurerm_image.packer_image.id

    os_disk {
        storage_account_type = "Standard_LRS"
        caching              = "ReadWrite"
    }

    tags = {
        project = "Udacity_Costco_DevOps"
    }
}

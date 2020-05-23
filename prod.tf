# Create a resource group
resource "azurerm_resource_group" "capstoneprod" {
  name     = "capstoneprod-resources"
  location = "westus"
}

# Create virtual network
resource "azurerm_virtual_network" "capstoneprod" {
  name                = "capstoneprod_acctvn"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.capstoneprod.location
  resource_group_name = azurerm_resource_group.capstoneprod.name
}

# Create subnet
resource "azurerm_subnet" "capstoneprod" {
  name                 = "capstoneprod_acctsub"
  resource_group_name  = azurerm_resource_group.capstoneprod.name
  virtual_network_name = azurerm_virtual_network.capstoneprod.name
  address_prefix       = "10.0.2.0/24"
}

# Create public IP Address
resource "azurerm_public_ip" "capstoneprod" {
  name                = "capstoneprod_publicip"
  location            = azurerm_resource_group.capstoneprod.location
  resource_group_name = azurerm_resource_group.capstoneprod.name
  allocation_method   = "Static"
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "capstoneprod" {
  name                = "capstoneprod_nsg"
  location            = azurerm_resource_group.capstoneprod.location
  resource_group_name = azurerm_resource_group.capstoneprod.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create virtual network interface
resource "azurerm_network_interface" "capstoneprod" {
  name                = "capstoneprod_acctni"
  location            = azurerm_resource_group.capstoneprod.location
  resource_group_name = azurerm_resource_group.capstoneprod.name
  network_security_group_id = azurerm_network_security_group.capstoneprod.id

  ip_configuration {
    name                          = "capstoneprod_testconfiguration2"
    subnet_id                     = azurerm_subnet.capstoneprod.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.capstoneprod.id
  }
}

# Create a Linux virtual machine

resource "azurerm_virtual_machine" "capstoneprod" {
  name                  = "capstoneprod_acctvm"
  location              = azurerm_resource_group.capstoneprod.location
  resource_group_name   = azurerm_resource_group.capstoneprod.name
  network_interface_ids = [azurerm_network_interface.capstoneprod.id]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.7"
    version   = "latest"
  }

  storage_os_disk {
    name          = "capstoneprod_myosdisk1"
    caching       = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "master-capstoneprod"
    admin_username = "azurebitra"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine_extension" "capstoneprod" {
  name                 = "master-capstoneprod"
  virtual_machine_id   = azurerm_virtual_machine.capstoneprod.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "wget https://git.io/azureprodintellipaat.sh && sh azureprodintellipaat.sh"
    }
SETTINGS


  tags = {
    environment = "Production"
  }
}

output "prodip" {
  value = azurerm_public_ip.capstoneprod.ip_address
}

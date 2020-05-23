# Create a resource group
resource "azurerm_resource_group" "capstonetest" {
  name     = "capstonetest-resources"
  location = "westus"
}

# Create virtual network
resource "azurerm_virtual_network" "capstonetest" {
  name                = "capstonetest_acctvn"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.capstonetest.location
  resource_group_name = azurerm_resource_group.capstonetest.name
}

# Create subnet
resource "azurerm_subnet" "capstonetest" {
  name                 = "capstonetest_acctsub"
  resource_group_name  = azurerm_resource_group.capstonetest.name
  virtual_network_name = azurerm_virtual_network.capstonetest.name
  address_prefix       = "10.0.2.0/24"
}

# Create public IP Address
resource "azurerm_public_ip" "capstonetest" {
  name                = "capstonetest_publicip"
  location            = azurerm_resource_group.capstonetest.location
  resource_group_name = azurerm_resource_group.capstonetest.name
  allocation_method   = "Static"
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "capstonetest" {
  name                = "capstonetest_nsg"
  location            = azurerm_resource_group.capstonetest.location
  resource_group_name = azurerm_resource_group.capstonetest.name

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
resource "azurerm_network_interface" "capstonetest" {
  name                = "capstonetest_acctni"
  location            = azurerm_resource_group.capstonetest.location
  resource_group_name = azurerm_resource_group.capstonetest.name
  network_security_group_id = azurerm_network_security_group.capstonetest.id

  ip_configuration {
    name                          = "capstonetest_testconfiguration1"
    subnet_id                     = azurerm_subnet.capstonetest.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.capstonetest.id
  }
}

# Create a Linux virtual machine

resource "azurerm_virtual_machine" "capstonetest" {
  name                  = "capstonetest_acctvm"
  location              = azurerm_resource_group.capstonetest.location
  resource_group_name   = azurerm_resource_group.capstonetest.name
  network_interface_ids = [azurerm_network_interface.capstonetest.id]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.7"
    version   = "latest"
  }

  storage_os_disk {
    name          = "capstonetest_myosdisk1"
    caching       = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "master-capstonetest"
    admin_username = "azurebitra"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine_extension" "capstonetest" {
  name                 = "master-capstonetest"
  virtual_machine_id   = azurerm_virtual_machine.capstonetest.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "wget https://git.io/azuretestintellipaat.sh && sh azuretestintellipaat.sh"
    }
SETTINGS


  tags = {
    environment = "Production"
  }
}

output "testip" {
  value = azurerm_public_ip.capstonetest.ip_address
}

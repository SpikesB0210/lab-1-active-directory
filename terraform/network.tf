resource "azurerm_resource_group" "lab1" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "lab1" {
  name                = "vnet-lab1"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.lab1.location
  resource_group_name = azurerm_resource_group.lab1.name
}

resource "azurerm_subnet" "lab1" {
  name                 = "snet-lab1"
  resource_group_name  = azurerm_resource_group.lab1.name
  virtual_network_name = azurerm_virtual_network.lab1.name
  address_prefixes     = ["10.20.1.0/24"]
}

# Note: the SOP's manual portal steps allow RDP from anywhere. This locks it
# to your own IP instead — a small but real improvement IaC makes easy to do
# by default, worth calling out if you write this up.
resource "azurerm_network_security_group" "lab1_rdp" {
  name                = "nsg-lab1-rdp"
  location            = azurerm_resource_group.lab1.location
  resource_group_name = azurerm_resource_group.lab1.name

  security_rule {
    name                       = "Allow-RDP-From-Me"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.my_ip_cidr
    destination_address_prefix = "*"
  }

  # Lets VS Code's "Remote - SSH" extension connect straight into the VM, so
  # Steps 2-6's PowerShell can be written and run from VS Code instead of an
  # RDP session. See README.md, "Doing Steps 2-6 from VS Code too".
  security_rule {
    name                       = "Allow-SSH-From-Me"
    priority                   = 310
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_ip_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "lab1" {
  subnet_id                 = azurerm_subnet.lab1.id
  network_security_group_id = azurerm_network_security_group.lab1_rdp.id
}

resource "azurerm_public_ip" "dc01" {
  name                = "pip-lab1-${var.vm_name}"
  location            = azurerm_resource_group.lab1.location
  resource_group_name = azurerm_resource_group.lab1.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "dc01" {
  name                = "nic-lab1-${var.vm_name}"
  location            = azurerm_resource_group.lab1.location
  resource_group_name = azurerm_resource_group.lab1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id         = azurerm_public_ip.dc01.id
  }
}

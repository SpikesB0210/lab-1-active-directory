# --- Phase 1: this is the fully declarative part of the lab (SOP Step 1) ---

resource "azurerm_windows_virtual_machine" "dc01" {
  name                = var.vm_name
  computer_name       = var.vm_name
  resource_group_name = azurerm_resource_group.lab1.name
  location            = azurerm_resource_group.lab1.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.dc01.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  # Confirm the exact SKU string before applying — image SKUs shift over time:
  #   az vm image list --publisher MicrosoftWindowsServer --offer WindowsServer --all -o table
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-g2"
    version   = "latest"
  }
}

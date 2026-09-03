# --- Phase 3: SOP Step 4 (OUs, groups, users), Step 5 (GPO) ---
#
# Apply this only AFTER you've confirmed by RDP that Phase 2's reboot finished
# and the box is answering as a domain controller for lab.local:
#   terraform apply -target=azurerm_virtual_machine_extension.build_ad_objects

resource "azurerm_virtual_machine_extension" "build_ad_objects" {
  name                       = "phase3-ad-objects-and-gpo"
  virtual_machine_id         = azurerm_windows_virtual_machine.dc01.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    fileUris = [var.phase3_script_url]
  })

  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -File phase3-build-ad-objects.ps1 -UserPassword \"${var.admin_password}\""
  })

  depends_on = [azurerm_virtual_machine_extension.install_and_promote]
}

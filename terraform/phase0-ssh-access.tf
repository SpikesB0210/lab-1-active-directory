# --- Phase 0: not part of the SOP, but the piece that lets VS Code drive
# Steps 2-6 too, not just Terraform. Installs and starts OpenSSH Server on
# the VM so VS Code's "Remote - SSH" extension can connect directly.
#
# Independent of Phase 2/3 — apply it any time after the VM exists:
#   terraform apply -target=azurerm_virtual_machine_extension.enable_ssh

resource "azurerm_virtual_machine_extension" "enable_ssh" {
  name                       = "phase0-enable-openssh"
  virtual_machine_id         = azurerm_windows_virtual_machine.dc01.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    fileUris = [var.phase0_script_url]
  })

  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -File phase0-enable-openssh.ps1"
  })

  depends_on = [azurerm_windows_virtual_machine.dc01]
}

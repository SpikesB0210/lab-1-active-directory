# --- Phase 2: SOP Steps 2-3 (install AD DS + GPMC, promote to domain controller) ---
#
# Apply this on its OWN pass, after Phase 1's VM already exists and is running:
#   terraform apply -target=azurerm_virtual_machine_extension.install_and_promote
#
# Why a separate pass: Install-ADDSForest ends with an automatic reboot.
# The Custom Script Extension's own completion signal can be unreliable across
# a self-triggered reboot — this is a known rough edge, and it's exactly why
# enterprise-grade AD automation usually reaches for the DSC extension (whose
# Local Configuration Manager has built-in reboot-and-continue support) instead
# of a raw Custom Script Extension. For a lab this size, CSE is simpler to
# read and debug — just budget 10-15 minutes and confirm by RDP that the
# reboot completed and lab.local exists before moving on to Phase 3.

resource "azurerm_virtual_machine_extension" "install_and_promote" {
  name                       = "phase2-install-adds-promote"
  virtual_machine_id         = azurerm_windows_virtual_machine.dc01.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    fileUris = [var.phase2_script_url]
  })

  # protected_settings keeps the DSRM password out of the Azure activity log
  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -File phase2-install-and-promote.ps1 -DomainName ${var.domain_name} -DomainNetBiosName ${var.domain_netbios_name} -DsrmPassword \"${var.dsrm_password}\""
  })

  depends_on = [azurerm_windows_virtual_machine.dc01]
}

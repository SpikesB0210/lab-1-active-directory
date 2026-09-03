output "public_ip_address" {
  value = azurerm_public_ip.dc01.ip_address
}

output "rdp_hint" {
  value = "RDP to ${azurerm_public_ip.dc01.ip_address} as ${var.admin_username} (local admin, before the domain exists) or LAB\\Administrator (after Phase 2 promotes the domain)."
}

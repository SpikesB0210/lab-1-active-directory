variable "resource_group_name" {
  description = "Resource group for Lab 1"
  type        = string
  default     = "rg-lab1-active-directory"
}

variable "location" {
  description = "Azure region — East US matches the SOP's free-tier guidance"
  type        = string
  default     = "eastus"
}

variable "vm_name" {
  description = "Computer name for the domain controller VM (max 15 chars)"
  type        = string
  default     = "dc01"
}

variable "vm_size" {
  description = "VM size — Standard_B2s per the SOP (2 vCPU / 4GB RAM, smallest size that runs AD comfortably)"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Local admin username used to RDP in before the domain exists"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Local admin password, and the password Phase 3 assigns to the four lab user accounts. Azure requires 12-123 characters and 3 of 4 complexity categories."
  type        = string
  sensitive   = true
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR form, e.g. 203.0.113.5/32 (check whatismyip.com). RDP is restricted to this instead of the whole internet."
  type        = string
}

variable "domain_name" {
  description = "AD domain / forest name from the SOP"
  type        = string
  default     = "lab.local"
}

variable "domain_netbios_name" {
  type    = string
  default = "LAB"
}

variable "dsrm_password" {
  description = "Directory Services Restore Mode password, set when promoting the server to a domain controller"
  type        = string
  sensitive   = true
}

variable "phase2_script_url" {
  description = "Raw URL to phase2-install-and-promote.ps1 (e.g. your GitHub repo's raw.githubusercontent.com link)"
  type        = string
}

variable "phase3_script_url" {
  description = "Raw URL to phase3-build-ad-objects.ps1"
  type        = string
}

variable "phase0_script_url" {
  description = "Raw URL to phase0-enable-openssh.ps1"
  type        = string
}

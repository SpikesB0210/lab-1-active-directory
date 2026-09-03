# SOP Step 2 — Install AD DS + GPMC
# SOP Step 3 — Promote the server to a domain controller
#
# Run by the Custom Script Extension defined in dc-promotion.tf.

param(
    [Parameter(Mandatory = $true)][string]$DomainName,
    [Parameter(Mandatory = $true)][string]$DomainNetBiosName,
    [Parameter(Mandatory = $true)][string]$DsrmPassword
)

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature -Name GPMC

Import-Module ADDSDeployment

Install-ADDSForest `
  -DomainName $DomainName `
  -DomainNetBiosName $DomainNetBiosName `
  -InstallDns:$true `
  -SafeModeAdministratorPassword (ConvertTo-SecureString $DsrmPassword -AsPlainText -Force) `
  -Force:$true
# Reboots automatically on completion — this is expected and required.

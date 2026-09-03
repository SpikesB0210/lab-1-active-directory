<#
.SYNOPSIS
    Promotes this server to a domain controller for a brand new forest,
    lab.local.

.DESCRIPTION
    Lab 1 - Step 3. Requires the AD DS role to already be installed
    (01-Install-ADDS-Role.ps1). This creates a new forest, a new domain
    (lab.local), and installs DNS on this server. The server restarts
    automatically when complete - save any open work first.

.PARAMETER DsrmPassword
    The Directory Services Restore Mode password, as a SecureString. Needed
    only for disaster recovery scenarios - write it down somewhere safe.
    If not supplied, you will be prompted securely at runtime.

.NOTES
    Run as: Local Administrator, elevated PowerShell.
    Reboot: Automatic, as part of -Force:$true promotion.
#>

[CmdletBinding()]
param(
    [Security.SecureString]$DsrmPassword
)

$ErrorActionPreference = 'Stop'

if (-not $DsrmPassword) {
    $DsrmPassword = Read-Host -Prompt "Enter a DSRM (Directory Services Restore Mode) password" -AsSecureString
}

Import-Module ADDSDeployment

Write-Host "Promoting this server to a domain controller for a new forest: lab.local" -ForegroundColor Cyan
Write-Host "The server will restart automatically when this completes." -ForegroundColor Yellow

Install-ADDSForest `
    -DomainName 'lab.local' `
    -DomainNetBiosName 'LAB' `
    -InstallDns:$true `
    -SafeModeAdministratorPassword $DsrmPassword `
    -Force:$true

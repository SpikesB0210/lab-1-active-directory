<#
.SYNOPSIS
    Installs the Active Directory Domain Services role and the Group Policy
    Management Console (GPMC) on a Windows Server 2025 machine.

.DESCRIPTION
    Lab 1 - Step 2. Run this on the server BEFORE promoting it to a domain
    controller (see 02-Promote-Domain-Controller.ps1). GPMC is installed here
    too because Step 5 of the lab needs Group Policy Management, and it is a
    separate feature from AD DS.

.NOTES
    Run as: Local Administrator, elevated PowerShell.
    Reboot: Not required for these installs, but a reboot is required later
    after promoting the domain controller.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "Installing AD DS role..." -ForegroundColor Cyan
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Write-Host "Installing Group Policy Management Console (GPMC)..." -ForegroundColor Cyan
Install-WindowsFeature -Name GPMC

Write-Host "Done. Close and reopen Server Manager so Group Policy Management appears under Tools." -ForegroundColor Green
Write-Host "Next step: 02-Promote-Domain-Controller.ps1" -ForegroundColor Yellow

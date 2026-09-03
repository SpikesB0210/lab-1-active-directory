<#
.SYNOPSIS
    Creates the departmental Organizational Units (OUs) for lab.local.

.DESCRIPTION
    Lab 1 - Step 4.1. Run this after the domain controller promotion has
    completed and the server has rebooted. Creates one OU per department
    plus a Computers OU. Safe to re-run - existing OUs are skipped.

.NOTES
    Run as: Domain Admin (LAB\Administrator), on the domain controller or
    any machine with RSAT-AD-PowerShell installed.
#>

[CmdletBinding()]
param(
    [string]$DomainPath = "DC=lab,DC=local"
)

$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory

$ouNames = @("IT", "Finance", "HR", "Sales", "Computers")

foreach ($ouName in $ouNames) {
    $existing = Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -SearchBase $DomainPath -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "OU '$ouName' already exists - skipping." -ForegroundColor Yellow
    }
    else {
        New-ADOrganizationalUnit -Name $ouName -Path $DomainPath
        Write-Host "Created OU '$ouName'." -ForegroundColor Green
    }
}

Write-Host "Next step: 04-Create-Security-Groups.ps1" -ForegroundColor Cyan

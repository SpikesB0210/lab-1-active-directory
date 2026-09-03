<#
.SYNOPSIS
    Creates one Global Security group per department OU.

.DESCRIPTION
    Lab 1 - Step 4.2. Requires the OUs from 03-Create-OUs.ps1 to already
    exist. Groups are used for role-based access control - grant access to
    the group once, then add/remove members as people join or leave.

.NOTES
    Run as: Domain Admin (LAB\Administrator).
#>

[CmdletBinding()]
param(
    [string]$DomainSuffix = "DC=lab,DC=local"
)

$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory

$groups = @(
    @{ Name = "IT_Admins";     OU = "IT" },
    @{ Name = "Finance_Users"; OU = "Finance" },
    @{ Name = "HR_Users";      OU = "HR" },
    @{ Name = "Sales_Users";   OU = "Sales" }
)

foreach ($g in $groups) {
    $path = "OU=$($g.OU),$DomainSuffix"
    $existing = Get-ADGroup -Filter "Name -eq '$($g.Name)'" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Group '$($g.Name)' already exists - skipping." -ForegroundColor Yellow
    }
    else {
        New-ADGroup -Name $g.Name -GroupScope Global -GroupCategory Security -Path $path
        Write-Host "Created group '$($g.Name)' in OU '$($g.OU)'." -ForegroundColor Green
    }
}

Write-Host "Next step: 05-Create-Users.ps1" -ForegroundColor Cyan

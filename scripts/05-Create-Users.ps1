<#
.SYNOPSIS
    Creates the four lab test-user accounts and adds each to their
    department security group.

.DESCRIPTION
    Lab 1 - Step 4.3. Requires the OUs and groups from the two previous
    scripts to already exist.

    IMPORTANT: Run this entire script in one go (F5 / F8-select-all), not
    line by line. $password must be defined before the New-ADUser calls run
    in the same session, or PowerShell will prompt for a Name and fail.

.PARAMETER Password
    The initial password for all four accounts, as a SecureString. If not
    supplied, you will be prompted securely at runtime. This is a LAB-ONLY
    convenience - never reuse one shared password in a real environment.

.NOTES
    Run as: Domain Admin (LAB\Administrator).
#>

[CmdletBinding()]
param(
    [Security.SecureString]$Password
)

$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory

if (-not $Password) {
    $Password = Read-Host -Prompt "Enter the initial password for the 4 lab accounts" -AsSecureString
}

$users = @(
    @{ Name = "alice.chen";  Given = "Alice"; Sur = "Chen";  OU = "IT";      Group = "IT_Admins" },
    @{ Name = "bob.patel";   Given = "Bob";   Sur = "Patel"; OU = "Finance"; Group = "Finance_Users" },
    @{ Name = "carol.jones"; Given = "Carol"; Sur = "Jones"; OU = "HR";      Group = "HR_Users" },
    @{ Name = "david.smith"; Given = "David"; Sur = "Smith"; OU = "Sales";   Group = "Sales_Users" }
)

foreach ($u in $users) {
    $existing = Get-ADUser -Filter "SamAccountName -eq '$($u.Name)'" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "User '$($u.Name)' already exists - skipping creation." -ForegroundColor Yellow
    }
    else {
        New-ADUser -Name $u.Name -GivenName $u.Given -Surname $u.Sur `
            -SamAccountName $u.Name -UserPrincipalName "$($u.Name)@lab.local" `
            -Path "OU=$($u.OU),DC=lab,DC=local" -AccountPassword $Password -Enabled $true
        Write-Host "Created user '$($u.Name)' in OU '$($u.OU)'." -ForegroundColor Green
    }

    Add-ADGroupMember -Identity $u.Group -Members $u.Name -ErrorAction SilentlyContinue
    Write-Host "Added '$($u.Name)' to group '$($u.Group)'." -ForegroundColor Green
}

Write-Host "Next step: configure Group Policy (see SOP-runbook.md Section 5), then run 07-Verify-Lab.ps1" -ForegroundColor Cyan

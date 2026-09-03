<#
.SYNOPSIS
    Runs every verification check from the lab's Verification table and
    prints a pass/fail summary.

.DESCRIPTION
    Lab 1 - Verification section. Run this last, after Steps 1-5 are all
    complete, to confirm the domain controller, OUs, users, groups, and
    GPO are all in the expected state.

.NOTES
    Run as: Domain Admin (LAB\Administrator), on the domain controller or
    any machine with RSAT-AD-PowerShell + RSAT-GPMC installed.
#>

[CmdletBinding()]
param()

Import-Module ActiveDirectory
Import-Module GroupPolicy -ErrorAction SilentlyContinue

$results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param($Check, $Passed, $Detail)
    $results.Add([PSCustomObject]@{ Check = $Check; Passed = $Passed; Detail = $Detail })
}

# 1. Domain controller is running
try {
    $dc = Get-ADDomainController -ErrorAction Stop
    Add-Result "Domain controller is running" $true "Forest: $($dc.Forest), Host: $($dc.HostName)"
}
catch {
    Add-Result "Domain controller is running" $false $_.Exception.Message
}

# 2. OUs exist
try {
    $expectedOUs = @("IT", "Finance", "HR", "Sales", "Computers")
    $actualOUs = (Get-ADOrganizationalUnit -Filter * | Select-Object -ExpandProperty Name)
    $missing = $expectedOUs | Where-Object { $_ -notin $actualOUs }
    if ($missing.Count -eq 0) {
        Add-Result "All 5 OUs exist" $true ($actualOUs -join ", ")
    }
    else {
        Add-Result "All 5 OUs exist" $false "Missing: $($missing -join ', ')"
    }
}
catch {
    Add-Result "All 5 OUs exist" $false $_.Exception.Message
}

# 3. Users exist and are enabled
try {
    $expectedUsers = @("alice.chen", "bob.patel", "carol.jones", "david.smith")
    $enabledUsers = Get-ADUser -Filter { Enabled -eq $true } | Select-Object -ExpandProperty SamAccountName
    $missingUsers = $expectedUsers | Where-Object { $_ -notin $enabledUsers }
    if ($missingUsers.Count -eq 0) {
        Add-Result "4 test users exist and are enabled" $true ($expectedUsers -join ", ")
    }
    else {
        Add-Result "4 test users exist and are enabled" $false "Missing/disabled: $($missingUsers -join ', ')"
    }
}
catch {
    Add-Result "4 test users exist and are enabled" $false $_.Exception.Message
}

# 4. Group membership correct (IT_Admins -> alice.chen)
try {
    $members = Get-ADGroupMember -Identity "IT_Admins" | Select-Object -ExpandProperty SamAccountName
    if ("alice.chen" -in $members) {
        Add-Result "IT_Admins contains alice.chen" $true ($members -join ", ")
    }
    else {
        Add-Result "IT_Admins contains alice.chen" $false "Members found: $($members -join ', ')"
    }
}
catch {
    Add-Result "IT_Admins contains alice.chen" $false $_.Exception.Message
}

# 5. GPO is linked to the IT OU
try {
    $inheritance = Get-GPInheritance -Target "OU=IT,DC=lab,DC=local"
    $linked = $inheritance.GpoLinks | Where-Object { $_.DisplayName -eq "IT Security Policy" }
    if ($linked) {
        Add-Result "IT Security Policy GPO linked to IT OU" $true "Enabled: $($linked.Enabled)"
    }
    else {
        Add-Result "IT Security Policy GPO linked to IT OU" $false "No matching GPO link found"
    }
}
catch {
    Add-Result "IT Security Policy GPO linked to IT OU" $false $_.Exception.Message
}

$results | Format-Table -AutoSize

$failCount = ($results | Where-Object { -not $_.Passed }).Count
if ($failCount -eq 0) {
    Write-Host "`nAll checks passed." -ForegroundColor Green
}
else {
    Write-Host "`n$failCount check(s) failed - see Detail column above and SOP-runbook.md Section 8 (Troubleshooting)." -ForegroundColor Red
}

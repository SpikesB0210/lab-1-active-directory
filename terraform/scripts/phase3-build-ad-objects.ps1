# SOP Step 4 — Organizational Units, security groups, user accounts
# SOP Step 5 — Group Policy Object (the two registry-backed settings only —
#              see the note near the bottom about Password Policy)
# SOP Verification section
#
# Run by the Custom Script Extension defined in ad-objects.tf, AFTER Phase 2's
# reboot has completed and lab.local is answering as a domain.

param(
    [Parameter(Mandatory = $true)][string]$UserPassword
)

Import-Module ActiveDirectory

# --- Step 4.1: Organizational Units ---
New-ADOrganizationalUnit -Name "IT"        -Path "DC=lab,DC=local" -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name "Finance"   -Path "DC=lab,DC=local" -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name "HR"        -Path "DC=lab,DC=local" -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name "Sales"     -Path "DC=lab,DC=local" -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name "Computers" -Path "DC=lab,DC=local" -ErrorAction SilentlyContinue

# --- Step 4.2: Security Groups ---
New-ADGroup -Name "IT_Admins"     -GroupScope Global -GroupCategory Security -Path "OU=IT,DC=lab,DC=local"      -ErrorAction SilentlyContinue
New-ADGroup -Name "Finance_Users" -GroupScope Global -GroupCategory Security -Path "OU=Finance,DC=lab,DC=local" -ErrorAction SilentlyContinue
New-ADGroup -Name "HR_Users"      -GroupScope Global -GroupCategory Security -Path "OU=HR,DC=lab,DC=local"      -ErrorAction SilentlyContinue
New-ADGroup -Name "Sales_Users"   -GroupScope Global -GroupCategory Security -Path "OU=Sales,DC=lab,DC=local"   -ErrorAction SilentlyContinue

# --- Step 4.3: Users ---
$securePassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force

$users = @(
    @{ Name = "alice.chen";  Given = "Alice"; Sur = "Chen";  OU = "IT";      Group = "IT_Admins" },
    @{ Name = "bob.patel";   Given = "Bob";   Sur = "Patel"; OU = "Finance"; Group = "Finance_Users" },
    @{ Name = "carol.jones"; Given = "Carol"; Sur = "Jones"; OU = "HR";      Group = "HR_Users" },
    @{ Name = "david.smith"; Given = "David"; Sur = "Smith"; OU = "Sales";   Group = "Sales_Users" }
)

foreach ($u in $users) {
    New-ADUser -Name $u.Name -GivenName $u.Given -Surname $u.Sur `
      -SamAccountName $u.Name -UserPrincipalName "$($u.Name)@lab.local" `
      -Path "OU=$($u.OU),DC=lab,DC=local" -AccountPassword $securePassword -Enabled $true `
      -ErrorAction SilentlyContinue

    Add-ADGroupMember -Identity $u.Group -Members $u.Name -ErrorAction SilentlyContinue
}

# --- Step 5: GPO ---
Import-Module GroupPolicy

if (-not (Get-GPO -Name "IT Security Policy" -ErrorAction SilentlyContinue)) {
    New-GPO -Name "IT Security Policy" | Out-Null
}
New-GPLink -Name "IT Security Policy" -Target "OU=IT,DC=lab,DC=local" -ErrorAction SilentlyContinue

# These two settings are registry-backed (Security Options / Administrative
# Templates), so Set-GPRegistryValue can reach them directly:
Set-GPRegistryValue -Name "IT Security Policy" `
  -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
  -ValueName "InactivityTimeoutSecs" -Type DWord -Value 900

Set-GPRegistryValue -Name "IT Security Policy" `
  -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices" `
  -ValueName "Deny_All" -Type DWord -Value 1

# NOTE — deliberately NOT scripted here: minimum password length (12) and
# password complexity live in the GPO's Account Policy / security template
# (GptTmpl.inf on SYSVOL), not the registry, so Set-GPRegistryValue cannot
# set them. Full automation is possible with Microsoft's LGPO.exe (Security
# Compliance Toolkit), but editing a GPO's security template by hand is easy
# to get subtly wrong (GPT.ini version, machine extension GUIDs). For a lab
# this size, set these two values by hand in GPMC after this script runs:
# Computer Configuration > Windows Settings > Security Settings >
# Account Policies > Password Policy. Two clicks, far less fragile.

# --- Verification (from the SOP) ---
Write-Output "--- Domain Controller ---"
Get-ADDomainController | Select-Object Name, Domain, Forest

Write-Output "--- OUs ---"
Get-ADOrganizationalUnit -Filter * | Select-Object Name

Write-Output "--- Enabled Users ---"
Get-ADUser -Filter { Enabled -eq $true } | Select-Object Name

Write-Output "--- IT_Admins Members ---"
Get-ADGroupMember -Identity IT_Admins | Select-Object Name

Write-Output "--- GPO Links on IT OU ---"
Get-GPInheritance -Target 'OU=IT,DC=lab,DC=local' | Select-Object -ExpandProperty GpoLinks

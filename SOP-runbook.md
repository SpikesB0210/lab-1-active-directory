# SOP / Runbook — Build & Administer an Active Directory Domain (lab.local)

**Scope:** Provision a Windows Server 2025 domain controller, promote it to a new forest/domain, build the OU/group/user structure, apply a GPO, and perform the standard help-desk lifecycle tasks.
**Audience:** Whoever is standing this environment up or reproducing it (you, in six months, or a teammate).
**Estimated time:** 3–5 hours across multiple sessions.

---

## 0. Prerequisites

- An Azure Free Account (azure.microsoft.com/free), **or** a local machine with 8 GB+ RAM, 60 GB free disk, and virtualization enabled in BIOS for VirtualBox.
- Remote Desktop client installed locally (not just the Azure portal's browser console).
- Basic familiarity with PowerShell and the Windows Server Manager console.

---

## 1. Provision the Server

### Option A — Azure (recommended)

1. Go to `azure.microsoft.com/free` and create a free account.
2. Sign in at `portal.azure.com`.
3. Search **Virtual machines** → **Create**.
4. Configure using the table below, then **Review + Create** → **Create**.

   | Setting | Value | Why |
   |---|---|---|
   | Region | East US | Cheapest region, broadest free-tier VM availability |
   | Image | Windows Server 2025 Datacenter — Gen2 | Latest server OS, free 180-day evaluation license |
   | Size | Standard_B2s (2 vCPU, 4 GB RAM) | Smallest size that runs AD comfortably |
   | Authentication | Password | Used to RDP in |
   | Public inbound ports | Allow RDP (3389) | Required to connect from your local machine |
   | OS disk | Standard SSD | Good performance, included in free tier |

5. **Cost control:** Stop (don't delete) the VM whenever you're not using it. A B2s VM runs ~$0.05/hour; stopping pauses compute billing so your $200 credit lasts far longer.

### Fix: enable clipboard sharing before you RDP in

RDP does not share your local clipboard by default — without this fix you can't paste commands into the VM.

1. Open the Remote Desktop app on your local machine (not the Azure portal's browser console).
2. Enter the VM's public IP.
3. Click **Show Options** (bottom left) → **Local Resources** tab.
4. Confirm **Clipboard** is checked under Local devices and resources.
5. Click **Connect**.

If you're using the Azure portal's browser-based console, clipboard support is limited — download the RDP file instead (**Connect → Download RDP File**) and open it with the native Remote Desktop app. Do this for every lab session.

### Option B — Local VirtualBox (alternative, no cloud account)

1. Download VirtualBox from `virtualbox.org`.
2. Download the Windows Server 2025 Evaluation ISO from the Microsoft Evaluation Center.
3. Create a new VM: 4 GB RAM minimum, 60 GB disk, Windows Server 2019/2022 as the type.
4. Mount the ISO, boot, and select **Windows Server 2025 Datacenter with Desktop Experience** during setup.
5. Host machine minimum: 8 GB RAM total, 60 GB free disk, quad-core CPU with virtualization enabled in BIOS.

---

## 2. Install Active Directory Domain Services

RDP into the VM — Server Manager opens automatically on login.

**GUI path:**
1. Server Manager → **Manage → Add Roles and Features**.
2. Next through the wizard to **Server Roles**.
3. Check **Active Directory Domain Services** → **Add Features** when prompted (includes management tools).
4. Next through remaining pages → **Install**. Takes 2–3 minutes.
5. **Close** when complete — do **not** restart yet.

**PowerShell path** (`scripts/01-Install-ADDS-Role.ps1`):
```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
```

**Also install the Group Policy Management Console (GPMC) now** — Step 5 of this runbook requires it, and it's a separate install from AD DS. Skipping this step means Group Policy Management won't appear in Server Manager's Tools menu later.

```powershell
Install-WindowsFeature -Name GPMC
```

Close and reopen Server Manager after it completes so **Group Policy Management** appears under Tools. It is a separate window from Active Directory Users and Computers — GPOs are not managed from ADUC.

---

## 3. Promote the Server to a Domain Controller

Installing the AD DS role does not create a domain — promotion creates the forest, the domain, and makes this server the authoritative DNS/identity server.

- **Forest** = the top-level container of the entire AD structure (think: the organization itself).
- **Domain** = a boundary inside the forest with its own name (`lab.local` here); most small/medium orgs run one domain in one forest.

**GUI path:**
1. Server Manager → click the yellow warning flag (top right) → **Promote this server to a domain controller**.
2. Select **Add a new forest**. Root domain name: `lab.local`.
3. Set a DSRM password and record it somewhere safe — needed only for disaster recovery.
4. Accept defaults on the DNS Options and NetBIOS pages.
5. **Install** — the server restarts automatically when complete.

**PowerShell path** (`scripts/02-Promote-Domain-Controller.ps1`):
```powershell
Import-Module ADDSDeployment
Install-ADDSForest `
  -DomainName 'lab.local' `
  -DomainNetBiosName 'LAB' `
  -InstallDns:$true `
  -SafeModeAdministratorPassword (ConvertTo-SecureString 'YourDSRMPassword!' -AsPlainText -Force) `
  -Force:$true
```

> Replace `'YourDSRMPassword!'` with your own strong password before running. The server restarts automatically after this completes.

**What just happened:** you created a new AD forest called `lab.local`. This server now runs DNS for the domain and is the authoritative source for every identity decision — anything that joins `lab.local` trusts this box to authenticate users.

---

## 4. Build the Organizational Structure

Open **Active Directory Users and Computers (ADUC)** from Server Manager's Tools menu.

### 4.1 Create Organizational Units (OUs)

An OU is a folder inside AD used to organize users, computers, and groups by department or function. GPOs link to OUs, so everything inside an OU inherits the same policy automatically.

**GUI:** Right-click `lab.local` → **New → Organizational Unit**, one per department plus one for computers.

**PowerShell** (`scripts/03-Create-OUs.ps1`):
```powershell
New-ADOrganizationalUnit -Name "IT"        -Path "DC=lab,DC=local"
New-ADOrganizationalUnit -Name "Finance"   -Path "DC=lab,DC=local"
New-ADOrganizationalUnit -Name "HR"        -Path "DC=lab,DC=local"
New-ADOrganizationalUnit -Name "Sales"     -Path "DC=lab,DC=local"
New-ADOrganizationalUnit -Name "Computers" -Path "DC=lab,DC=local"
```

### 4.2 Create Security Groups

A security group holds user accounts so access to a resource is granted to the group once, not to individuals repeatedly — this is role-based access control. Add/remove someone from the group and their access changes instantly.

**GUI:** Right-click each OU → **New → Group**. Scope: Global. Type: Security.

**PowerShell** (`scripts/04-Create-Security-Groups.ps1`):
```powershell
New-ADGroup -Name "IT_Admins"     -GroupScope Global -GroupCategory Security -Path "OU=IT,DC=lab,DC=local"
New-ADGroup -Name "Finance_Users" -GroupScope Global -GroupCategory Security -Path "OU=Finance,DC=lab,DC=local"
New-ADGroup -Name "HR_Users"      -GroupScope Global -GroupCategory Security -Path "OU=HR,DC=lab,DC=local"
New-ADGroup -Name "Sales_Users"   -GroupScope Global -GroupCategory Security -Path "OU=Sales,DC=lab,DC=local"
```

### 4.3 Create User Accounts

A user account is the single identity that controls a person's access to everything — email, shares, printers, apps — via group membership. Use a consistent naming convention (`firstname.lastname`).

> **Important:** run the entire script block below together, not line by line. `$password` must be defined before the `New-ADUser` commands execute in the same session, or PowerShell will prompt for a `Name` and the script will fail. In PowerShell ISE, select all and press F8; in a regular PowerShell window, paste the whole block and press Enter.

**PowerShell** (`scripts/05-Create-Users.ps1`):
```powershell
$password = ConvertTo-SecureString "Welcome@2026!" -AsPlainText -Force

New-ADUser -Name "alice.chen" -GivenName "Alice" -Surname "Chen" `
  -SamAccountName "alice.chen" -UserPrincipalName "alice.chen@lab.local" `
  -Path "OU=IT,DC=lab,DC=local" -AccountPassword $password -Enabled $true

New-ADUser -Name "bob.patel" -GivenName "Bob" -Surname "Patel" `
  -SamAccountName "bob.patel" -UserPrincipalName "bob.patel@lab.local" `
  -Path "OU=Finance,DC=lab,DC=local" -AccountPassword $password -Enabled $true

New-ADUser -Name "carol.jones" -GivenName "Carol" -Surname "Jones" `
  -SamAccountName "carol.jones" -UserPrincipalName "carol.jones@lab.local" `
  -Path "OU=HR,DC=lab,DC=local" -AccountPassword $password -Enabled $true

New-ADUser -Name "david.smith" -GivenName "David" -Surname "Smith" `
  -SamAccountName "david.smith" -UserPrincipalName "david.smith@lab.local" `
  -Path "OU=Sales,DC=lab,DC=local" -AccountPassword $password -Enabled $true

Add-ADGroupMember -Identity "IT_Admins"     -Members "alice.chen"
Add-ADGroupMember -Identity "Finance_Users" -Members "bob.patel"
Add-ADGroupMember -Identity "HR_Users"      -Members "carol.jones"
Add-ADGroupMember -Identity "Sales_Users"   -Members "david.smith"
```

> Change `"Welcome@2026!"` to your own value before running in a real environment — this is a lab-only placeholder password.

---

## 5. Configure Group Policy

Group Policy enforces settings across every machine and user in the domain without touching each one individually. Open **Group Policy Management** from Server Manager's Tools menu (requires GPMC — see Section 2).

A **Group Policy Object (GPO)** is a rulebook Windows applies automatically to everything inside the OU it's linked to, the next time a machine/user logs in or runs `gpupdate`.

**Steps:**
1. Expand **Forest: lab.local → Domains → lab.local**.
2. Right-click the **IT** OU → **Create a GPO in this domain and link it here**.
3. Name it **IT Security Policy**.
4. Right-click the new GPO → **Edit**, and configure:

   | Policy path | Setting | Value | Why |
   |---|---|---|---|
   | Computer Config → Windows Settings → Security → Account Policies → Password Policy | Minimum password length | 12 | Enforces strong passwords |
   | Computer Config → Windows Settings → Security → Account Policies → Password Policy | Password must meet complexity requirements | Enabled | Requires upper/lower/number/symbol |
   | Computer Config → Windows Settings → Security → Local Policies → Security Options | Interactive logon: Machine inactivity limit | 900 seconds | Auto-locks screen after 15 minutes |
   | Computer Config → Administrative Templates → System → Removable Storage Access | All removable storage classes: Deny all access | Enabled | Prevents data exfiltration via USB |

5. **Test it:** join a second VM to `lab.local`, move its computer object into the IT OU, run `gpupdate /force` on it, log in as `alice.chen`, and confirm the screen-lock policy applies.

---

## 6. Common Help-Desk Tasks

These are the top day-one tasks expected of any IT support role. Script versions are in `scripts/06-HelpDesk-Tasks.ps1` (each is a standalone function — call the one you need).

| Task | Command |
|---|---|
| Reset a password (forces change at next logon) | `Set-ADAccountPassword` + `Set-ADUser -ChangePasswordAtLogon $true` |
| Unlock a locked account | `Unlock-ADAccount` |
| Disable an account (offboarding — never delete) | `Disable-ADAccount` |
| Find disabled accounts | `Search-ADAccount -AccountDisabled` |
| Find accounts inactive 90+ days | `Get-ADUser -Filter {LastLogonDate -lt $cutoff}` |
| Check a user's group memberships | `Get-ADPrincipalGroupMembership` |

**Why disable instead of delete:** disabling preserves account history and group memberships for audit purposes. Deletion is permanent and destroys that trail.

---

## 7. Verification

Run `scripts/07-Verify-Lab.ps1`, or the individual checks:

| Check | Command | Expected result |
|---|---|---|
| Domain controller is running | `Get-ADDomainController` | Returns DC info including forest `lab.local` |
| OUs exist | `Get-ADOrganizationalUnit -Filter *` | Lists all 5 OUs |
| Users exist and are enabled | `Get-ADUser -Filter {Enabled -eq $true}` | Lists the 4 test accounts |
| Group memberships correct | `Get-ADGroupMember -Identity IT_Admins` | Returns `alice.chen` |
| GPO is linked | `Get-GPInheritance -Target 'OU=IT,DC=lab,DC=local'` | Shows "IT Security Policy" as linked |

---

## 8. Troubleshooting

| Problem | Fix |
|---|---|
| PowerShell prompts for `Name:` when creating users | `$password` wasn't defined before `New-ADUser` ran. Run the entire block from Section 4.3 together, not line by line. |
| Cannot copy/paste into the VM | RDP client → Show Options → Local Resources → check Clipboard, then reconnect. Or use the downloaded RDP file instead of the browser console. |
| Promotion fails: DNS conflict | Set the NIC's preferred DNS to `127.0.0.1` before promoting, or use the VM's static IP. |
| Cannot RDP after domain join | Log in as `LAB\Administrator` (domain admin), not the local `Administrator`. |
| GPO not applying | Run `gpupdate /force` on the target machine, then `gpresult /r` to see which policies actually applied. |
| User cannot log in after creation | Confirm the account is `Enabled` and check `ChangePasswordAtLogon`. |
| AD Users and Computers not showing | Run `dsa.msc` from the Run dialog, or `Add-WindowsFeature RSAT-ADDS`. |

---

## 9. Change Log / Session Notes

Use this section to log what you actually did each session — dates, deviations from the plan, anything that took longer than expected. Useful both for troubleshooting later and as the raw material for interview answers about this project.

| Date | Notes |
|---|---|
| | |

# Lab 1 — Active Directory, via VS Code + Terraform

This is a Terraform-driven version of the Lab 1 SOP. It doesn't change what
the lab teaches — it changes how much of it you can drive from `terraform
apply` instead of clicking through the Azure portal and typing commands into
an RDP session by hand.

## What's actually Terraform-native vs. scripted

| SOP step | How it runs here | Why |
|---|---|---|
| 1 — Provision the VM | **Native Terraform** (`network.tf`, `vm.tf`) | Resource group, VNet, subnet, NSG, public IP, and the VM are all real `azurerm` resources — this is Terraform doing what it's built for. |
| 2 — Install AD DS + GPMC | **Scripted, via Custom Script Extension** (`dc-promotion.tf` + `scripts/phase2-*.ps1`) | Installing a Windows feature happens inside the guest OS. Terraform can't touch that directly — it can only tell Azure "run this script on the VM," which is what the extension resource does. |
| 3 — Promote to Domain Controller | **Scripted, same extension** | Same mechanism as Step 2. Triggers an automatic reboot — see the Phase 2 note below. |
| 4 — OUs, groups, users | **Scripted, via a second Custom Script Extension** (`ad-objects.tf` + `scripts/phase3-*.ps1`) | Straightforward PowerShell, just orchestrated by Terraform instead of run by hand. |
| 5 — GPO | **Mostly scripted, two settings by hand** | GPO creation, linking, the inactivity timeout, and the removable-storage block are all scripted. Minimum password length and complexity live in the GPO's security template, not the registry, so they're set manually in GPMC — see the note in `phase3-build-ad-objects.ps1`. |
| 6 — Help desk tasks | **Not scripted, but runnable from VS Code** | Password resets, unlocks, and offboarding are one-off operational actions, not infrastructure state — the wrong shape for `terraform apply` regardless of provider maturity. But once Phase 0 is applied, you can run the SOP's PowerShell for these straight from a VS Code Remote-SSH terminal instead of RDP — see below. |

Nothing here uses HashiCorp's Windows AD provider (`hashicorp/ad`) — it's
labeled experimental by HashiCorp itself and the GitHub repo was archived in
August 2025, so it's not something worth anchoring a portfolio project on.

## Doing Steps 2-6 from VS Code too, not just Terraform

Terraform only reaches Azure's control plane — but VS Code itself can reach
*inside* the VM if you give it a way in. That's what `phase0-ssh-access.tf`
is for: it installs and starts OpenSSH Server on the VM (and `network.tf`
opens port 22 to your IP alongside RDP's 3389), so VS Code's **Remote - SSH**
extension can connect directly to the box. Once connected, you get a real
integrated terminal running *on the domain controller* — meaning Steps 2
through 6's PowerShell can be written, edited, and run from VS Code, with
proper syntax highlighting and IntelliSense (via the **PowerShell**
extension), instead of typing into PowerShell ISE over RDP.

Setup:

1. Install the **Remote - SSH** and **PowerShell** extensions in VS Code.
2. `terraform apply -target=azurerm_virtual_machine_extension.enable_ssh` (any time after Phase 1's VM exists).
3. In VS Code: `Cmd+Shift+P` → **Remote-SSH: Connect to Host** → enter `azureuser@<public-ip>`.
4. Open an integrated terminal in that remote window — it's now a PowerShell session on the domain controller. Run Steps 2-6's commands, or the `scripts/phase2-*.ps1` / `phase3-*.ps1` files directly, from there.

What this does *not* replace: **Active Directory Users and Computers**,
**Group Policy Management Console**, and the two Password Policy settings
noted in `phase3-build-ad-objects.ps1` are MMC GUI tools with no terminal
equivalent — those still need a (much shorter) RDP session. Realistically:
RDP in once, click through GPMC for the two Account Policy values, confirm
things look right in ADUC, then do the rest of your iterating from VS Code.

## Prerequisites

1. **VS Code** with the [HashiCorp Terraform extension](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform) — gives you syntax highlighting, validation, and a formatted view of these `.tf` files. It's a front end; the actual work still happens through the `terraform` CLI in VS Code's integrated terminal.
2. **Terraform CLI** installed (`terraform -version` to confirm).
3. **Azure CLI** installed and authenticated: `az login`.
4. This repo's `scripts/` folder pushed somewhere Azure can fetch it over HTTPS at deploy time — the simplest option is your own GitHub repo (public), referencing the raw file URL. If you'd rather not make the scripts public, use an Azure Storage blob with a SAS token instead.

## Running it — three passes, not one

```bash
cd terraform-lab1-ad
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: real passwords, your IP, your script URLs
terraform init

# Phase 1 — provision the VM (SOP Step 1)
terraform apply -target=azurerm_windows_virtual_machine.dc01

# Phase 0 (optional) — enable OpenSSH so VS Code can connect directly
terraform apply -target=azurerm_virtual_machine_extension.enable_ssh

# Phase 2 — install AD DS + promote to DC (SOP Steps 2-3)
terraform apply -target=azurerm_virtual_machine_extension.install_and_promote
# Wait ~10-15 min, then RDP in and confirm the server rebooted into lab.local
# before continuing. Custom Script Extension's completion signal can be
# unreliable across a self-triggered reboot — don't trust the portal status
# alone, verify by connecting.

# Phase 3 — OUs, groups, users, GPO (SOP Steps 4-5)
terraform apply -target=azurerm_virtual_machine_extension.build_ad_objects

# Once you're happy everything's in place, a plain `terraform apply` with no
# -target will reconcile the full set and is safe to run from here on.
```

Why three passes instead of one `terraform apply`: `Install-ADDSForest`
reboots the server as its final action, and Phase 3's PowerShell can't run
until the box has actually come back up as a domain controller. Terraform's
dependency graph (`depends_on`) guarantees ordering, but it doesn't know how
to wait out an in-guest reboot — that's a genuine gap between what
declarative infrastructure tools model well (resource existence) and what
this lab needs (a specific in-guest state after a restart). This is also
exactly why real AD automation reaches for the DSC extension instead of
Custom Script Extension — DSC's Local Configuration Manager has built-in
reboot-and-continue support. Worth a mention if you write this up: it's a
more interesting story than "everything just worked."

## Security note worth keeping in your back pocket

The SOP's manual Step 1 opens RDP to the whole internet ("Allow RDP (3389)").
`network.tf` here restricts it to your own IP by default (`my_ip_cidr`) —
a small, free improvement that's easy to forget when you're clicking through
the portal but hard to skip when you're forced to fill in a variable for it.
That contrast — IaC nudging you toward better defaults — is a solid,
concrete talking point for a LinkedIn post.

## Cleaning up

```bash
terraform destroy
```

Stops the free-tier cost clock completely, rather than just stopping the VM.

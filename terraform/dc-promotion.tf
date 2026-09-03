# --- Phase 2: SOP Steps 2-3 (install AD DS + GPMC, promote to domain controller) ---
#
# This used to define azurerm_virtual_machine_extension.install_and_promote.
# It ran once, successfully — AD DS is installed and dc01 is promoted to a
# domain controller for lab.local. That work is done and stays done; it
# happened inside the guest OS and doesn't get undone by anything below.
#
# The resource block is gone on purpose. Azure Windows VMs allow only ONE
# Microsoft.Compute.CustomScriptExtension on a VM for its entire lifetime —
# not "one at a time," one ever, unless you remove the existing one first.
# Phase 3 (ad-objects.tf) is that one remaining slot, so this file must stay
# resource-free from here on, or a future `terraform apply` will try to
# recreate this extension and immediately collide with Phase 3's.
#
# If you ever destroy and rebuild this VM from scratch, temporarily restore
# a resource block here (see git history), apply it first, confirm the
# reboot completed, THEN remove it again before applying Phase 3 — same
# manual "remove the extension object, then move on" dance as the first
# time around.

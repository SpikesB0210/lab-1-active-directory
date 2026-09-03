# Phase 0 used to be its own azurerm_virtual_machine_extension resource here.
# It's gone: Azure Windows VMs only allow ONE Microsoft.Compute.CustomScript
# Extension per VM, and Phase 2 (dc-promotion.tf) already occupies that slot.
# OpenSSH enablement is now bolted onto the Phase 3 script instead —
# see scripts/phase3-build-ad-objects.ps1 and ad-objects.tf.
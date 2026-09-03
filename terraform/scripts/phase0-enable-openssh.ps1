# Not part of the SOP — enables OpenSSH Server so VS Code's "Remote - SSH"
# extension can connect directly to this VM from your local machine, giving
# you a real integrated terminal on the box without RDP.

Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# The capability install usually creates this firewall rule automatically —
# create it explicitly in case it didn't, so port 22 isn't silently blocked.
if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" `
      -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}

# Makes SSH sessions land in PowerShell instead of cmd.exe by default.
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell `
  -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -PropertyType String -Force

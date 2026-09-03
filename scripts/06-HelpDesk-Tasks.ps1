<#
.SYNOPSIS
    Reusable functions for the most common day-one Active Directory
    help-desk tasks: password reset, account unlock, offboarding, and
    basic audit reporting.

.DESCRIPTION
    Lab 1 - Step 6. Dot-source this file to load the functions into your
    session, then call whichever one you need:

        . .\06-HelpDesk-Tasks.ps1
        Reset-LabUserPassword -Identity "bob.patel"
        Unlock-LabUserAccount -Identity "carol.jones"
        Disable-LabUserAccount -Identity "david.smith"
        Get-LabDisabledAccounts
        Get-LabInactiveAccounts -Days 90
        Get-LabUserGroups -Identity "alice.chen"

.NOTES
    Run as: Domain Admin (LAB\Administrator), or an account delegated
    help-desk rights over the relevant OUs.
#>

Import-Module ActiveDirectory

function Reset-LabUserPassword {
    <#
    .SYNOPSIS
        Resets a user's password and forces a change at next logon -
        the standard pattern for a help-desk password-reset ticket.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Identity,
        [Security.SecureString]$NewPassword
    )
    if (-not $NewPassword) {
        $NewPassword = Read-Host -Prompt "Enter new password for $Identity" -AsSecureString
    }
    Set-ADAccountPassword -Identity $Identity -Reset -NewPassword $NewPassword
    Set-ADUser -Identity $Identity -ChangePasswordAtLogon $true
    Write-Host "Password reset for '$Identity'. User must change it at next logon." -ForegroundColor Green
}

function Unlock-LabUserAccount {
    <#
    .SYNOPSIS
        Unlocks an account that has been locked out after too many failed
        login attempts - one of the most frequent help-desk calls.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Identity
    )
    Unlock-ADAccount -Identity $Identity
    Write-Host "Unlocked account '$Identity'." -ForegroundColor Green
}

function Disable-LabUserAccount {
    <#
    .SYNOPSIS
        Disables an account for employee offboarding. Disable, don't
        delete - this preserves account history and group memberships
        for audit purposes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Identity
    )
    Disable-ADAccount -Identity $Identity
    Write-Host "Disabled account '$Identity'." -ForegroundColor Green
}

function Get-LabDisabledAccounts {
    <#
    .SYNOPSIS
        Lists all currently disabled accounts in the domain.
    #>
    [CmdletBinding()]
    param()
    Search-ADAccount -AccountDisabled | Select-Object Name, SamAccountName
}

function Get-LabInactiveAccounts {
    <#
    .SYNOPSIS
        Lists enabled accounts that have not logged in within the given
        number of days (default 90) - standard compliance/audit report.
    #>
    [CmdletBinding()]
    param(
        [int]$Days = 90
    )
    $cutoff = (Get-Date).AddDays(-$Days)
    Get-ADUser -Filter { LastLogonDate -lt $cutoff -and Enabled -eq $true } -Properties LastLogonDate |
        Select-Object Name, LastLogonDate
}

function Get-LabUserGroups {
    <#
    .SYNOPSIS
        Lists the group memberships for a given user - useful for access
        review tickets ("what does this person have access to?").
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Identity
    )
    Get-ADPrincipalGroupMembership -Identity $Identity | Select-Object Name
}

Write-Host "Help-desk functions loaded: Reset-LabUserPassword, Unlock-LabUserAccount, Disable-LabUserAccount, Get-LabDisabledAccounts, Get-LabInactiveAccounts, Get-LabUserGroups" -ForegroundColor Cyan

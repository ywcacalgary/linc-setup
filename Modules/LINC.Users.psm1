Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-LincStudentUser {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$UserName = 'Student',
        [string]$Description = 'Custom Local Standard Account',
        [string]$LocalGroup = 'Users'
    )

    try {
        $existingUser = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue

        if ($existingUser) {
            Write-LincLog -Message "User '$UserName' already exists. Removing existing account." -Level Warning
            if ($PSCmdlet.ShouldProcess($UserName, 'Remove local user')) {
                Remove-LocalUser -Name $UserName -ErrorAction Stop
            }
        }

        if ($PSCmdlet.ShouldProcess($UserName, 'Create local user')) {
            New-LocalUser -Name $UserName -FullName $UserName -Description $Description -NoPassword -ErrorAction Stop | Out-Null
            Set-LocalUser -Name $UserName -UserMayChangePassword $false -PasswordNeverExpires $true -ErrorAction Stop
            Add-LocalGroupMember -Group $LocalGroup -Member $UserName -ErrorAction Stop
        }

        Write-LincLog -Message "User '$UserName' successfully created." -Level Success
    }
    catch {
        Write-LincLog -Message "User creation failed for '$UserName': $($_.Exception.Message)" -Level Error
        throw
    }
}

Export-ModuleMember -Function New-LincStudentUser
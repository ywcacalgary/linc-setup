Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Install-LincWindowsUpdate {
    [CmdletBinding()]
    param([switch]$AutoReboot)

    try {
        Write-LincLog -Message 'Preparing Windows Update components.'

        if (-not (Test-LincCommandAvailable -Name Get-WindowsUpdate)) {
            Write-LincLog -Message 'Installing PSWindowsUpdate module.'
            Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
            Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers -Confirm:$false -ErrorAction Stop
        }

        Import-Module PSWindowsUpdate -ErrorAction Stop
        Add-WUServiceManager -MicrosoftUpdate -Confirm:$false -ErrorAction Stop | Out-Null

        Write-LincLog -Message 'Installing available updates.'
        if ($AutoReboot) {
            Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -Install -AutoReboot -ErrorAction Stop | Out-Null
        }
        else {
            Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -Install -IgnoreReboot -ErrorAction Stop | Out-Null
        }

        $rebootRequired = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        if ($rebootRequired) {
            Write-LincLog -Message 'A reboot is required after Windows Update.' -Level Warning
        }

        Write-LincLog -Message 'Windows Update completed.' -Level Success
    }
    catch {
        Write-LincLog -Message "Windows Update failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

Export-ModuleMember -Function Install-LincWindowsUpdate
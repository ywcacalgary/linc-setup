Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Install-LincWindowsUpdate {
    [CmdletBinding()]
    param(
        [switch]$AutoReboot
    )

    try {
        Write-LincLog -Message 'Preparing Windows Update components.'

        if (-not (Test-LincCommandAvailable -Name Get-WindowsUpdate)) {
            Write-LincLog -Message 'Installing PSWindowsUpdate module.'
            Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
            Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers -Confirm:$false -ErrorAction Stop
        }

        Import-Module PSWindowsUpdate -ErrorAction Stop
        Add-WUServiceManager -MicrosoftUpdate -Confirm:$false -ErrorAction Stop | Out-Null

        Write-LincLog -Message 'Querying available updates.'
        $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -ErrorAction Stop

        if (-not $updates) {
            Write-LincLog -Message 'No updates were found.' -Level Success
            return
        }

        $total = $updates.Count
        $index = 0

        foreach ($update in $updates) {
            $index++
            $title = if ($update.Title) { $update.Title } else { 'Unknown update' }
            $percent = [math]::Round(($index / $total) * 100)

            Write-Progress -Activity 'Installing Windows updates' `
                -Status "$index of $total" `
                -CurrentOperation $title `
                -PercentComplete $percent

            Write-LincLog -Message "Installing update: $title"

            Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -KBArticleID $update.KB -ErrorAction Stop | Out-Null
        }

        Write-Progress -Activity 'Installing Windows updates' -Completed

        $rebootRequired = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        if ($rebootRequired) {
            Write-LincLog -Message 'A reboot is required after Windows Update.' -Level Warning
            if ($AutoReboot) {
                Restart-Computer -Force
            }
        }

        Write-LincLog -Message 'Windows Update completed.' -Level Success
    }
    catch {
        Write-Progress -Activity 'Installing Windows updates' -Completed
        Write-LincLog -Message "Windows Update failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

Export-ModuleMember -Function Install-LincWindowsUpdate
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Add-LincWifi {
    try {
        $netshOutput = netsh wlan show profiles 
        if ($netshOutput | Select-String -Pattern "YWCalgary Guest") {
            Write-Linclog -Message "YWCalgary Guest already added as Wi-Fi profile. Reinstalling profile." -Level Warning
            netsh wlan delete profile name="YWCalgary Guest" interface="Wi-Fi"
        }
        Get-Content -Path ".\Wi-Fi-YWCalgary Guest.xml" -ErrorAction Stop
        Write-Linclog -Message "Found Wi-Fi configuration file." -Level Success
        Write-Linclog -Message "Adding Wi-Fi to device's networks..." -Level Info
        netsh wlan add profile filename=".\Wi-Fi-YWCalgary Guest.xml"
        Write-Linclog -Message "Successfully added YWCalgary Guest as a Wi-Fi network." -Level Success
    } catch {
        Write-Linclog -Message "Unable to read Wi-fi configuration file." -Level Error
    }
    
}
function Connect-LincWiFi {
    Start-Sleep -Seconds 5
    Write-Linclog -Message "Updating WiFi Profiles..."
    # Turning on Location services to connect to Wi-Fi. By Default this was off.
    $AppPrivacy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
    if (!(Test-Path $AppPrivacy)) {
        New-Item -Path $AppPrivacy -Force | Out-Null
    }
    Set-ItemProperty -Path $AppPrivacy -Name "LetAppsAccessLocation" -Value 1 -Type DWORD
    Set-ItemProperty -Path $AppPrivacy -Name "LetDesktopAppsAccessLocation" -Value 1 -Type DWORD

    Start-Process "$env:WINDIR\System32\SystemSettingsAdminFlows.exe" -ArgumentList "SetCamSystemGlobal location 1" -Wait
    netsh wlan connect name="YWCalgary Guest" ssid="YWCalgary Guest"
    Write-Linclog -Message "Connecting to YWCalgary Guest..."
    Start-Sleep -Seconds 5
    $netshOutput = netsh wlan show profiles
    
    $connectedWifi = $netshOutput | Select-String -Pattern "YWCalgary Guest"
    
    if ($connectedWifi) {
        Write-Linclog -Message "Successfully connected to YWCalgary Guest Wi-Fi." -Level Success
        netsh wlan delete profile name="YWCA" interface="Wi-Fi"
        Write-Linclog -Message "Deleting YWCA Staff WiFi..."
    } else {
        Write-Linclog -Message "Wi-Fi could not be changed."
        do {
            $response = Read-Host "Do you want to try again? [Y/N]"
            $response = $response.Trim().ToUpper()
        } until ($response -in @('Y','N'))

        if ($response -eq 'Y') {
            Add-LincWifi
            Connect-LincWiFi
        } else {
            Write-Linclog -Message "Skipping Wi-Fi Change." -Level Warning
        }
    }
}

Export-ModuleMember -Function Add-LincWiFi, Connect-LincWiFi
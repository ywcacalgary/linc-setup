Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Reset-PC {
    # Added an if-statement here, if this was not here and it ran a freshly reset pc
    # it would append the temporary MINWINPC name to the file and throw an error trying to rewrite it.
    $CurrentComputerName = $env:COMPUTERNAME

    if ($CurrentComputerName -ne "MINWINPC") {
        Set-Content -Path ".\ComputerName.txt" -Value $CurrentComputerName
    } else {
        do {
            $response = Read-Host "Computer name not set correctly. Please enter the name you wish to rename the PC to after setup"
            if ([string]::IsNullOrWhiteSpace($response)) {
            Write-Linclog -Message "Computer name cannot be empty. Try again." -Level Warning
            } 
        } while ([string]::IsNullOrWhiteSpace($response)) 
        Write-Linclog -Message "Setting computer name to $response" -Level Success
        Set-Content -Path ".\ComputerName.txt" -Value $response
    }

    Write-Linclog -Message "Deleting old hard drive encryption key from Master Log as it is no longer needed." -Level Info
    $Serial = (Get-CimInstance Win32_BIOS).SerialNumber
    
    $LinesRead = @(Get-Content -Path ".\BitLocker_Master_Log.txt" -ErrorAction SilentlyContinue) | Where-Object { $_ }
    $NewLinesToWrite = [System.Collections.Generic.List[string]]::new()
    try {
         if ($LinesRead) {
            for ($i = 0; $i -lt $LinesRead.Length; $i++) {
                if ($LinesRead[$i].Trim().StartsWith($Serial)) {
                    if (($i + 1) -lt $LinesRead.Length -and $LinesRead[$i + 1].Trim().StartsWith('-')) {
                        $i++
                    }
                    continue
                }
                $NewLinesToWrite.Add($LinesRead[$i])
            }
        
            if ($NewLinesToWrite -or $LinesRead.Length -le 2) {
                Write-Linclog -Message "Encryption key successfully deleted." -Level Success
                Write-Linclog -Message "Rewriting the file with the remaining keys..." -Level Info
                Set-Content -Path ".\BitLocker_Master_Log.txt" -Value $NewLinesToWrite
                Write-Linclog -Message "Successfully rewrote the lines." -Level Success
            } else {
                Write-Linclog -Message "Error: File read returned an empty array. Please manually note device Serial number and delete key accordingly." -Level Error
                Write-Linclog -Message "The device serial number is: $Serial, please ensure you delete the old encryption key corresponding to this device." -Level Warning
            }
        } else {
            Write-Linclog -Message "No Serial numbers to delete... continuing Reset Process." -Level Info
        }
    }
    catch {
            Write-Linclog -Message "Updating encryption keys failed: $($_.Exception.Message)" -Level Error
            exit 1
    }
    Start-Sleep -Seconds 3
    Start-Process -FilePath "shutdown.exe" -ArgumentList "/r /t 20"  -NoNewWindow
    Write-Linclog -Message "Once the device has restarted, ensure you enter the BIOS temporary boot (F12) and select the USB drive to boot from." -Level Info
    Write-Linclog -Message "Restarting the device..." -Level Info
}

Export-ModuleMember -Function Reset-PC, Install-PSTools
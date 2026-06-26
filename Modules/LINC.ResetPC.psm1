Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Reset-PC {
    # Added an if-statement here, if this was not here and it ran a freshly reset pc
    # it would append the temporary MINWINPC name to the file and throw an error trying to rewrite it.
    $CurrentComputerName = $env:COMPUTERNAME
    if (!($CurrentComputerName -eq "MINWINPC")) {
        Set-Content -Path ".\ComputerName.txt" -Value $env:COMPUTERNAME
    } else {
        
    }
    Write-Linclog -Message "Deleting old hard drive encryption key from Master Log as it is no longer needed." -Level Info
    $Serial = (Get-CimInstance Win32_BIOS).SerialNumber
    
    $LinesRead = @(Get-Content -Path ".\BitLocker_Master_Log.txt" -ErrorAction SilentlyContinue)
    $NewLinesToWrite = [System.Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $LinesRead.Count; $i++) {
        if ($LinesRead[$i].Trim().StartsWith($Serial)) {
            if (($i + 1) -lt $LinesRead.Count -and $LinesRead[$i + 1].Trim().StartsWith('-')) {`
                $i++
            }
            continue
        }
        $NewLinesToWrite.Add($LinesRead[$i])
    }
    $LinesRead
    $NewLinesToWrite
    if ($NewLinesToWrite -or $LinesRead.Count -le 2) {
        Write-Linclog -Message "Encryption key successfully deleted." -Level Success
        Write-Linclog -Message "Rewriting the file with the remaining keys..." -Level Info
        $NewLinesToWrite | Set-Content -Path ".\BitLocker_Master_Log.txt"
        Write-Linclog -Message "Successfully rewrote the lines." -Level Success
    } else {
        Write-Linclog -Message "Error: File read returned an empty array. Please manually note device Serial number and delete key accordingly." -Level Error
    }
    Start-Sleep -Seconds 3
    Start-Process -FilePath "shutdown.exe" -ArgumentList "/r /t 15 /c `"The computer will restart shortly.`"" -NoNewWindow -Wait
    Write-Linclog -Message "Once the device has restarted, ensure you enter the BIOS temporary boot (F12) and select the USB drive to boot from." -Level Info
    Write-Linclog -Message "Restarting the device..." -Level Info
    
}

Export-ModuleMember -Function Reset-PC, Install-PSTools
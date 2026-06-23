Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Install-PSTools {
    # 1. Define paths
    $zipUrl  = "https://download.sysinternals.com/files/PSTools.zip"
    $zipFile = "$env:TEMP\PSTools.zip"
    $outDir  = "$env:TEMP\PSTools"
    $target  = "$env:SystemRoot\System32\psexec.exe"

    try {
        # 2. Download the PsTools archive
        Write-LincLog -Message "Downloading PsTools..."
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile

        # 3. Extract the contents
        Write-LincLog -Message "Extracting files..."
        Expand-Archive -Path $zipFile -DestinationPath $outDir -Force

        # 4. Move PsExec to System32 & unblock it for execution
        if (Test-Path "$outDir\psexec.exe") {
            Move-Item -Path "$outDir\psexec.exe" -Destination $target -Force
            Unblock-File -Path $target
            
            # 5. Optional: Suppress the first-time EULA prompt
            New-ItemProperty -Path "HKCU:\Software\Sysinternals\PsExec" -Name "EulaAccepted" -Value 1 -PropertyType DWORD -Force -ErrorAction SilentlyContinue
            
            Write-LincLog -Message "PsExec successfully installed to $target" -Level Success
        } else {
            Write-LincLog -Message "PsExec.exe extraction failed." -Level Error
        }
    } catch {
        Write-LincLog -Message "PsExec was not able to be installed." -Level Error
    }
    # 6. Cleanup temp archive
    Remove-Item -Path $zipFile, $outDir -Recurse -Force -ErrorAction SilentlyContinue
}

function Reset-PC {
    Set-Content -Path ".\ComputerName.txt" -Value $env:COMPUTERNAME
    do {
        $response = Read-Host "Do you want to Reset the PC? [Y/N]"
        $response = $response.Trim().ToUpper()
    } until ($response -in @('Y','N'))

    if ($response -eq 'Y') {
        Write-LincLog -Message "Initiating system reset..."
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force

        if (-not (Get-Command psexec -ErrorAction SilentlyContinue)) {
            Write-LincLog -Message "PsExec is not installed. It will now install." -Level Warning
            Install-PSTools
        } else {
            Write-LincLog -Message "PsExec is installed. Continuing Reset process."
        }

        $MyScriptBlock = {
        
            $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name
            Write-LincLog -Message "Running as: $CurrentUser"
            psexec -accepteula
            try { 
                $namespaceName = "root\cimv2\mdm\dmmap"
                $className = "MDM_RemoteWipe"
                $methodName = "doWipeMethod"

                $session = New-CimSession

                $params = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
                $param = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("param", "", "String", "In")
                $params.Add($param)

                $instance = Get-CimInstance -Namespace $namespaceName -ClassName $className -Filter "ParentID='./Vendor/MSFT' and InstanceID='RemoteWipe'"
                $session.InvokeMethod($namespaceName, $instance, $methodName, $params)
            } catch {
                Write-LincLog -Message "System Reset failed." -Level Error
            }
        }

        $ScriptBytes = [System.Text.Encoding]::Unicode.GetBytes($MyScriptBlock.ToString())
        $EncodedCmd = [Convert]::ToBase64String($ScriptBytes)

        psexec -accepteula
        psexec -s powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand $EncodedCmd
    } else {
        Write-LincLog -Message "Skipping PC reset." -Level Warning
    }
}

Export-ModuleMember -Function Reset-PC, Install-PSTools
#requires -RunAsAdministrator
#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ModuleRoot = 'C:\Windows\Temp\Modules' #(Join-Path $PSScriptRoot 'Modules')
)

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Import-LincModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Module file not found: $Path"
    }

    Import-Module -Name $Path -Force -ErrorAction Stop
}

try {
    Import-LincModule -Path (Join-Path $ModuleRoot 'LINC.Common.psm1')
    Import-LincModule -Path (Join-Path $ModuleRoot 'LINC.Users.psm1')
    Import-LincModule -Path (Join-Path $ModuleRoot 'LINC.Apps.psm1')
    Import-LincModule -Path (Join-Path $ModuleRoot 'LINC.Updates.psm1')
    Import-LincModule -Path (Join-Path $ModuleRoot 'LINC.RenamePC.psm1')
    Import-LincModule -Path (Join-Path $ModuleRoot 'LINC.ResetPC.psm1')
    Import-LincModule -Path (Join-Path $ModuleRoot 'LINC.ChangeWiFi.psm1');

    if (-not (Test-LincAdministrator)) {
        throw 'This script must be run as Administrator.'
    }
    do {
        $response = Read-Host "Do you want to Reset the PC? [Y/N]"
        $response = $response.Trim().ToUpper()
    } until ($response -in @('Y','N'))

    if ($response -eq 'Y') {
        Invoke-LincStep -StepName 'Reset PC' -ScriptBlock { Reset-PC }
    } else {
        Invoke-LincStep -StepName 'User creation' -ScriptBlock { New-LincStudentUser }
        Invoke-LincStep -StepName 'Custom app installation' -ScriptBlock {
            Install-LincGoogleChrome
            Install-LincZoom
        }
        Invoke-LincStep -StepName 'Windows update' -ScriptBlock { Install-LincWindowsUpdate }
        Invoke-LincStep -StepName 'WiFi Change' -ScriptBlock { 
            Add-LincWiFi
            Connect-LincWiFi
        }
        Invoke-LincStep -StepName 'Rename PC' -ScriptBlock { Rename-LincPC }
        Write-Linclog -Message "All steps completed." -Level Success
        Write-Linclog -Message "Computer will now restart to finish Windows update process." -Level Info
        Start-Sleep -Seconds 5
        Restart-Computer -Force
    }
    
    
}
catch {
    Write-LincLog -Message "Setup failed: $($_.Exception.Message)" -Level Error
    exit 1
}
finally {
    $NULL = Read-Host "Press enter to exit"
}
#requires -RunAsAdministrator
#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ModuleRoot = '.\Modules' #(Join-Path $PSScriptRoot 'Modules')
)

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

    if (-not (Test-LincAdministrator)) {
        throw 'This script must be run as Administrator.'
    }

    Invoke-LincStep -StepName 'User creation' -ScriptBlock { New-LincStudentUser }
    Invoke-LincStep -StepName 'Custom app installation' -ScriptBlock {
        Install-LincGoogleChrome
        Install-LincZoom
    }
    Invoke-LincStep -StepName 'Windows update' -ScriptBlock { Install-LincWindowsUpdate }
}
catch {
    Write-LincLog -Message "Setup failed: $($_.Exception.Message)" -Level Error
    exit 1
}
finally {
    Read-Host -Prompt "Press ENTER to exit"
}
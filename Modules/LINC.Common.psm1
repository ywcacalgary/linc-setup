Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-LincLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $prefix = "[$timestamp][$Level]"

    switch ($Level) {
        'Success' { Write-Host "$prefix $Message" -ForegroundColor Green }
        'Warning' { Write-Host "$prefix $Message" -ForegroundColor Yellow }
        'Error'   { Write-Host "$prefix $Message" -ForegroundColor Red }
        default   { Write-Host "$prefix $Message" -ForegroundColor White }
    }
}

function Invoke-LincStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$StepName,
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )

    try {
        Write-LincLog -Message "Starting: $StepName"
        & $ScriptBlock
        Write-LincLog -Message "Completed: $StepName" -Level Success
    }
    catch {
        Write-LincLog -Message "Failed: $StepName. $($_.Exception.Message)" -Level Error
        throw
    }
}

function Test-LincAdministrator {
    [CmdletBinding()]
    param()

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-LincDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uri]$Uri,
        [Parameter(Mandatory)]
        [string]$DestinationPath
    )

    try {
        Start-BitsTransfer -Source $Uri.AbsoluteUri -Destination $DestinationPath -ErrorAction Stop
    }
    catch {
        Invoke-WebRequest -Uri $Uri.AbsoluteUri -OutFile $DestinationPath -UseBasicParsing -ErrorAction Stop
    }
}

function Test-LincCommandAvailable {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name)
    [bool](Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

Export-ModuleMember -Function Write-LincLog, Invoke-LincStep, Test-LincAdministrator, Invoke-LincDownload, Test-LincCommandAvailable
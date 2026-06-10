#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$SourceRoot = $PSScriptRoot,
    [string]$OutputRoot = (Join-Path $PSScriptRoot 'dist'),
    [string]$ExeName = 'LINC.Setup.exe'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-BuildLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    switch ($Level) {
        'Success' { Write-Host "[$timestamp][$Level] $Message" -ForegroundColor Green }
        'Warning' { Write-Host "[$timestamp][$Level] $Message" -ForegroundColor Yellow }
        'Error'   { Write-Host "[$timestamp][$Level] $Message" -ForegroundColor Red }
        default   { Write-Host "[$timestamp][$Level] $Message" -ForegroundColor White }
    }
}

try {
    $moduleSource = Join-Path $SourceRoot 'Modules'
    $mainScript = Join-Path $SourceRoot 'LINC.Setup.ps1'
    $manifest = Join-Path $SourceRoot 'LINC.Setup.psd1'
    $stagingRoot = Join-Path $OutputRoot 'staging'
    $packageRoot = Join-Path $OutputRoot 'package'
    $exePath = Join-Path $packageRoot $ExeName

    if (-not (Test-Path $mainScript)) { throw "Main script not found: $mainScript" }
    if (-not (Test-Path $moduleSource)) { throw "Modules folder not found: $moduleSource" }

    New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null

    if (-not (Get-Module -ListAvailable -Name PS2EXE)) {
        Install-Module -Name PS2EXE -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    }

    Import-Module PS2EXE -ErrorAction Stop

    Copy-Item -Path $mainScript -Destination $stagingRoot -Force
    Copy-Item -Path $manifest -Destination $stagingRoot -Force
    Copy-Item -Path $moduleSource -Destination (Join-Path $stagingRoot 'Modules') -Recurse -Force

    $stagedScript = Join-Path $stagingRoot 'LINC.Setup.ps1'
    Invoke-PS2EXE -InputFile $stagedScript -OutputFile $exePath -NoConsole -ErrorAction Stop

    Copy-Item -Path (Join-Path $stagingRoot 'Modules') -Destination $packageRoot -Recurse -Force
    Copy-Item -Path (Join-Path $stagingRoot 'LINC.Setup.psd1') -Destination $packageRoot -Force

    Write-BuildLog -Message "Build completed: $exePath" -Level Success
}
catch {
    Write-BuildLog -Message "Build failed: $($_.Exception.Message)" -Level Error
    throw
}
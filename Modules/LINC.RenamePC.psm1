Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Rename-LincPC {
    $NewName = (Get-Content -Path ".\ComputerName.txt").Trim()
    Rename-Computer -NewName $NewName -Force -ErrorAction SilentlyContinue
}

Export-ModuleMember -Function Rename-LincPC
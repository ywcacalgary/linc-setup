Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Rename-LincPC {
    $NewName = (Get-Content -Path ".\ComputerName.txt").Trim()
    Rename-Computer -NewName $NewName -Force
}

Export-ModuleMember -Function Rename-LincPC
#Requires -Version 5.1
[CmdletBinding()]
param(
  # Path to the JSON preset file
  [Parameter(Mandatory = $true)]
  [string]$Preset
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$runner = Join-Path $PSScriptRoot "run-preset.ps1"
if (-not (Test-Path -LiteralPath $runner)) {
  throw "run-preset.ps1 not found next to run-preset-pause.ps1: $runner"
}

try {
  & $runner -Preset $Preset
}
finally {
  Write-Host "Press any key to exit..."
  [void][System.Console]::ReadKey($true)
}

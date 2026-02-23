#Requires -Version 5.1
[CmdletBinding()]
param(
  # Path to the JSON preset file
  [Parameter(Mandatory = $true)]
  [string]$Preset
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Preset)) {
  throw "Preset file not found: $Preset"
}

$makeVideo = Join-Path $PSScriptRoot "make-video.ps1"
if (-not (Test-Path -LiteralPath $makeVideo)) {
  throw "make-video.ps1 not found next to run-preset.ps1: $makeVideo"
}

$presetPath = (Resolve-Path -LiteralPath $Preset).Path

# Read JSON
$jsonText = Get-Content -LiteralPath $presetPath -Raw -Encoding UTF8
$data = $jsonText | ConvertFrom-Json

# ConvertFrom-Json returns a PSCustomObject. Convert it to a hashtable for splatting.
$params = @{}
foreach ($prop in $data.PSObject.Properties) {
  $params[$prop.Name] = $prop.Value
}

# Run make-video.ps1 from its own directory so relative assets and Data/ paths
# are resolved next to the script.
Push-Location $PSScriptRoot
try {
  & $makeVideo @params
}
finally {
  Pop-Location
}

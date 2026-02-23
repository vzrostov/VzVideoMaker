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
$presetDir  = Split-Path -Parent $presetPath

# Read JSON
$jsonText = Get-Content -LiteralPath $presetPath -Raw -Encoding UTF8
$data = $jsonText | ConvertFrom-Json

# ConvertFrom-Json returns a PSCustomObject. Convert it to a hashtable for splatting.
$params = @{}
foreach ($prop in $data.PSObject.Properties) {
  $params[$prop.Name] = $prop.Value
}

function Resolve-IfRelative([object]$value, [string]$baseDir) {
  if ($null -eq $value) { return $value }
  if ($value -isnot [string]) { return $value }
  if ([string]::IsNullOrWhiteSpace($value)) { return $value }
  if ([System.IO.Path]::IsPathRooted($value)) { return $value }
  return (Join-Path $baseDir $value)
}

# If the preset contains relative paths, resolve them relative to the preset directory.
if ($params.ContainsKey('InFile'))   { $params['InFile']   = Resolve-IfRelative $params['InFile']   $presetDir }
if ($params.ContainsKey('OutFile'))  { $params['OutFile']  = Resolve-IfRelative $params['OutFile']  $presetDir }
if ($params.ContainsKey('Subs'))     { $params['Subs']     = Resolve-IfRelative $params['Subs']     $presetDir }
if ($params.ContainsKey('FontFile')) { $params['FontFile'] = Resolve-IfRelative $params['FontFile'] $presetDir }

# Run make-video.ps1 from its own directory so relative assets (e.g. icon.gif)
# are resolved next to the script.
Push-Location $PSScriptRoot
try {
  & $makeVideo @params
}
finally {
  Pop-Location
}

Write-Host "Press any key to exit..."
[void][System.Console]::ReadKey($true)

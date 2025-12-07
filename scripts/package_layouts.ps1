Param(
  [string]$Version = $(Get-Date -Format 'yyyyMMddHHmmss')
)

Write-Output "[package] Packaging All Keyboard Layouts (version: $Version)"

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$layouts = Join-Path $root '..\All Keyboard Layouts (1.0.3.40)'
$out = Join-Path $root '..\dist'
if (-not (Test-Path $out)) { New-Item -ItemType Directory -Path $out | Out-Null }

Push-Location $layouts
try {
  $hassha = (Get-Content -Raw -Path .\layouts.json | ConvertFrom-Json | Where-Object { $_.sha256 }) -ne $null
} catch {
  $hassha = $false
}
if (-not $hassha) {
  Write-Output "layouts.json has no embedded sha256 entries — generating helper layouts.checksums.json"
  & "$root\compute_checksums.bat"
}

$zipname = "All.Keyboard.Layouts.$Version.zip"
Compress-Archive -Path * -DestinationPath (Join-Path $out $zipname) -Force
Write-Output "[package] Wrote: $out\$zipname"
Pop-Location

Param(
  [string]$Version = $(Get-Date -Format 'yyyyMMddHHmmss')
)

Write-Output "[package] Packaging All Keyboard Layouts (version: $Version)"

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$layouts = Join-Path $root '..\All Keyboard Layouts (1.0.3.40)'
$out = Join-Path $root '..\dist'
if (-not (Test-Path $out)) { New-Item -ItemType Directory -Path $out | Out-Null }

Push-Location $layouts
if (-not (Test-Path .\install_checksums.txt)) {
  Write-Output "Checksums missing — generating install_checksums.txt"
  & "$root\compute_checksums.bat"
}

$zipname = "All.Keyboard.Layouts.$Version.zip"
Compress-Archive -Path * -DestinationPath (Join-Path $out $zipname) -Force
Write-Output "[package] Wrote: $out\$zipname"
Pop-Location

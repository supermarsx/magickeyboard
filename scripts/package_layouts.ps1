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
  $matrix = Get-Content -Raw -Encoding UTF8 -Path .\layouts.json | ConvertFrom-Json
  $entries = @($matrix.PSObject.Properties | ForEach-Object { $_.Value })
  $hassha = @(
    $entries | Where-Object {
      $_ -and $_.PSObject.Properties.Name -contains 'sha256' -and -not [string]::IsNullOrWhiteSpace($_.sha256)
    }
  ).Count -gt 0
} catch {
  $hassha = $false
}
if (-not $hassha) {
  Write-Output "layouts.json has no embedded sha256 entries - generating helper layouts.checksums.json"
  & "$root\compute_checksums.bat"
}

$zipname = "All.Keyboard.Layouts.$Version.zip"
Compress-Archive -Path * -DestinationPath (Join-Path $out $zipname) -Force
Write-Output "[package] Wrote: $out\$zipname"
Pop-Location

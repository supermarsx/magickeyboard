<#
  uninstall_registry_from_matrix.ps1

  Purpose:
    Read layouts.json and delete registry entries for the keyboard layout collection.

  Usage:
    -MatrixPath <path-to-layouts.json>   (defaults to script directory /layouts.json)
    -DryRun                               (prints what would be done without deleting)

  Notes:
    - Safe for simulation via -DryRun; when actually running it requires elevation to delete HKLM keys.
#>

param(
  [string] $MatrixPath = "$PSScriptRoot\layouts.json",
  [switch] $DryRun
)

if (-not (Test-Path $MatrixPath)) {
  Write-Error "Matrix file not found: $MatrixPath"
  exit 2
}

$matrix = Get-Content -Raw -Path $MatrixPath | ConvertFrom-Json

foreach ($key in $matrix.PSObject.Properties.Name) {
  $entry = $matrix.$key

  if ($entry.PSObject.Properties.Name -contains 'reg_path' -and $entry.reg_path) {
    $fullRegPath = $entry.reg_path -replace '\\{2,}','\\'
    if ($fullRegPath -like 'HKLM\\*') { $fullRegPath = $fullRegPath -replace '^HKLM\\','HKLM:\' }
  } elseif ($entry.PSObject.Properties.Name -contains 'reg_key' -and $entry.reg_key) {
    $fullRegPath = "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Keyboard Layouts\\$($entry.reg_key)"
  } else {
    Write-Warning "Skipping $key - no reg_path or reg_key available in matrix"
    continue
  }

  if ($DryRun) {
    Write-Host "DRYRUN: would delete registry key $fullRegPath"
    continue
  }

  try {
    if (Test-Path $fullRegPath) {
      Remove-Item -Path $fullRegPath -Recurse -Force -ErrorAction Stop
      Write-Host "OK: removed registry key $fullRegPath"
    } else {
      Write-Host "Not present: $fullRegPath"
    }
  } catch {
    $errMsg = ($_ | Out-String).Trim()
    Write-Warning ("Failed to remove registry key for {0}: {1}" -f $key, $errMsg)
    exit 1
  }
}

Exit 0

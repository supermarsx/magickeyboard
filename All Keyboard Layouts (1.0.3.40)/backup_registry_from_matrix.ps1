<#
  backup_registry_from_matrix.ps1

  Purpose:
    Create a safety backup of the registry keys touched by this repo's layouts.json.

  Output format:
    JSON file containing an array of entries with prior existence and selected properties.

  Notes:
    - Reading HKLM is generally allowed for non-admin; writing/restoring requires elevation.
    - This backs up only the keys referenced by layouts.json (or a subset via -Layouts).
#>

param(
  [string] $MatrixPath = "$PSScriptRoot\layouts.json",
  [string] $OutFile,
  [switch] $DryRun,
  [string[]] $Layouts
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $MatrixPath)) {
  Write-Error "Matrix file not found: $MatrixPath"
  exit 2
}

# Support comma-separated single-argument for -Layouts
if ($Layouts -and $Layouts.Count -eq 1 -and $Layouts[0] -match ',') {
  $Layouts = $Layouts[0] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
}

function Resolve-FullRegPath {
  param($entry)

  if ($entry.PSObject.Properties.Name -contains 'reg_path' -and $entry.reg_path) {
    $full = ($entry.reg_path -replace '\\{2,}', '\\')
    if ($full -like 'HKLM\\*') { $full = $full -replace '^HKLM\\', 'HKLM:\\' }
    return $full
  }

  if ($entry.PSObject.Properties.Name -contains 'reg_key' -and $entry.reg_key) {
    return "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Keyboard Layouts\\$($entry.reg_key)"
  }

  return $null
}

$matrix = Get-Content -Raw -Path $MatrixPath | ConvertFrom-Json

if (-not $OutFile -or $OutFile -eq '1') {
  $stamp = (Get-Date).ToString('yyyyMMddHHmmss')
  $OutFile = Join-Path $env:TEMP "magickeyboard_registry_backup_$stamp.json"
}

$parent = Split-Path -Parent $OutFile
if ($parent -and -not (Test-Path $parent)) {
  New-Item -ItemType Directory -Path $parent | Out-Null
}

$propertyNames = @('Layout Text', 'Layout File', 'Layout Id', 'Layout Component ID')

$entries = @()
foreach ($p in $matrix.PSObject.Properties) {
  $key = $p.Name

  if ($Layouts -and $Layouts.Count -gt 0 -and ($Layouts -notcontains $key)) {
    continue
  }

  $entry = $p.Value
  $regPath = Resolve-FullRegPath -entry $entry
  if (-not $regPath) {
    Write-Warning "Skipping $key - no reg_path or reg_key in matrix"
    continue
  }

  $existed = $false
  $present = @{}
  $props = @{}

  try {
    if (Test-Path $regPath) {
      $existed = $true
      $item = Get-ItemProperty -Path $regPath -ErrorAction Stop
      foreach ($name in $propertyNames) {
        if ($item.PSObject.Properties.Name -contains $name) {
          $present[$name] = $true
          $props[$name] = ($item.$name -as [string])
        } else {
          $present[$name] = $false
        }
      }
    } else {
      foreach ($name in $propertyNames) { $present[$name] = $false }
    }
  } catch {
    Write-Warning ("Failed reading registry for {0} at {1}: {2}" -f $key, $regPath, (($_ | Out-String).Trim()))
    foreach ($name in $propertyNames) { if (-not $present.ContainsKey($name)) { $present[$name] = $false } }
  }

  $entries += [pscustomobject]@{
    key     = $key
    regPath = $regPath
    existed = $existed
    present = $present
    values  = $props
  }
}

$backup = [pscustomobject]@{
  createdUtc = (Get-Date).ToUniversalTime().ToString('o')
  matrixPath = (Resolve-Path -Path $MatrixPath).Path
  layouts    = $Layouts
  entries    = $entries
}

if ($DryRun) {
  Write-Output "DRYRUN: would write registry backup to $OutFile"
  Write-Output ("DRYRUN: entries = {0}" -f $entries.Count)
  exit 0
}

$backup | ConvertTo-Json -Depth 8 | Set-Content -Path $OutFile -Encoding UTF8
Write-Output "OK: wrote registry backup to $OutFile"
exit 0

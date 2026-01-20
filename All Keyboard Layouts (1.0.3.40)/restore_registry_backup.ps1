<#
  restore_registry_backup.ps1

  Purpose:
    Restore registry keys previously backed up by backup_registry_from_matrix.ps1.

  Semantics:
    - If a key did not exist at backup time, it is removed on restore (if present).
    - If it existed, selected properties are restored; properties absent at backup time are removed.

  Notes:
    - Requires elevation when writing to HKLM.
#>

param(
  [Parameter(Mandatory = $true)][string] $BackupPath,
  [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $BackupPath)) {
  Write-Error "Backup file not found: $BackupPath"
  exit 2
}

$backup = Get-Content -Raw -Path $BackupPath | ConvertFrom-Json
if (-not $backup.entries) {
  Write-Error "Backup file does not contain entries: $BackupPath"
  exit 3
}

$propertyNames = @('Layout Text', 'Layout File', 'Layout Id', 'Layout Component ID')

foreach ($e in $backup.entries) {
  $regPath = $e.regPath
  $keyName = $e.key

  if (-not $regPath) {
    Write-Warning "Skipping entry with missing regPath (key=$keyName)"
    continue
  }

  if (-not $e.existed) {
    if ($DryRun) {
      Write-Output "DRYRUN: would remove registry key $regPath (was absent in backup)"
      continue
    }

    if (Test-Path $regPath) {
      Remove-Item -Path $regPath -Recurse -Force
      Write-Output "OK: removed $regPath (was absent in backup)"
    } else {
      Write-Output "Not present: $regPath"
    }
    continue
  }

  if ($DryRun) {
    Write-Output "DRYRUN: would restore registry key $regPath"
    continue
  }

  if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
  }

  foreach ($name in $propertyNames) {
    $wasPresent = $false
    if ($e.present -and ($e.present.PSObject.Properties.Name -contains $name)) {
      $wasPresent = [bool]$e.present.$name
    }

    if ($wasPresent) {
      $val = $null
      if ($e.values -and ($e.values.PSObject.Properties.Name -contains $name)) {
        $val = $e.values.$name
      }
      New-ItemProperty -Path $regPath -Name $name -Value ($val -as [string]) -PropertyType String -Force | Out-Null
    } else {
      try {
        $cur = Get-ItemProperty -Path $regPath -ErrorAction Stop
        if ($cur.PSObject.Properties.Name -contains $name) {
          Remove-ItemProperty -Path $regPath -Name $name -ErrorAction SilentlyContinue
        }
      } catch {
        # ignore
      }
    }
  }

  Write-Output "OK: restored $regPath"
}

exit 0

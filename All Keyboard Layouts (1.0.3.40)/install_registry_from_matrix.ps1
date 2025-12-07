<#
  install_registry_from_matrix.ps1

  Purpose:
    Read layouts.json to create registry entries for the keyboard layout collection.

  Usage:
    -MatrixPath <path-to-layouts.json>   (defaults to script directory /layouts.json)
    -TranslationsPath <path-to-translations.json> (defaults to script dir /translations.json)
    -DryRun                                (prints what would be done without writing)

  Notes:
    - Uses get_translation.ps1 (in same directory) to resolve localized Layout Text.
    - Safe for simulation via -DryRun; does not require administrator right for dry-run.
    - When actually writing, it creates keys under HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\<reg_key>
#>

param(
  [string] $MatrixPath = "$PSScriptRoot\layouts.json",
  [string] $TranslationsPath = "$PSScriptRoot\translations.json",
  [switch] $DryRun
)

if (-not (Test-Path $MatrixPath)) {
  Write-Error "Matrix file not found: $MatrixPath"
  exit 2
}

$matrix = Get-Content -Raw -Path $MatrixPath | ConvertFrom-Json

foreach ($key in $matrix.PSObject.Properties.Name) {
  $entry = $matrix.$key

  # resolve translated layout text using the helper script if available
  $layoutText = $null
  $gt = Join-Path $PSScriptRoot 'get_translation.ps1'
  if (Test-Path $gt) {
    try {
      $layoutText = & $gt -Key $key -File $TranslationsPath -ErrorAction Stop
      # get_translation.ps1 prints the string — trim it
      if ($LASTEXITCODE -ne 0) { $layoutText = $null }
      $layoutText = $layoutText -as [string]
    } catch {
      $layoutText = $null
    }
  }

  if (-not $layoutText) {
    # fallback to english name in translations.json or key name
    try {
      $t = Get-Content -Raw -Path $TranslationsPath | ConvertFrom-Json
      if ($t.$key -and $t.$key.en) { $layoutText = $t.$key.en }
      else { $layoutText = $key }
    } catch { $layoutText = $key }
  }

  # prefer explicit reg_path in matrix; otherwise construct from reg_key
  if ($entry.PSObject.Properties.Name -contains 'reg_path' -and $entry.reg_path) {
    $fullRegPath = $entry.reg_path -replace '\\{2,}','\\'
    # normalize leading HKLM\ to HKLM:\ for the registry provider
    if ($fullRegPath -like 'HKLM\\*') { $fullRegPath = $fullRegPath -replace '^HKLM\\','HKLM:\' }
  } else {
    $regKey = $entry.reg_key
    $fullRegPath = "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Keyboard Layouts\\$regKey"
  }

  if ($DryRun) {
    Write-Host "DRYRUN: would create registry key $fullRegPath"
    if ($layoutText) { Write-Host "DRYRUN:   Layout Text = $layoutText" }
    if ($entry.file) { Write-Host "DRYRUN:   Layout File = $($entry.file)" }
    if ($entry.layout_id) { Write-Host "DRYRUN:   Layout Id = $($entry.layout_id)" }
    if ($entry.component_id) { Write-Host "DRYRUN:   Layout Component ID = $($entry.component_id)" }
    continue
  }

  # Ensure the registry key exists
  try {
    if (-not (Test-Path $fullRegPath)) { New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\$regKey" -Force | Out-Null }

    # Set Layout Text when present
    if ($layoutText) { New-ItemProperty -Path $fullRegPath -Name 'Layout Text' -Value $layoutText -PropertyType String -Force | Out-Null }

    if ($entry.file) { New-ItemProperty -Path $fullRegPath -Name 'Layout File' -Value $entry.file -PropertyType String -Force | Out-Null }
    if ($entry.layout_id) { New-ItemProperty -Path $fullRegPath -Name 'Layout Id' -Value $entry.layout_id -PropertyType String -Force | Out-Null }
    if ($entry.component_id) { New-ItemProperty -Path $fullRegPath -Name 'Layout Component ID' -Value $entry.component_id -PropertyType String -Force | Out-Null }

    Write-Host "OK: registry updated for $key -> $fullRegPath"
  } catch {
    # Use Out-String to safely include the error object in the message on all platforms
    $errMsg = ($_ | Out-String).Trim()
    Write-Warning ("Failed to update registry for {0}: {1}" -f $key, $errMsg)
    exit 1
  }
}

Exit 0

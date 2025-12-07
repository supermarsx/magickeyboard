param(
  [string] $LayoutDir = "$PSScriptRoot/../../All Keyboard Layouts (1.0.3.40)"
)

$layoutDir = Resolve-Path -Path $LayoutDir
$matrixPath = Join-Path $layoutDir 'layouts.json'
$installScript = Join-Path $layoutDir 'install_registry_from_matrix.ps1'
$uninstallScript = Join-Path $layoutDir 'uninstall_registry_from_matrix.ps1'

if (-not (Test-Path $matrixPath)) { Write-Error "Missing layouts.json: $matrixPath"; exit 2 }

$matrix = Get-Content -Raw -Path $matrixPath | ConvertFrom-Json

# Count matrix entries that include a reg_path or reg_key (these are actionable entries)
$actionable = 0
foreach ($v in $matrix.PSObject.Properties.Value) {
  if (($v.PSObject.Properties.Name -contains 'reg_path' -and $v.reg_path) -or ($v.PSObject.Properties.Name -contains 'reg_key' -and $v.reg_key)) { $actionable++ }
}

if ($actionable -lt 1) { Write-Error "No actionable matrix entries found"; exit 3 }

Write-Host "Matrix actionable entries: $actionable"

# run install dry-run and ensure the number of 'would create' lines matches actionable count
$installOut = & pwsh -NoProfile -ExecutionPolicy Bypass -File $installScript -MatrixPath $matrixPath -TranslationsPath (Join-Path $layoutDir 'translations.json') -DryRun 2>$null
$installCreateCount = ($installOut -split "`n" | Where-Object { $_ -match 'DRYRUN: would create registry key' }).Count
if ($installCreateCount -ne $actionable) { Write-Error "Install dry-run count mismatch: $installCreateCount vs $actionable"; exit 4 }
Write-Host "OK: install dry-run produced $installCreateCount create lines"

# run uninstall dry-run and ensure delete lines match actionable count
$uninstallOut = & pwsh -NoProfile -ExecutionPolicy Bypass -File $uninstallScript -MatrixPath $matrixPath -DryRun 2>$null
$deleteCount = ($uninstallOut -split "`n" | Where-Object { $_ -match 'DRYRUN: would delete registry key' }).Count
if ($deleteCount -ne $actionable) { Write-Error "Uninstall dry-run count mismatch: $deleteCount vs $actionable"; exit 5 }
Write-Host "OK: uninstall dry-run produced $deleteCount delete lines"

Write-Host "All PowerShell matrix dry-run tests passed"

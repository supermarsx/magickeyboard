Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

$starts = @()
if ($PSScriptRoot) { $starts += $PSScriptRoot }
$starts += (Get-Location).Path
if ($env:GITHUB_WORKSPACE) { $starts += $env:GITHUB_WORKSPACE }
$found = $null
foreach ($s in $starts) {
    if (-not $s) { continue }
    try { $cur = (Resolve-Path -Path $s).Path } catch { continue }
    while ($true) {
        if (Test-Path (Join-Path $cur 'All Keyboard Layouts (1.0.3.40)')) { $found = $cur; break }
        $parent = Split-Path -Parent $cur
        if ($parent -eq $cur) { break }
        $cur = $parent
    }
    if ($found) { break }
}
if (-not $found) { throw "Repo root with layouts directory not found" }
$LayoutDir = Resolve-Path "$found/All Keyboard Layouts (1.0.3.40)"
$matrixPath = Join-Path $LayoutDir 'layouts.json'
$installScript = Join-Path $LayoutDir 'install_registry_from_matrix.ps1'
$uninstallScript = Join-Path $LayoutDir 'uninstall_registry_from_matrix.ps1'

Describe 'Matrix installer dry-run' {
    BeforeAll {
        if (-not (Test-Path $matrixPath)) { throw "Missing layouts.json: $matrixPath" }
        $matrix = Get-Content -Raw -Path $matrixPath | ConvertFrom-Json
        $actionable = 0
        foreach ($v in $matrix.PSObject.Properties.Value) {
            if (($v.PSObject.Properties.Name -contains 'reg_path' -and $v.reg_path) -or ($v.PSObject.Properties.Name -contains 'reg_key' -and $v.reg_key)) { $actionable++ }
        }
    }

    It 'has actionable entries in matrix' {
        $actionable | Should -BeGreaterThan 0
    }

    It 'install dry-run emits the expected number of create messages' {
        $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $installScript -MatrixPath $matrixPath -TranslationsPath (Join-Path $LayoutDir 'translations.json') -DryRun 2>$null
        $createCount = ($out -split "`n" | Where-Object { $_ -match 'DRYRUN: would create registry key' }).Count
        $createCount | Should -Be $actionable
    }

    It 'uninstall dry-run emits the expected number of delete messages' {
        $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $uninstallScript -MatrixPath $matrixPath -DryRun 2>$null
        $deleteCount = ($out -split "`n" | Where-Object { $_ -match 'DRYRUN: would delete registry key' }).Count
        $deleteCount | Should -Be $actionable
    }
}

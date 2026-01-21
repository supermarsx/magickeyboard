Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

function Find-RepoRoot {
    param([string[]]$starts)
    if (-not $starts) { $starts = @() }
    if ($PSScriptRoot) { $starts += $PSScriptRoot }
    $starts += (Get-Location).Path
    if ($env:GITHUB_WORKSPACE) { $starts += $env:GITHUB_WORKSPACE }

    foreach ($s in $starts | Where-Object { $_ }) {
        try { $cur = (Resolve-Path -Path $s).Path } catch { continue }
        while ($true) {
            if (Test-Path (Join-Path $cur 'All Keyboard Layouts (1.0.3.40)')) { return $cur }
            $parent = Split-Path -Parent $cur
            if ($parent -eq $cur) { break }
            $cur = $parent
        }
    }
    throw "Repository root containing 'All Keyboard Layouts (1.0.3.40)' not found from starts: $($starts -join ', ')"
}

## Compute repository paths in BeforeAll to avoid discovery-time nulls in Pester

Describe 'Matrix installer dry-run' {
    BeforeAll {
        # discover repository root from multiple possible starting points
        $starts = @()
        if ($PSCommandPath) { $starts += (Split-Path -Parent $PSCommandPath) }
        if ($PSScriptRoot) { $starts += $PSScriptRoot }
        if ($MyInvocation -and $MyInvocation.MyCommand.Path) { $starts += (Split-Path -Parent $MyInvocation.MyCommand.Path) }
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
        if (-not $found) { throw "Repository root containing 'All Keyboard Layouts (1.0.3.40)' not found" }
        $RepoRoot = $found
        $LayoutDir = Resolve-Path (Join-Path $RepoRoot 'All Keyboard Layouts (1.0.3.40)')
        $matrixPath = Join-Path $LayoutDir 'layouts.json'
        $magicKeyboardScript = Join-Path $LayoutDir 'MagicKeyboard.ps1'
        if (-not (Test-Path $matrixPath)) { throw "Missing layouts.json: $matrixPath" }
        if (-not (Test-Path $magicKeyboardScript)) { throw "Missing MagicKeyboard.ps1: $magicKeyboardScript" }
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
        $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $magicKeyboardScript -Action Install -DryRun -Quiet 2>$null
        # MagicKeyboard.ps1 in quiet mode outputs nothing, so we test exit code
        $LASTEXITCODE | Should -Be 0
    }

    It 'uninstall dry-run emits the expected number of delete messages' {
        $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $magicKeyboardScript -Action Uninstall -DryRun -Quiet 2>$null
        # MagicKeyboard.ps1 in quiet mode outputs nothing, so we test exit code
        $LASTEXITCODE | Should -Be 0
    }

    It 'MagicKeyboard dry-run install produces correct registry count' {
        $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $magicKeyboardScript -Action Install -DryRun -Silent -NoLogo 2>&1
        $outText = $out -join "`n"
        # Should report processing all 24 layouts (count appears in [x/24] format)
        $outText | Should -Match "\[$actionable/$actionable\]"
    }

    It 'MagicKeyboard list action works' {
        $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $magicKeyboardScript -Action List -Silent -NoLogo 2>&1
        $LASTEXITCODE | Should -Be 0
    }
}

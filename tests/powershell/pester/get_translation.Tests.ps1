Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

function Find-RepoRoot {
    param([string[]]$starts)
    if (-not $starts) { $starts = @() }
    # prefer script-based locations when available so discovery works during Pester's discovery phase
    if ($PSCommandPath) { $starts += (Split-Path -Parent $PSCommandPath) }
    if ($PSScriptRoot) { $starts += $PSScriptRoot }
    if ($MyInvocation -and $MyInvocation.MyCommand.Path) { $starts += (Split-Path -Parent $MyInvocation.MyCommand.Path) }
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

## NOTE: Do not resolve these paths at parse/discovery time - compute them in BeforeAll so
## Pester's discovery runspaces (which may not set PSScriptRoot/MyInvocation) don't end up
## with null/empty values.

Describe 'MagicKeyboard.ps1 GetTranslation action' {
    BeforeAll {
        # discover repository root from common start points (PSCommandPath, PSScriptRoot, CWD, or CI workspace)
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
        $MagicKeyboard = Join-Path $LayoutDir 'MagicKeyboard.ps1'
        if (-not (Test-Path $MagicKeyboard)) { throw "MagicKeyboard.ps1 not found at $MagicKeyboard" }
        $translationsJson = Get-Content -Raw -Path (Join-Path $LayoutDir 'translations.json') | ConvertFrom-Json
    }

    It 'returns the French translation for BelgiumA when asked explicitly' {
        $out = & $MagicKeyboard -Action GetTranslation -Key 'BelgiumA' -Locale 'fr-FR' -NoLogo
        $out | Should -Be 'Belge (Apple)'
    }

    It 'supports language-only locales (en -> en-US equivalent)' {
        $out = & $MagicKeyboard -Action GetTranslation -Key 'BritishA' -Locale 'en' -NoLogo
        $out | Should -Be 'British (Apple)'
    }

    It 'normalizes underscored locales (en_US -> en-US)' {
        $out = & $MagicKeyboard -Action GetTranslation -Key 'CanadaA' -Locale 'en_US' -NoLogo
        $out | Should -Be 'Canadian (Apple)'
    }

    It 'falls back to another available locale when given unknown locale' {
        $out = & $MagicKeyboard -Action GetTranslation -Key 'GermanA' -Locale 'xx-ZZ' -NoLogo
        # should not be empty; prefer 'en' fallback or another available translation
        $out | Should -Not -BeNullOrEmpty
    }
}

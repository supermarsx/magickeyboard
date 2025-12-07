Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

function Find-RepoRoot {
    param([string[]]$starts)
    if (-not $starts) { $starts = @() }
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

## NOTE: Resolve repository-related paths at runtime in BeforeAll to avoid discovery-time nulls

Describe 'Translations matrix' {
    BeforeAll {
        # discover repo root robustly during test runtime
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
        $translations = Join-Path $LayoutDir 'translations.json'
        if (-not (Test-Path $translations)) { throw "translations.json not found at $translations" }
        $json = Get-Content -Raw -Path $translations | ConvertFrom-Json
        $reqLocales = 'en','en-US','fr-FR','de-DE','es-ES','nl-NL','it-IT','pt-PT','pt-BR','ru-RU','zh-CN','zh-TW','pl-PL','sv-SE','fi-FI','nb-NO','cs-CZ','hu-HU','tr-TR','en-CA'
    }

    It 'contains all required locales for each key and no empty placeholders' {
        $keys = (Get-Content -Raw -Path (Join-Path $LayoutDir 'layouts.json') | ConvertFrom-Json).PSObject.Properties.Name
        foreach ($k in $keys) {
            foreach ($loc in $reqLocales) {
                $val = $json.$k.$loc
                $val | Should -Not -BeNullOrEmpty -Because "Locale $loc must be present for $k"
                $val | Should -Not -Be $k -Because "Translation for $k in $loc must not be placeholder"
            }
        }
    }

    Context 'fallback and format checks' {
        It 'supports language-only fallback (en)' {
            $out = & (Join-Path $LayoutDir 'get_translation.ps1') -Key 'BritishA' -File $translations -Locale 'en'
            $out | Should -Be 'British (Apple)'
        }

        It 'supports regional/language normalization (en_US -> en-US)' {
            $out = & (Join-Path $LayoutDir 'get_translation.ps1') -Key 'CanadaA' -File $translations -Locale 'en_US'
            $out | Should -Be 'Canadian (Apple)'
        }
    }
}

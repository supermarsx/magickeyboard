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
$translations = Join-Path $LayoutDir 'translations.json'
$gt = Join-Path $LayoutDir 'get_translation.ps1'

Describe 'get_translation.ps1 behavior' {
    BeforeAll {
        if (-not (Test-Path $gt)) { throw "get_translation.ps1 not found at $gt" }
        $translationsJson = Get-Content -Raw -Path $translations | ConvertFrom-Json
    }

    It 'returns the French translation for BelgiumA when asked explicitly' {
        $out = & $gt -Key 'BelgiumA' -File $translations -Locale 'fr-FR'
        $out | Should -Be 'Belge (Apple)'
    }

    It 'supports language-only locales (en -> en-US equivalent)' {
        $out = & $gt -Key 'BritishA' -File $translations -Locale 'en'
        $out | Should -Be 'British (Apple)'
    }

    It 'normalizes underscored locales (en_US -> en-US)' {
        $out = & $gt -Key 'CanadaA' -File $translations -Locale 'en_US'
        $out | Should -Be 'Canadian (Apple)'
    }

    It 'falls back to another available locale when given unknown locale' {
        $out = & $gt -Key 'GermanA' -File $translations -Locale 'xx-ZZ'
        # should not be empty; prefer 'en' fallback or another available translation
        $out | Should -Not -BeNullOrEmpty
    }
}

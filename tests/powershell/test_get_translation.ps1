param(
  [string] $LayoutDir = "$PSScriptRoot/../../All Keyboard Layouts (1.0.3.40)"
)

$layoutDir = Resolve-Path -Path $LayoutDir
$gt = Join-Path $layoutDir 'get_translation.ps1'
$translations = Join-Path $layoutDir 'translations.json'

if (-not (Test-Path $gt)) {
  Write-Error "get_translation.ps1 not found at $gt"
  exit 2
}

Write-Host "Running PowerShell translation helper tests against: $layoutDir"

function Assert-Equals($got, $expected, $label) {
  if ($got -ne $expected) {
    Write-Error "FAIL: $label -> got '$got' expected '$expected'"
    exit 1
  }
  Write-Host "OK: $label -> $got"
}

# exact locale
$out = & $gt -Key 'BelgiumA' -File $translations -Locale 'fr-FR'
Assert-Equals $out 'Belge (Apple)' 'BelgiumA fr-FR'

# language-only
$out = & $gt -Key 'BritishA' -File $translations -Locale 'en'
Assert-Equals $out 'British (Apple)' 'BritishA en'

# underscore normalization
$out = & $gt -Key 'CanadaA' -File $translations -Locale 'en_US'
Assert-Equals $out 'Canadian (Apple)' 'CanadaA en_US -> en-US normalization'

# fallback to en when unknown locale
$out = & $gt -Key 'GermanA' -File $translations -Locale 'xx-ZZ' 2>$null
if ($out -eq '') { $out = $null }
if ($out -eq $null) {
  Write-Error "FAIL: GermanA returned empty for unknown locale"
  exit 1
}

Write-Host "All PowerShell translation tests passed"

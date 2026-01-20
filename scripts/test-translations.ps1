<#
  test-translations.ps1

  Purpose:
    Windows-friendly translation validation without fragile cmd quoting.

  Checks:
    - For each layout key in layouts.json, translations.json contains REQUIRED_LOCALES.
    - Translation values are non-empty and not a placeholder equal to the key name.
#>

param(
  [string] $Root = (Join-Path $PSScriptRoot '..\All Keyboard Layouts (1.0.3.40)')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$layoutsPath = Join-Path $Root 'layouts.json'
$translationsPath = Join-Path $Root 'translations.json'

if (-not (Test-Path $layoutsPath)) { Write-Error "layouts.json missing at $layoutsPath"; exit 2 }
if (-not (Test-Path $translationsPath)) { Write-Error "translations.json missing at $translationsPath"; exit 2 }

$requiredLocales = @(
  'en','en-US','fr-FR','de-DE','es-ES','nl-NL','it-IT','pt-PT','pt-BR','ru-RU','zh-CN','zh-TW','pl-PL','sv-SE','fi-FI','nb-NO','cs-CZ','hu-HU','tr-TR','en-CA'
)

$matrix = Get-Content -Raw -Path $layoutsPath | ConvertFrom-Json
$trans = Get-Content -Raw -Path $translationsPath | ConvertFrom-Json

$missingKeys = 0
$missingLocales = 0
$emptyValues = 0
$placeholders = 0

foreach ($p in $matrix.PSObject.Properties) {
  $key = $p.Name
  if (-not ($trans.PSObject.Properties.Name -contains $key)) {
    Write-Host "ERROR: translations.json missing key $key"
    $missingKeys++
    continue
  }

  $entry = $trans.$key
  foreach ($loc in $requiredLocales) {
    if (-not ($entry.PSObject.Properties.Name -contains $loc)) {
      Write-Host "ERROR: translations.json missing locale $loc for key $key"
      $missingLocales++
      continue
    }

    $val = $entry.$loc
    if ([string]::IsNullOrWhiteSpace($val)) {
      Write-Host "ERROR: translations.json has empty translation for locale $loc in key $key"
      $emptyValues++
      continue
    }

    if ($val -eq $key) {
      Write-Host "ERROR: translations.json has placeholder (key name) for locale $loc in key $key"
      $placeholders++
      continue
    }
  }
}

if (($missingKeys + $missingLocales + $emptyValues + $placeholders) -gt 0) {
  Write-Host "[test-translations] FAILED"
  Write-Host "  Missing keys: $missingKeys"
  Write-Host "  Missing locales: $missingLocales"
  Write-Host "  Empty values: $emptyValues"
  Write-Host "  Placeholder values: $placeholders"
  exit 3
}

Write-Host "[test-translations] OK - translations resolve for all keys (no empty/placeholders)"
exit 0

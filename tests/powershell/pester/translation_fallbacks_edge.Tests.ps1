Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

Describe 'Translation fallback behavior' {
    BeforeAll {
        $starts = @()
        if ($PSCommandPath) { $starts += (Split-Path -Parent $PSCommandPath) }
        if ($PSScriptRoot) { $starts += $PSScriptRoot }
        if ($MyInvocation -and $MyInvocation.MyCommand.Path) { $starts += (Split-Path -Parent $MyInvocation.MyCommand.Path) }
        $starts += (Get-Location).Path
        if ($env:GITHUB_WORKSPACE) { $starts += $env:GITHUB_WORKSPACE }

        $RepoRoot = $null
        foreach ($s in $starts | Where-Object { $_ }) {
            try { $cur = (Resolve-Path -Path $s).Path } catch { continue }
            while ($true) {
                if (Test-Path (Join-Path $cur 'All Keyboard Layouts (1.0.3.40)')) { $RepoRoot = $cur; break }
                $parent = Split-Path -Parent $cur
                if ($parent -eq $cur) { break }
                $cur = $parent
            }
            if ($RepoRoot) { break }
        }
        if (-not $RepoRoot) { throw "Repository root not found from starts: $($starts -join ', ')" }

        $LayoutDir = Join-Path $RepoRoot 'All Keyboard Layouts (1.0.3.40)'
        $MagicKeyboard = Join-Path $LayoutDir 'MagicKeyboard.ps1'
        if (-not (Test-Path $MagicKeyboard)) { throw "MagicKeyboard.ps1 not found at $MagicKeyboard" }

        function Invoke-GetTranslation {
            param(
                [string]$Key,
                [string]$Locale,
                [string]$TranslationsFile
            )
            $args = @('-Action', 'GetTranslation', '-Key', $Key, '-NoLogo', '-Silent')
            if ($Locale) { $args += @('-Locale', $Locale) }
            if ($TranslationsFile) { $args += @('-TranslationsFile', $TranslationsFile) }
            $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $MagicKeyboard @args 2>&1
            [pscustomobject]@{
                ExitCode = $LASTEXITCODE
                Output   = ($out -join "`n").Trim()
            }
        }
    }

    It 'uses exact locale when available (fr-FR)' {
        $tmp = Join-Path $env:TEMP ("mk_trans_exact_{0}.json" -f [guid]::NewGuid().ToString('N'))
        try {
            @'
{
  "BelgiumA": {
    "en": "EN Name",
    "fr-FR": "FR Name"
  }
}
'@ | Set-Content -Path $tmp -NoNewline
            $r = Invoke-GetTranslation -Key 'BelgiumA' -Locale 'fr-FR' -TranslationsFile $tmp
            $r.ExitCode | Should -Be 0
            $r.Output | Should -Be 'FR Name'
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'falls back from regional locale to language locale (fr-CA -> fr)' {
        $tmp = Join-Path $env:TEMP ("mk_trans_lang_{0}.json" -f [guid]::NewGuid().ToString('N'))
        try {
            @'
{
  "BelgiumA": {
    "en": "EN Name",
    "fr": "FR Generic"
  }
}
'@ | Set-Content -Path $tmp -NoNewline
            $r = Invoke-GetTranslation -Key 'BelgiumA' -Locale 'fr-CA' -TranslationsFile $tmp
            $r.ExitCode | Should -Be 0
            $r.Output | Should -Be 'FR Generic'
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'falls back to en when locale and language are missing' {
        $tmp = Join-Path $env:TEMP ("mk_trans_en_{0}.json" -f [guid]::NewGuid().ToString('N'))
        try {
            @'
{
  "BelgiumA": {
    "en": "EN Fallback",
    "de-DE": "DE Name"
  }
}
'@ | Set-Content -Path $tmp -NoNewline
            $r = Invoke-GetTranslation -Key 'BelgiumA' -Locale 'pt-BR' -TranslationsFile $tmp
            $r.ExitCode | Should -Be 0
            $r.Output | Should -Be 'EN Fallback'
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'falls back to first available translation when en is missing' {
        $tmp = Join-Path $env:TEMP ("mk_trans_first_{0}.json" -f [guid]::NewGuid().ToString('N'))
        try {
            @'
{
  "BelgiumA": {
    "it-IT": "IT First",
    "de-DE": "DE Second"
  }
}
'@ | Set-Content -Path $tmp -NoNewline
            $r = Invoke-GetTranslation -Key 'BelgiumA' -Locale 'pt-PT' -TranslationsFile $tmp
            $r.ExitCode | Should -Be 0
            $r.Output | Should -Be 'IT First'
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'falls back to key when translation entry is missing for key' {
        $tmp = Join-Path $env:TEMP ("mk_trans_missing_key_{0}.json" -f [guid]::NewGuid().ToString('N'))
        try {
            @'
{
  "OtherKey": {
    "en": "Other Name"
  }
}
'@ | Set-Content -Path $tmp -NoNewline
            $r = Invoke-GetTranslation -Key 'BelgiumA' -Locale 'en-US' -TranslationsFile $tmp
            $r.ExitCode | Should -Be 0
            $r.Output | Should -Be 'BelgiumA'
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'normalizes underscore locale and still resolves exact match (pt_BR -> pt-BR)' {
        $tmp = Join-Path $env:TEMP ("mk_trans_norm_{0}.json" -f [guid]::NewGuid().ToString('N'))
        try {
            @'
{
  "BelgiumA": {
    "pt-BR": "PTBR Name",
    "en": "EN Name"
  }
}
'@ | Set-Content -Path $tmp -NoNewline
            $r = Invoke-GetTranslation -Key 'BelgiumA' -Locale 'pt_BR' -TranslationsFile $tmp
            $r.ExitCode | Should -Be 0
            $r.Output | Should -Be 'PTBR Name'
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
        }
    }
}

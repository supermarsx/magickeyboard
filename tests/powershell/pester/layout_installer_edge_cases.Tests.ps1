Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

Describe 'MagicKeyboard layout installer edge cases' {
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
        $PowerShellExe = (Get-Command powershell -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
        if (-not $PowerShellExe) {
            $PowerShellExe = (Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
        }
        if (-not $PowerShellExe) { throw 'No PowerShell executable found (powershell or pwsh).' }

        function Invoke-MagicKeyboardProcess {
            param(
                [string]$ScriptPath,
                [string[]]$Arguments
            )
            $out = & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1
            [pscustomobject]@{
                ExitCode = $LASTEXITCODE
                Output   = ($out -join "`n")
            }
        }
    }

    It 'shows help text and exits successfully' {
        $r = Invoke-MagicKeyboardProcess -ScriptPath $MagicKeyboard -Arguments @('-Action', 'Help', '-NoLogo', '-Silent')
        $r.ExitCode | Should -Be 0
        $r.Output | Should -Match 'USAGE:'
        $r.Output | Should -Match 'ACTIONS:'
    }

    It 'fails GetTranslation when -Key is missing' {
        $r = Invoke-MagicKeyboardProcess -ScriptPath $MagicKeyboard -Arguments @('-Action', 'GetTranslation', '-NoLogo', '-Silent')
        $r.ExitCode | Should -Be 1
        $r.Output | Should -Match '-Key parameter is required'
    }

    It 'uses default translations when custom TranslationsFile path does not exist' {
        $r = Invoke-MagicKeyboardProcess -ScriptPath $MagicKeyboard -Arguments @('-Action', 'GetTranslation', '-Key', 'BelgiumA', '-Locale', 'fr-FR', '-TranslationsFile', 'C:\__does_not_exist__.json', '-NoLogo', '-Silent')
        $r.ExitCode | Should -Be 0
        $r.Output.Trim() | Should -Be 'Belge (Apple)'
    }

    It 'uses custom translations file when provided' {
        $tmp = Join-Path $env:TEMP ("mk_custom_trans_{0}.json" -f [guid]::NewGuid().ToString('N'))
        try {
            @'
{
  "BelgiumA": {
    "en": "Belgium CUSTOM"
  }
}
'@ | Set-Content -Path $tmp -NoNewline
            $r = Invoke-MagicKeyboardProcess -ScriptPath $MagicKeyboard -Arguments @('-Action', 'GetTranslation', '-Key', 'BelgiumA', '-Locale', 'en-US', '-TranslationsFile', $tmp, '-NoLogo', '-Silent')
            $r.ExitCode | Should -Be 0
            $r.Output.Trim() | Should -Be 'Belgium CUSTOM'
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'returns key as fallback for unknown translation key' {
        $r = Invoke-MagicKeyboardProcess -ScriptPath $MagicKeyboard -Arguments @('-Action', 'GetTranslation', '-Key', 'UnknownLayoutKey', '-Locale', 'en-US', '-NoLogo', '-Silent')
        $r.ExitCode | Should -Be 0
        $r.Output.Trim() | Should -Be 'UnknownLayoutKey'
    }

    It 'install dry-run with one layout processes one registry entry' {
        $r = Invoke-MagicKeyboardProcess -ScriptPath $MagicKeyboard -Arguments @('-Action', 'Install', '-Layouts', 'BelgiumA', '-DryRun', '-NoLogo', '-Silent')
        $r.Output | Should -Match 'Registry entries:\s+1'
        $r.Output | Should -Match 'Files copied:\s+1'
    }

    It 'install dry-run with unknown layout filter processes zero entries' {
        $r = Invoke-MagicKeyboardProcess -ScriptPath $MagicKeyboard -Arguments @('-Action', 'Install', '-Layouts', 'NotARealLayout', '-DryRun', '-NoLogo', '-Silent')
        $r.Output | Should -Match 'Registry entries:\s+0'
        $r.Output | Should -Match 'Files copied:\s+0'
    }

    It 'reinstall dry-run runs both steps successfully' {
        $r = Invoke-MagicKeyboardProcess -ScriptPath $MagicKeyboard -Arguments @('-Action', 'Reinstall', '-Layouts', 'USA', '-DryRun', '-NoLogo', '-Silent')
        $r.ExitCode | Should -Be 0
        $r.Output | Should -Match 'Step 1: Removing existing layouts'
        $r.Output | Should -Match 'Step 2: Installing layouts'
    }

    It 'backup action writes a JSON file with entries' {
        $tmp = Join-Path $env:TEMP ("mk_backup_{0}.json" -f [guid]::NewGuid().ToString('N'))
        try {
            $r = Invoke-MagicKeyboardProcess -ScriptPath $MagicKeyboard -Arguments @('-Action', 'Backup', '-BackupPath', $tmp, '-NoLogo', '-Silent')
            $r.ExitCode | Should -Be 0
            Test-Path $tmp | Should -BeTrue
            $json = Get-Content -Raw -Encoding UTF8 -Path $tmp | ConvertFrom-Json
            $json.PSObject.Properties.Name | Should -Contain 'entries'
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'install dry-run fails when layouts.json is missing' {
        $tmpDir = Join-Path $env:TEMP ("mk_missing_matrix_{0}" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tmpDir | Out-Null
        $tmpScript = Join-Path $tmpDir 'MagicKeyboard.ps1'
        try {
            Copy-Item -Path $MagicKeyboard -Destination $tmpScript -Force
            Copy-Item -Path (Join-Path $LayoutDir 'translations.json') -Destination (Join-Path $tmpDir 'translations.json') -Force
            $r = Invoke-MagicKeyboardProcess -ScriptPath $tmpScript -Arguments @('-Action', 'Install', '-DryRun', '-NoLogo', '-Silent')
            $r.Output | Should -Match 'layouts.json not found'
            $r.Output | Should -Match 'Installation failed'
        }
        finally {
            if (Test-Path $tmpDir) { Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'install dry-run fails when custom translations JSON is malformed' {
        $tmp = Join-Path $env:TEMP ("mk_bad_trans_{0}.json" -f [guid]::NewGuid().ToString('N'))
        try {
            '{ "BelgiumA": { "en": "ok"  ' | Set-Content -Path $tmp -NoNewline
            $r = Invoke-MagicKeyboardProcess -ScriptPath $MagicKeyboard -Arguments @('-Action', 'Install', '-DryRun', '-TranslationsFile', $tmp, '-NoLogo', '-Silent')
            $r.Output | Should -Match 'Installation failed'
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
        }
    }
}

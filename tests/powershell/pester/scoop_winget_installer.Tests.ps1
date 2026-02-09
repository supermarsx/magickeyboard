Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

Describe 'Scoop/Winget installer flow' {
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
                if (Test-Path (Join-Path $cur 'bucket/magickeyboard.json')) { $RepoRoot = $cur; break }
                $parent = Split-Path -Parent $cur
                if ($parent -eq $cur) { break }
                $cur = $parent
            }
            if ($RepoRoot) { break }
        }
        if (-not $RepoRoot) { throw "Repository root not found from starts: $($starts -join ', ')" }

        $LayoutDir = Join-Path $RepoRoot 'All Keyboard Layouts (1.0.3.40)'
        $InstallerScript = Join-Path $LayoutDir 'ScoopWingetInstaller.ps1'
        $InstallWrapper = Join-Path $LayoutDir 'install_scoop_winget_elevated.bat'
        $UninstallWrapper = Join-Path $LayoutDir 'uninstall_scoop_winget_elevated.bat'
    }

    It 'manifest files reference the new Scoop/Winget wrappers' {
        $bucket = Get-Content -Raw -Path (Join-Path $RepoRoot 'bucket/magickeyboard.json')
        $winget = Get-Content -Raw -Path (Join-Path $RepoRoot 'winget/magickeyboard.yaml')

        $bucket | Should -Match 'install_scoop_winget_elevated\.bat'
        $bucket | Should -Match 'uninstall_scoop_winget_elevated\.bat'
        $winget | Should -Match "RelativeFilePath:\s*'install_scoop_winget_elevated\.bat'"
        $winget | Should -Match "RelativeFilePath:\s*'uninstall_scoop_winget_elevated\.bat'"
    }

    It 'installer scripts exist in layout package root' {
        Test-Path $InstallerScript | Should -BeTrue
        Test-Path $InstallWrapper | Should -BeTrue
        Test-Path $UninstallWrapper | Should -BeTrue
    }

    It 'install action runs both driver installers and layout installer in silent mode' {
        $tmp = Join-Path $env:TEMP ("mk_installtest_{0}" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tmp | Out-Null
        $log = Join-Path $tmp 'log.txt'
        $driver1 = Join-Path $tmp 'driver1.cmd'
        $driver2 = Join-Path $tmp 'driver2.cmd'
        $mockLayout = Join-Path $tmp 'MagicKeyboard.ps1'

        @"
@echo off
echo driver1 %*>>"$log"
exit /b 0
"@ | Set-Content -Path $driver1 -NoNewline
        @"
@echo off
echo driver2 %*>>"$log"
exit /b 0
"@ | Set-Content -Path $driver2 -NoNewline
        @'
param([string]$Action,[switch]$Quiet,[switch]$DryRun,[switch]$NoLogo)
"layout $Action quiet=$($Quiet.IsPresent) dryrun=$($DryRun.IsPresent)" | Out-File -FilePath "__LOG__" -Append -Encoding ascii
exit 0
'@.Replace('__LOG__', $log.Replace("'", "''")) | Set-Content -Path $mockLayout -NoNewline

        try {
            & $InstallerScript -Action Install -Silent -SkipElevation -Driver1Path $driver1 -Driver2Path $driver2 -LayoutsScriptPath $mockLayout
            $LASTEXITCODE | Should -Be 0
            $content = Get-Content -Raw -Path $log
            $content | Should -Match 'driver1 /S'
            $content | Should -Match 'driver2 /S'
            $content | Should -Match 'layout Install quiet=True dryrun=False'
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'install action fails when both driver installers fail' {
        $tmp = Join-Path $env:TEMP ("mk_installfail_{0}" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tmp | Out-Null
        $driver1 = Join-Path $tmp 'driver1.cmd'
        $driver2 = Join-Path $tmp 'driver2.cmd'
        $mockLayout = Join-Path $tmp 'MagicKeyboard.ps1'

        "@echo off`nexit /b 1" | Set-Content -Path $driver1 -NoNewline
        "@echo off`nexit /b 1" | Set-Content -Path $driver2 -NoNewline
        "exit 0" | Set-Content -Path $mockLayout -NoNewline

        try {
            { & $InstallerScript -Action Install -Silent -SkipElevation -Driver1Path $driver1 -Driver2Path $driver2 -LayoutsScriptPath $mockLayout } | Should -Throw
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'uninstall action calls layout uninstaller silently' {
        $tmp = Join-Path $env:TEMP ("mk_uninstalltest_{0}" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tmp | Out-Null
        $log = Join-Path $tmp 'log.txt'
        $mockLayout = Join-Path $tmp 'MagicKeyboard.ps1'
        @'
param([string]$Action,[switch]$Quiet,[switch]$DryRun,[switch]$NoLogo)
"layout $Action quiet=$($Quiet.IsPresent) dryrun=$($DryRun.IsPresent)" | Out-File -FilePath "__LOG__" -Append -Encoding ascii
exit 0
'@.Replace('__LOG__', $log.Replace("'", "''")) | Set-Content -Path $mockLayout -NoNewline
        try {
            & $InstallerScript -Action Uninstall -Silent -SkipElevation -LayoutsScriptPath $mockLayout
            $LASTEXITCODE | Should -Be 0
            (Get-Content -Raw -Path $log) | Should -Match 'layout Uninstall quiet=True dryrun=False'
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
}

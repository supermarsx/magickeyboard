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
        $InstallerScript = Join-Path $LayoutDir 'pkgmngr/ScoopWingetInstaller.ps1'
        $InstallWrapper = Join-Path $LayoutDir 'pkgmngr/install_scoop_winget_elevated.bat'
        $UninstallWrapper = Join-Path $LayoutDir 'pkgmngr/uninstall_scoop_winget_elevated.bat'

    }


    It 'manifest files reference the new Scoop/Winget wrappers' {
        $bucket = Get-Content -Raw -Path (Join-Path $RepoRoot 'bucket/magickeyboard.json')
        $winget = Get-Content -Raw -Path (Join-Path $RepoRoot 'winget/magickeyboard.yaml')

        $bucket | Should -Match 'install_scoop_winget_elevated\.bat'
        $bucket | Should -Match 'uninstall_scoop_winget_elevated\.bat'
        $winget | Should -Match "RelativeFilePath:\s*'pkgmngr/install_scoop_winget_elevated\.bat'"
        $winget | Should -Match "RelativeFilePath:\s*'pkgmngr/uninstall_scoop_winget_elevated\.bat'"
    }

    It 'installer scripts exist in layout package root' {
        Test-Path $InstallerScript | Should -BeTrue
        Test-Path $InstallWrapper | Should -BeTrue
        Test-Path $UninstallWrapper | Should -BeTrue
    }

    It 'wrapper scripts parse silent/dryrun/elevation flags' {
        $installText = Get-Content -Raw -Path $InstallWrapper
        $uninstallText = Get-Content -Raw -Path $UninstallWrapper

        $installText | Should -Match 'set "PSARGS=-Action Install"'
        $uninstallText | Should -Match 'set "PSARGS=-Action Uninstall"'

        foreach ($t in @($installText, $uninstallText)) {
            $t | Should -Match '/SILENT'
            $t | Should -Match '/DRYRUN'
            $t | Should -Match '/SKIP_ELEVATION'
            $t | Should -Match '-Silent'
            $t | Should -Match '-DryRun'
            $t | Should -Match '-SkipElevation'
            $t | Should -Match 'ScoopWingetInstaller\.ps1'
        }
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

    It 'install action proceeds when one driver fails but one succeeds' {
        $tmp = Join-Path $env:TEMP ("mk_installpartial_{0}" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tmp | Out-Null
        $log = Join-Path $tmp 'log.txt'
        $driver1 = Join-Path $tmp 'driver1.cmd'
        $driver2 = Join-Path $tmp 'driver2.cmd'
        $mockLayout = Join-Path $tmp 'MagicKeyboard.ps1'

        @"
@echo off
echo driver1 fail %*>>"$log"
exit /b 1
"@ | Set-Content -Path $driver1 -NoNewline
        @"
@echo off
echo driver2 ok %*>>"$log"
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
            $content | Should -Match 'driver1 fail /S'
            $content | Should -Match 'driver2 ok /S'
            $content | Should -Match 'layout Install quiet=True dryrun=False'
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'install dry-run does not execute drivers and passes dryrun to layouts' {
        $tmp = Join-Path $env:TEMP ("mk_installdryrun_{0}" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tmp | Out-Null
        $log = Join-Path $tmp 'log.txt'
        $driver1 = Join-Path $tmp 'driver1.cmd'
        $driver2 = Join-Path $tmp 'driver2.cmd'
        $mockLayout = Join-Path $tmp 'MagicKeyboard.ps1'

        @"
@echo off
echo driver1 executed>>"$log"
exit /b 0
"@ | Set-Content -Path $driver1 -NoNewline
        @"
@echo off
echo driver2 executed>>"$log"
exit /b 0
"@ | Set-Content -Path $driver2 -NoNewline
        @'
param([string]$Action,[switch]$Quiet,[switch]$DryRun,[switch]$NoLogo)
"layout $Action quiet=$($Quiet.IsPresent) dryrun=$($DryRun.IsPresent)" | Out-File -FilePath "__LOG__" -Append -Encoding ascii
exit 0
'@.Replace('__LOG__', $log.Replace("'", "''")) | Set-Content -Path $mockLayout -NoNewline

        try {
            & $InstallerScript -Action Install -DryRun -SkipElevation -Driver1Path $driver1 -Driver2Path $driver2 -LayoutsScriptPath $mockLayout
            $LASTEXITCODE | Should -Be 0
            $content = Get-Content -Raw -Path $log
            $content | Should -Not -Match 'driver1 executed'
            $content | Should -Not -Match 'driver2 executed'
            $content | Should -Match 'layout Install quiet=False dryrun=True'
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'install action can download driver installers from URLs and execute them' {
        $tmp = Join-Path $env:TEMP ("mk_installurl_{0}" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tmp | Out-Null
        $log = Join-Path $tmp 'log.txt'
        $mockLayout = Join-Path $tmp 'MagicKeyboard.ps1'

        $d1Content = "@echo off`necho driver1 url %*>>`"$log`"`nexit /b 0`n"
        $d2Content = "@echo off`necho driver2 url %*>>`"$log`"`nexit /b 0`n"
        @'
param([string]$Action,[switch]$Quiet,[switch]$DryRun,[switch]$NoLogo)
"layout $Action quiet=$($Quiet.IsPresent) dryrun=$($DryRun.IsPresent)" | Out-File -FilePath "__LOG__" -Append -Encoding ascii
exit 0
'@.Replace('__LOG__', $log.Replace("'", "''")) | Set-Content -Path $mockLayout -NoNewline

        $url1 = 'https://example.test/driver1.cmd'
        $url2 = 'https://example.test/driver2.cmd'
        $hadInvokeWebRequest = Test-Path function:\global:Invoke-WebRequest
        $oldInvokeWebRequest = if ($hadInvokeWebRequest) { (Get-Item function:\global:Invoke-WebRequest).ScriptBlock } else { $null }
        $global:MockDriverDownloads = @{
            'driver1.cmd' = $d1Content
            'driver2.cmd' = $d2Content
        }
        function global:Invoke-WebRequest {
            param([string]$Uri, [string]$OutFile)
            $leaf = Split-Path -Leaf $Uri
            if (-not $global:MockDriverDownloads.ContainsKey($leaf)) {
                throw "Unexpected download URL in test: $Uri"
            }
            Set-Content -Path $OutFile -Value $global:MockDriverDownloads[$leaf] -NoNewline -Encoding ASCII
        }
        try {
            & $InstallerScript -Action Install -Silent -SkipElevation -Driver1Url $url1 -Driver2Url $url2 -LayoutsScriptPath $mockLayout
            $LASTEXITCODE | Should -Be 0
            $content = Get-Content -Raw -Path $log
            $content | Should -Match 'driver1 url /S'
            $content | Should -Match 'driver2 url /S'
            $content | Should -Match 'layout Install quiet=True dryrun=False'
        }
        finally {
            Remove-Variable -Name MockDriverDownloads -Scope Global -ErrorAction SilentlyContinue
            if ($hadInvokeWebRequest) {
                Set-Item function:\global:Invoke-WebRequest -Value $oldInvokeWebRequest
            }
            else {
                Remove-Item function:\global:Invoke-WebRequest -ErrorAction SilentlyContinue
            }
            if (Test-Path $tmp) { Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'install action treats reboot-required driver exit codes as success' {
        $tmp = Join-Path $env:TEMP ("mk_installreboot_{0}" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tmp | Out-Null
        $log = Join-Path $tmp 'log.txt'
        $driver1 = Join-Path $tmp 'driver1.cmd'
        $driver2 = Join-Path $tmp 'driver2.cmd'
        $mockLayout = Join-Path $tmp 'MagicKeyboard.ps1'

        @"
@echo off
echo driver1 reboot %*>>"$log"
exit /b 3010
"@ | Set-Content -Path $driver1 -NoNewline
        @"
@echo off
echo driver2 reboot %*>>"$log"
exit /b 1641
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
            $content | Should -Match 'driver1 reboot /S'
            $content | Should -Match 'driver2 reboot /S'
            $content | Should -Match 'layout Install quiet=True dryrun=False'
        }
        finally {
            if (Test-Path $tmp) { Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'install action prefers local driver files from pkgmngr folder over URL download' {
        $tmp = Join-Path $env:TEMP ("mk_installlocal_{0}" -f [guid]::NewGuid().ToString('N'))
        $pkgmngrDir = Join-Path $tmp 'pkgmngr'
        New-Item -ItemType Directory -Path $pkgmngrDir -Force | Out-Null

        $scriptCopy = Join-Path $pkgmngrDir 'ScoopWingetInstaller.ps1'
        Copy-Item -LiteralPath $InstallerScript -Destination $scriptCopy -Force

        $log = Join-Path $tmp 'log.txt'
        $localDriver1Name = 'localdriver1.cmd'
        $localDriver2Name = 'localdriver2.cmd'
        $localDriver1Path = Join-Path $pkgmngrDir $localDriver1Name
        $localDriver2Path = Join-Path $pkgmngrDir $localDriver2Name
        $mockLayout = Join-Path $tmp 'MagicKeyboard.ps1'

        @"
@echo off
echo local1 %*>>"$log"
exit /b 0
"@ | Set-Content -Path $localDriver1Path -NoNewline
        @"
@echo off
echo local2 %*>>"$log"
exit /b 0
"@ | Set-Content -Path $localDriver2Path -NoNewline
        @'
param([string]$Action,[switch]$Quiet,[switch]$DryRun,[switch]$NoLogo)
"layout $Action quiet=$($Quiet.IsPresent) dryrun=$($DryRun.IsPresent)" | Out-File -FilePath "__LOG__" -Append -Encoding ascii
exit 0
'@.Replace('__LOG__', $log.Replace("'", "''")) | Set-Content -Path $mockLayout -NoNewline

        $url1 = "http://127.0.0.1:9/$localDriver1Name"
        $url2 = "http://127.0.0.1:9/$localDriver2Name"
        try {
            & $scriptCopy -Action Install -Silent -SkipElevation -Driver1Url $url1 -Driver2Url $url2 -LayoutsScriptPath $mockLayout
            $LASTEXITCODE | Should -Be 0
            $content = Get-Content -Raw -Path $log
            $content | Should -Match 'local1 /S'
            $content | Should -Match 'local2 /S'
            $content | Should -Match 'layout Install quiet=True dryrun=False'
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


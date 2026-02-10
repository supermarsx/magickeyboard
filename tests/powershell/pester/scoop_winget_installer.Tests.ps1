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

        function Start-OneShotHttpTextServer {
            param(
                [string]$RouteFileName,
                [string]$Content
            )

            $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
            $listener.Start()
            $port = ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
            $listener.Stop()

            $job = Start-Job -ScriptBlock {
                param($p, $route, $body)
                $listener = [System.Net.HttpListener]::new()
                $listener.Prefixes.Add("http://127.0.0.1:$p/")
                $listener.Start()
                try {
                    $ctx = $listener.GetContext()
                    $path = $ctx.Request.Url.AbsolutePath.TrimStart('/')
                    if ($path -eq $route) {
                        $bytes = [Text.Encoding]::ASCII.GetBytes($body)
                        $ctx.Response.StatusCode = 200
                        $ctx.Response.ContentType = 'application/octet-stream'
                        $ctx.Response.ContentLength64 = $bytes.Length
                        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
                    }
                    else {
                        $ctx.Response.StatusCode = 404
                    }
                    $ctx.Response.OutputStream.Close()
                }
                finally {
                    if ($listener.IsListening) { $listener.Stop() }
                    $listener.Close()
                }
            } -ArgumentList $port, $RouteFileName, $Content

            return [pscustomobject]@{
                Port = $port
                Job  = $job
            }
        }
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
        $srv1 = Start-OneShotHttpTextServer -RouteFileName 'driver1.cmd' -Content $d1Content
        $srv2 = Start-OneShotHttpTextServer -RouteFileName 'driver2.cmd' -Content $d2Content
        @'
param([string]$Action,[switch]$Quiet,[switch]$DryRun,[switch]$NoLogo)
"layout $Action quiet=$($Quiet.IsPresent) dryrun=$($DryRun.IsPresent)" | Out-File -FilePath "__LOG__" -Append -Encoding ascii
exit 0
'@.Replace('__LOG__', $log.Replace("'", "''")) | Set-Content -Path $mockLayout -NoNewline

        $url1 = "http://127.0.0.1:$($srv1.Port)/driver1.cmd"
        $url2 = "http://127.0.0.1:$($srv2.Port)/driver2.cmd"
        try {
            & $InstallerScript -Action Install -Silent -SkipElevation -Driver1Url $url1 -Driver2Url $url2 -LayoutsScriptPath $mockLayout
            $LASTEXITCODE | Should -Be 0
            $content = Get-Content -Raw -Path $log
            $content | Should -Match 'driver1 url /S'
            $content | Should -Match 'driver2 url /S'
            $content | Should -Match 'layout Install quiet=True dryrun=False'
        }
        finally {
            if ($srv1 -and $srv1.Job) { Wait-Job -Job $srv1.Job -Timeout 10 | Out-Null; Remove-Job -Job $srv1.Job -Force -ErrorAction SilentlyContinue }
            if ($srv2 -and $srv2.Job) { Wait-Job -Job $srv2.Job -Timeout 10 | Out-Null; Remove-Job -Job $srv2.Job -Force -ErrorAction SilentlyContinue }
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

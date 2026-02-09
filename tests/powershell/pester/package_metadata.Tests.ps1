Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

Describe 'Package metadata scripts' {
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
                if (Test-Path (Join-Path $cur 'scripts/verify-package-metadata.ps1')) { $RepoRoot = $cur; break }
                $parent = Split-Path -Parent $cur
                if ($parent -eq $cur) { break }
                $cur = $parent
            }
            if ($RepoRoot) { break }
        }
        if (-not $RepoRoot) { throw "Repository root containing scripts/verify-package-metadata.ps1 not found from starts: $($starts -join ', ')" }

        $VerifyScript = Join-Path $RepoRoot 'scripts/verify-package-metadata.ps1'
        $SyncScript = Join-Path $RepoRoot 'scripts/sync-package-hashes.ps1'

        $GetSha256Hex = {
            param([string]$Path)
            $stream = [System.IO.File]::OpenRead($Path)
            try {
                $sha = [System.Security.Cryptography.SHA256]::Create()
                try {
                    $hashBytes = $sha.ComputeHash($stream)
                }
                finally {
                    $sha.Dispose()
                }
            }
            finally {
                $stream.Dispose()
            }
            return (-join ($hashBytes | ForEach-Object { $_.ToString('x2') })).ToUpperInvariant()
        }

        $NewTempRepoFixture = {
            param(
                [string]$Url,
                [string]$Version = '1.2.3',
                [string]$BucketHash = ('0' * 64),
                [string]$WingetHash1 = ('0' * 64),
                [string]$WingetHash2 = ('0' * 64)
            )

            $root = Join-Path ([IO.Path]::GetTempPath()) ("mk_meta_{0}" -f [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $root | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root 'bucket') | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root 'winget') | Out-Null

            $bucket = @"
{
  "version": "$Version",
  "description": "test",
  "homepage": "https://example.test",
  "license": "MIT",
  "url": "$Url",
  "hash": "$BucketHash"
}
"@
            Set-Content -LiteralPath (Join-Path $root 'bucket/magickeyboard.json') -Value $bucket -NoNewline

            $winget = @"
PackageIdentifier: supermarsx.magickeyboard
PackageVersion: $Version
InstallerUrl: $Url
InstallerSha256: $WingetHash1
Uninstallers:
  - InstallerUrl: $Url
    InstallerSha256: $WingetHash2
"@
            Set-Content -LiteralPath (Join-Path $root 'winget/magickeyboard.yaml') -Value $winget -NoNewline

            return $root
        }

        $StartOneShotHttpFileServer = {
            param(
                [string]$FilePath,
                [string]$RouteFileName
            )

            $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
            $listener.Start()
            $port = ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
            $listener.Stop()

            $job = Start-Job -ScriptBlock {
                param($p, $file, $routeFile)
                $listener = [System.Net.HttpListener]::new()
                $listener.Prefixes.Add("http://127.0.0.1:$p/")
                $listener.Start()
                try {
                    $ctx = $listener.GetContext()
                    $path = $ctx.Request.Url.AbsolutePath.TrimStart('/')
                    if ($path -eq $routeFile) {
                        $bytes = [IO.File]::ReadAllBytes($file)
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
            } -ArgumentList $port, $FilePath, $RouteFileName

            return [pscustomobject]@{
                Port = $port
                Job  = $job
            }
        }
    }

    It 'sync script updates bucket and winget hashes from artifact' {
        $route = 'All.Keyboard.Layouts.1.2.3.zip'
        $artifact = Join-Path ([IO.Path]::GetTempPath()) ("mk_artifact_{0}.zip" -f [guid]::NewGuid().ToString('N'))
        Set-Content -LiteralPath $artifact -Value 'sync-hash-test-data' -NoNewline
        $server = & $StartOneShotHttpFileServer -FilePath $artifact -RouteFileName $route
        $url = "http://127.0.0.1:$($server.Port)/$route"
        $repo = & $NewTempRepoFixture -Url $url -Version '1.2.3' -BucketHash ('0' * 64) -WingetHash1 ('1' * 64) -WingetHash2 ('2' * 64)
        try {
            & $SyncScript -RepoRoot $repo

            $expected = & $GetSha256Hex -Path $artifact
            $bucket = Get-Content -LiteralPath (Join-Path $repo 'bucket/magickeyboard.json') -Raw | ConvertFrom-Json
            $winget = Get-Content -LiteralPath (Join-Path $repo 'winget/magickeyboard.yaml') -Raw

            $bucket.hash.ToUpperInvariant() | Should -Be $expected
            ([regex]::Matches($winget, '(?m)^\s*InstallerSha256\s*:\s*([A-Fa-f0-9]{64})\s*$').Count) | Should -Be 2
            foreach ($m in [regex]::Matches($winget, '(?m)^\s*InstallerSha256\s*:\s*([A-Fa-f0-9]{64})\s*$')) {
                $m.Groups[1].Value.ToUpperInvariant() | Should -Be $expected
            }
        }
        finally {
            if ($server -and $server.Job) { Wait-Job -Job $server.Job -Timeout 10 | Out-Null; Remove-Job -Job $server.Job -Force -ErrorAction SilentlyContinue }
            if (Test-Path -LiteralPath $artifact) { Remove-Item -LiteralPath $artifact -Force -ErrorAction SilentlyContinue }
            if (Test-Path -LiteralPath $repo) { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'verify script passes when manifests and remote artifact hash match' {
        $route = 'All.Keyboard.Layouts.1.2.3.zip'
        $artifact = Join-Path ([IO.Path]::GetTempPath()) ("mk_artifact_{0}.zip" -f [guid]::NewGuid().ToString('N'))
        Set-Content -LiteralPath $artifact -Value 'verify-pass-data' -NoNewline
        $server = & $StartOneShotHttpFileServer -FilePath $artifact -RouteFileName $route
        $url = "http://127.0.0.1:$($server.Port)/$route"
        $hash = & $GetSha256Hex -Path $artifact
        $repo = & $NewTempRepoFixture -Url $url -Version '1.2.3' -BucketHash $hash -WingetHash1 $hash -WingetHash2 $hash
        try {
            { & $VerifyScript -RepoRoot $repo } | Should -Not -Throw
        }
        finally {
            if ($server -and $server.Job) { Wait-Job -Job $server.Job -Timeout 10 | Out-Null; Remove-Job -Job $server.Job -Force -ErrorAction SilentlyContinue }
            if (Test-Path -LiteralPath $artifact) { Remove-Item -LiteralPath $artifact -Force -ErrorAction SilentlyContinue }
            if (Test-Path -LiteralPath $repo) { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'verify script fails when winget hash differs from bucket hash' {
        $url = 'https://example.test/All.Keyboard.Layouts.1.2.3.zip'
        $repo = & $NewTempRepoFixture -Url $url -Version '1.2.3' -BucketHash ('A' * 64) -WingetHash1 ('B' * 64) -WingetHash2 ('A' * 64)
        try {
            { & $VerifyScript -RepoRoot $repo } | Should -Throw -ExpectedMessage '*Hash mismatch between bucket and winget manifests*'
        }
        finally {
            if (Test-Path -LiteralPath $repo) { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'verify script fails when remote artifact hash differs from expected' {
        $route = 'All.Keyboard.Layouts.1.2.3.zip'
        $artifact = Join-Path ([IO.Path]::GetTempPath()) ("mk_artifact_{0}.zip" -f [guid]::NewGuid().ToString('N'))
        Set-Content -LiteralPath $artifact -Value 'verify-mismatch-data' -NoNewline
        $server = & $StartOneShotHttpFileServer -FilePath $artifact -RouteFileName $route
        $url = "http://127.0.0.1:$($server.Port)/$route"
        $wrongHash = ('C' * 64)
        $repo = & $NewTempRepoFixture -Url $url -Version '1.2.3' -BucketHash $wrongHash -WingetHash1 $wrongHash -WingetHash2 $wrongHash
        try {
            { & $VerifyScript -RepoRoot $repo } | Should -Throw -ExpectedMessage '*Remote artifact hash mismatch*'
        }
        finally {
            if ($server -and $server.Job) { Wait-Job -Job $server.Job -Timeout 10 | Out-Null; Remove-Job -Job $server.Job -Force -ErrorAction SilentlyContinue }
            if (Test-Path -LiteralPath $artifact) { Remove-Item -LiteralPath $artifact -Force -ErrorAction SilentlyContinue }
            if (Test-Path -LiteralPath $repo) { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
}

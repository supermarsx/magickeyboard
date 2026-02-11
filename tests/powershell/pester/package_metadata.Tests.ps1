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
        $SyncFromArtifactScript = Join-Path $RepoRoot 'scripts/sync-package-hashes-from-artifact.ps1'

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
    }

    It 'sync script updates bucket and winget hashes from artifact' {
        $artifact = Join-Path ([IO.Path]::GetTempPath()) ("mk_artifact_{0}.zip" -f [guid]::NewGuid().ToString('N'))
        Set-Content -LiteralPath $artifact -Value 'sync-hash-test-data' -NoNewline
        $url = 'https://example.test/All.Keyboard.Layouts.1.2.3.zip'
        $repo = & $NewTempRepoFixture -Url $url -Version '1.2.3' -BucketHash ('0' * 64) -WingetHash1 ('1' * 64) -WingetHash2 ('2' * 64)
        $hadInvokeWebRequest = Test-Path function:\global:Invoke-WebRequest
        $oldInvokeWebRequest = if ($hadInvokeWebRequest) { (Get-Item function:\global:Invoke-WebRequest).ScriptBlock } else { $null }
        $global:MockArtifactPath = $artifact
        function global:Invoke-WebRequest {
            param([string]$Uri, [string]$OutFile)
            Copy-Item -LiteralPath $global:MockArtifactPath -Destination $OutFile -Force
        }
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
            Remove-Variable -Name MockArtifactPath -Scope Global -ErrorAction SilentlyContinue
            if ($hadInvokeWebRequest) {
                Set-Item function:\global:Invoke-WebRequest -Value $oldInvokeWebRequest
            }
            else {
                Remove-Item function:\global:Invoke-WebRequest -ErrorAction SilentlyContinue
            }
            if (Test-Path -LiteralPath $artifact) { Remove-Item -LiteralPath $artifact -Force -ErrorAction SilentlyContinue }
            if (Test-Path -LiteralPath $repo) { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'verify script passes when manifests and remote artifact hash match' {
        $artifact = Join-Path ([IO.Path]::GetTempPath()) ("mk_artifact_{0}.zip" -f [guid]::NewGuid().ToString('N'))
        Set-Content -LiteralPath $artifact -Value 'verify-pass-data' -NoNewline
        $url = 'https://example.test/All.Keyboard.Layouts.1.2.3.zip'
        $hash = & $GetSha256Hex -Path $artifact
        $repo = & $NewTempRepoFixture -Url $url -Version '1.2.3' -BucketHash $hash -WingetHash1 $hash -WingetHash2 $hash
        $hadInvokeWebRequest = Test-Path function:\global:Invoke-WebRequest
        $oldInvokeWebRequest = if ($hadInvokeWebRequest) { (Get-Item function:\global:Invoke-WebRequest).ScriptBlock } else { $null }
        $global:MockArtifactPath = $artifact
        function global:Invoke-WebRequest {
            param([string]$Uri, [string]$OutFile)
            Copy-Item -LiteralPath $global:MockArtifactPath -Destination $OutFile -Force
        }
        try {
            { & $VerifyScript -RepoRoot $repo } | Should -Not -Throw
        }
        finally {
            Remove-Variable -Name MockArtifactPath -Scope Global -ErrorAction SilentlyContinue
            if ($hadInvokeWebRequest) {
                Set-Item function:\global:Invoke-WebRequest -Value $oldInvokeWebRequest
            }
            else {
                Remove-Item function:\global:Invoke-WebRequest -ErrorAction SilentlyContinue
            }
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
        $artifact = Join-Path ([IO.Path]::GetTempPath()) ("mk_artifact_{0}.zip" -f [guid]::NewGuid().ToString('N'))
        Set-Content -LiteralPath $artifact -Value 'verify-mismatch-data' -NoNewline
        $url = 'https://example.test/All.Keyboard.Layouts.1.2.3.zip'
        $wrongHash = ('C' * 64)
        $repo = & $NewTempRepoFixture -Url $url -Version '1.2.3' -BucketHash $wrongHash -WingetHash1 $wrongHash -WingetHash2 $wrongHash
        $hadInvokeWebRequest = Test-Path function:\global:Invoke-WebRequest
        $oldInvokeWebRequest = if ($hadInvokeWebRequest) { (Get-Item function:\global:Invoke-WebRequest).ScriptBlock } else { $null }
        $global:MockArtifactPath = $artifact
        function global:Invoke-WebRequest {
            param([string]$Uri, [string]$OutFile)
            Copy-Item -LiteralPath $global:MockArtifactPath -Destination $OutFile -Force
        }
        try {
            { & $VerifyScript -RepoRoot $repo } | Should -Throw -ExpectedMessage '*Remote artifact hash mismatch*'
        }
        finally {
            Remove-Variable -Name MockArtifactPath -Scope Global -ErrorAction SilentlyContinue
            if ($hadInvokeWebRequest) {
                Set-Item function:\global:Invoke-WebRequest -Value $oldInvokeWebRequest
            }
            else {
                Remove-Item function:\global:Invoke-WebRequest -ErrorAction SilentlyContinue
            }
            if (Test-Path -LiteralPath $artifact) { Remove-Item -LiteralPath $artifact -Force -ErrorAction SilentlyContinue }
            if (Test-Path -LiteralPath $repo) { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'verify script fails when winget version differs from bucket version' {
        $url = 'https://example.test/All.Keyboard.Layouts.1.2.3.zip'
        $repo = & $NewTempRepoFixture -Url $url -Version '1.2.3' -BucketHash ('A' * 64) -WingetHash1 ('A' * 64) -WingetHash2 ('A' * 64)
        try {
            $wingetPath = Join-Path $repo 'winget/magickeyboard.yaml'
            $winget = (Get-Content -LiteralPath $wingetPath -Raw) -replace '(?m)^PackageVersion:\s*1\.2\.3\s*$', 'PackageVersion: 1.2.4'
            Set-Content -LiteralPath $wingetPath -Value $winget -NoNewline
            { & $VerifyScript -RepoRoot $repo } | Should -Throw -ExpectedMessage '*Version mismatch*'
        }
        finally {
            if (Test-Path -LiteralPath $repo) { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'verify script fails when bucket hash is not valid SHA256' {
        $url = 'https://example.test/All.Keyboard.Layouts.1.2.3.zip'
        $repo = & $NewTempRepoFixture -Url $url -Version '1.2.3' -BucketHash 'not-a-real-hash'
        try {
            { & $VerifyScript -RepoRoot $repo } | Should -Throw -ExpectedMessage '*not a valid SHA256*'
        }
        finally {
            if (Test-Path -LiteralPath $repo) { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'sync-from-artifact script updates bucket and winget hashes from local dist zip' {
        $repo = & $NewTempRepoFixture -Url 'https://example.test/All.Keyboard.Layouts.1.2.3.zip' -Version '1.2.3' -BucketHash ('0' * 64) -WingetHash1 ('1' * 64) -WingetHash2 ('2' * 64)
        $dist = Join-Path $repo 'dist'
        $artifact = Join-Path $dist 'All.Keyboard.Layouts.1.2.3.zip'
        New-Item -ItemType Directory -Path $dist | Out-Null
        Set-Content -LiteralPath $artifact -Value 'sync-local-artifact-data' -NoNewline
        try {
            & $SyncFromArtifactScript -RepoRoot $repo
            $expected = & $GetSha256Hex -Path $artifact
            $bucket = Get-Content -LiteralPath (Join-Path $repo 'bucket/magickeyboard.json') -Raw | ConvertFrom-Json
            $winget = Get-Content -LiteralPath (Join-Path $repo 'winget/magickeyboard.yaml') -Raw
            $bucket.hash.ToUpperInvariant() | Should -Be $expected
            foreach ($m in [regex]::Matches($winget, '(?m)^\s*InstallerSha256\s*:\s*([A-Fa-f0-9]{64})\s*$')) {
                $m.Groups[1].Value.ToUpperInvariant() | Should -Be $expected
            }
        }
        finally {
            if (Test-Path -LiteralPath $repo) { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
}

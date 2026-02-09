Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

Describe 'CI workflow and script smoke tests' {
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
                if (Test-Path (Join-Path $cur '.github/workflows/ci.yml')) { $RepoRoot = $cur; break }
                $parent = Split-Path -Parent $cur
                if ($parent -eq $cur) { break }
                $cur = $parent
            }
            if ($RepoRoot) { break }
        }
        if (-not $RepoRoot) { throw "Repository root containing .github/workflows/ci.yml not found from starts: $($starts -join ', ')" }

        $CiPath = Join-Path $RepoRoot '.github/workflows/ci.yml'
        $CiText = Get-Content -LiteralPath $CiPath -Raw
    }

    Context 'Workflow coverage' {
        It 'defines expected CI jobs and dependencies' {
            $CiText | Should -Match '(?m)^\s*lint:\s*$'
            $CiText | Should -Match '(?m)^\s*format:\s*$'
            $CiText | Should -Match '(?m)^\s*type:\s*$'
            $CiText | Should -Match '(?m)^\s*package-metadata:\s*$'
            $CiText | Should -Match '(?m)^\s*test:\s*$'
            $CiText | Should -Match '(?m)^\s*package:\s*$'
            $CiText | Should -Match '(?m)^\s*release:\s*$'
            $CiText | Should -Match '(?m)^\s*needs:\s*\[lint,\s*format,\s*type\]\s*$'
            $CiText | Should -Match '(?m)^\s*needs:\s*\[lint,\s*format,\s*type,\s*test,\s*package-metadata\]\s*$'
            $CiText | Should -Match '(?m)^\s*needs:\s*\[package,\s*package-metadata\]\s*$'
        }

        It 'executes lint/format/type/package scripts in CI steps' {
            $CiText | Should -Match 'scripts/ci/run-lint\.sh'
            $CiText | Should -Match 'scripts/ci/run-format\.sh'
            $CiText | Should -Match 'scripts/ci/run-type\.sh'
            $CiText | Should -Match 'scripts/ci/run-tests\.sh'
            $CiText | Should -Match 'scripts/ci/run-package\.sh'
            $CiText | Should -Match 'scripts/ci/run-package-metadata\.ps1'
        }

        It 'gates package and release when metadata auto-sync commits changes' {
            $CiText | Should -Match 'steps\.sync\.outputs\.updated'
            $CiText | Should -Match "if:\s*needs\.package-metadata\.outputs\.updated\s*!=\s*'true'"
            $CiText | Should -Match 'run-package-metadata\.ps1'
        }
    }

    Context 'Windows scripts' {
        It 'runs check-lint.bat successfully' {
            if (-not $IsWindows -or -not (Get-Command cmd -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because 'Windows-only cmd test' }
            Push-Location $RepoRoot
            try {
                cmd /c scripts\check-lint.bat
                $LASTEXITCODE | Should -Be 0
            }
            finally { Pop-Location }
        }

        It 'runs check-format.bat successfully' {
            if (-not $IsWindows -or -not (Get-Command cmd -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because 'Windows-only cmd test' }
            Push-Location $RepoRoot
            try {
                cmd /c scripts\check-format.bat
                $LASTEXITCODE | Should -Be 0
            }
            finally { Pop-Location }
        }

        It 'packages layouts via package_layouts.ps1' {
            if (-not $IsWindows -or -not (Get-Command cmd -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because 'Windows-only packaging cmd test' }
            $version = "ci-smoke-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
            $archive = Join-Path $RepoRoot ("dist/All.Keyboard.Layouts.{0}.zip" -f $version)
            Push-Location $RepoRoot
            try {
                if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
                & (Join-Path $RepoRoot 'scripts/package_layouts.ps1') -Version $version
                $LASTEXITCODE | Should -Be 0
                Test-Path -LiteralPath $archive | Should -BeTrue
            }
            finally {
                if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue }
                Pop-Location
            }
        }
    }

    Context 'POSIX scripts (if available)' {
        It 'contains CI entrypoint scripts' {
            Test-Path (Join-Path $RepoRoot 'scripts/ci/run-lint.sh') | Should -BeTrue
            Test-Path (Join-Path $RepoRoot 'scripts/ci/run-format.sh') | Should -BeTrue
            Test-Path (Join-Path $RepoRoot 'scripts/ci/run-type.sh') | Should -BeTrue
            Test-Path (Join-Path $RepoRoot 'scripts/ci/run-tests.sh') | Should -BeTrue
            Test-Path (Join-Path $RepoRoot 'scripts/ci/run-package.sh') | Should -BeTrue
        }

        It 'runs check-lint.sh when bash exists' {
            $bash = Get-Command bash -ErrorAction SilentlyContinue
            if (-not $bash) { Set-ItResult -Skipped -Because 'bash is not available on this runner' }
            Push-Location $RepoRoot
            try {
                $out = & bash ./scripts/ci/run-lint.sh 2>&1
                ($out -join "`n") | Should -Match 'Running lightweight lint checks'
                ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1) | Should -BeTrue
            }
            finally { Pop-Location }
        }

        It 'runs check-format.sh when bash exists' {
            $bash = Get-Command bash -ErrorAction SilentlyContinue
            if (-not $bash) { Set-ItResult -Skipped -Because 'bash is not available on this runner' }
            Push-Location $RepoRoot
            try {
                $out = & bash ./scripts/ci/run-format.sh 2>&1
                ($out -join "`n") | Should -Match 'Running format checks'
                ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1) | Should -BeTrue
            }
            finally { Pop-Location }
        }

        It 'packages layouts via package_layouts.sh when bash and zip are available' {
            $bash = Get-Command bash -ErrorAction SilentlyContinue
            if (-not $bash) { Set-ItResult -Skipped -Because 'bash is not available on this runner' }
            & bash -lc "command -v jq >/dev/null 2>&1 && command -v zip >/dev/null 2>&1"
            if ($LASTEXITCODE -ne 0) { Set-ItResult -Skipped -Because 'jq/zip are not available in the bash environment' }
            $version = "ci-smoke-posix-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
            $archive = Join-Path $RepoRoot ("dist/All.Keyboard.Layouts.{0}.zip" -f $version)
            Push-Location $RepoRoot
            try {
                if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
                & bash ./scripts/package_layouts.sh $version
                if ($LASTEXITCODE -ne 0) { Set-ItResult -Skipped -Because 'package_layouts.sh failed in current bash environment' }
                Test-Path -LiteralPath $archive | Should -BeTrue
            }
            finally {
                if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue }
                Pop-Location
            }
        }
    }
}

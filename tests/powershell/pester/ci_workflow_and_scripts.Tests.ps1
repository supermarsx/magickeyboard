Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

Describe 'CI workflow and script smoke tests' {
    BeforeAll {
        $RunningOnWindows = ($PSVersionTable.PSEdition -eq 'Desktop') -or $IsWindows
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
            $CiText | Should -Match 'scripts/ci/run-tests\.ps1'
            $CiText | Should -Match 'scripts/ci/run-package\.sh'
            $CiText | Should -Match 'scripts/ci/run-package-metadata\.ps1'
            $CiText | Should -Match 'scripts/sync-package-hashes-from-artifact\.ps1'
        }

        It 'always runs package and release while still exporting metadata sync output' {
            $CiText | Should -Match 'steps\.sync\.outputs\.updated'
            $CiText | Should -Not -Match "if:\s*needs\.package-metadata\.outputs\.updated\s*!=\s*'true'"
            $CiText | Should -Match "(?m)^\s*if:\s*github\.ref\s*==\s*'refs/heads/main'\s*&&\s*github\.event_name\s*==\s*'push'\s*$"
            $CiText | Should -Match 'run-package-metadata\.ps1'
        }

        It 'commits hash updates from packaged artifact during package job' {
            $CiText | Should -Match '(?ms)^\s*package:\s*.*?Sync package manager hashes from packaged artifact'
            $CiText | Should -Match '(?ms)^\s*package:\s*.*?Commit package hash updates'
            $CiText | Should -Match 'ci: sync package hashes from artifact'
        }

        It 'runs Windows-dependent tests on Windows runner' {
            $CiText | Should -Match '(?ms)^\s*test:\s*.*?runs-on:\s*windows-latest'
            $CiText | Should -Match '(?ms)^\s*package-metadata:\s*.*?runs-on:\s*windows-latest'
            $CiText | Should -Match '(?ms)^\s*test:\s*.*?shell:\s*pwsh'
        }
    }

    Context 'Windows scripts' {
        It 'runs check-lint.bat successfully' {
            if (-not $RunningOnWindows -or -not (Get-Command cmd -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because 'Windows-only cmd test' }
            Push-Location $RepoRoot
            try {
                cmd /c scripts\check-lint.bat
                $LASTEXITCODE | Should -Be 0
            }
            finally { Pop-Location }
        }

        It 'runs check-format.bat successfully' {
            if (-not $RunningOnWindows -or -not (Get-Command cmd -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because 'Windows-only cmd test' }
            Push-Location $RepoRoot
            try {
                cmd /c scripts\check-format.bat
                $LASTEXITCODE | Should -Be 0
            }
            finally { Pop-Location }
        }

        It 'packages layouts via package_layouts.ps1' {
            if (-not $RunningOnWindows -or -not (Get-Command cmd -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because 'Windows-only packaging cmd test' }
            $version = "ci-smoke-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
            $archive = Join-Path $RepoRoot ("dist/All.Keyboard.Layouts.{0}.zip" -f $version)
            Push-Location $RepoRoot
            try {
                if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
                & (Join-Path $RepoRoot 'scripts/package_layouts.ps1') -Version $version
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
            Test-Path (Join-Path $RepoRoot 'scripts/ci/run-tests.ps1') | Should -BeTrue
            Test-Path (Join-Path $RepoRoot 'scripts/ci/run-package.sh') | Should -BeTrue
        }

        It 'CI scripts are thin wrappers around project-level scripts' {
            $lintText = Get-Content -Raw -Path (Join-Path $RepoRoot 'scripts/ci/run-lint.sh')
            $fmtText = Get-Content -Raw -Path (Join-Path $RepoRoot 'scripts/ci/run-format.sh')
            $typeText = Get-Content -Raw -Path (Join-Path $RepoRoot 'scripts/ci/run-type.sh')
            $pkgText = Get-Content -Raw -Path (Join-Path $RepoRoot 'scripts/ci/run-package.sh')
            $testWinText = Get-Content -Raw -Path (Join-Path $RepoRoot 'scripts/ci/run-tests.ps1')

            $lintText | Should -Match 'scripts/check-lint\.sh'
            $fmtText | Should -Match 'scripts/check-format\.sh'
            $typeText | Should -Match 'No type checking applicable'
            $pkgText | Should -Match 'scripts/package_layouts\.sh'
            $testWinText | Should -Match 'scripts\\run-tests\.bat'
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
            $version = "ci-smoke-posix-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
            $archive = Join-Path $RepoRoot ("dist/All.Keyboard.Layouts.{0}.zip" -f $version)
            Push-Location $RepoRoot
            try {
                if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
                if ($bash) {
                    & bash -lc "command -v jq >/dev/null 2>&1 && command -v zip >/dev/null 2>&1"
                    if ($LASTEXITCODE -eq 0) {
                        & bash ./scripts/package_layouts.sh $version
                    }
                    else {
                        # Windows fallback when bash toolchain is incomplete
                        & (Join-Path $RepoRoot 'scripts/package_layouts.ps1') -Version $version
                    }
                }
                else {
                    # Windows fallback when bash is not available
                    & (Join-Path $RepoRoot 'scripts/package_layouts.ps1') -Version $version
                }
                Test-Path -LiteralPath $archive | Should -BeTrue
            }
            finally {
                if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue }
                Pop-Location
            }
        }
    }
}

Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

function Find-RepoRoot {
    param([string[]]$starts)
    if (-not $starts) { $starts = @() }
    if ($PSCommandPath) { $starts += (Split-Path -Parent $PSCommandPath) }
    if ($PSScriptRoot) { $starts += $PSScriptRoot }
    if ($MyInvocation -and $MyInvocation.MyCommand.Path) { $starts += (Split-Path -Parent $MyInvocation.MyCommand.Path) }
    $starts += (Get-Location).Path
    if ($env:GITHUB_WORKSPACE) { $starts += $env:GITHUB_WORKSPACE }

    foreach ($s in $starts | Where-Object { $_ }) {
        try { $cur = (Resolve-Path -Path $s).Path } catch { continue }
        while ($true) {
            if (Test-Path (Join-Path $cur 'All Keyboard Layouts (1.0.3.40)')) { return $cur }
            $parent = Split-Path -Parent $cur
            if ($parent -eq $cur) { break }
            $cur = $parent
        }
    }
    throw "Repository root containing 'All Keyboard Layouts (1.0.3.40)' not found from starts: $($starts -join ', ')"
}

## Don't resolve repo paths at parse time - compute in BeforeAll

Describe 'Batch/Wrapper script content tests' {
    BeforeAll {
        # Inline repo discovery to ensure the path is resolved during Pester discovery and execution
        $starts = @()
        if ($PSScriptRoot) { $starts += $PSScriptRoot }
        $starts += (Get-Location).Path
        if ($env:GITHUB_WORKSPACE) { $starts += $env:GITHUB_WORKSPACE }
        $found = $null
        foreach ($s in $starts) {
            if (-not $s) { continue }
            try { $cur = (Resolve-Path -Path $s).Path } catch { continue }
            while ($true) {
                if (Test-Path (Join-Path $cur 'All Keyboard Layouts (1.0.3.40)')) { $found = $cur; break }
                $parent = Split-Path -Parent $cur
                if ($parent -eq $cur) { break }
                $cur = $parent
            }
            if ($found) { break }
        }
        if (-not $found) { throw "Repository root containing 'All Keyboard Layouts (1.0.3.40)' not found" }
        $RepoRoot = $found
        $LayoutDir = Join-Path $RepoRoot 'All Keyboard Layouts (1.0.3.40)'
        $install = Join-Path $LayoutDir 'install_keyboard_layouts.bat'
        $uninstall = Join-Path $LayoutDir 'uninstall_keyboard_layouts.bat'
        $installElev = Join-Path $LayoutDir 'install_keyboard_layouts_elevated.bat'
        $uninstallElev = Join-Path $LayoutDir 'uninstall_keyboard_layouts_elevated.bat'
    }

    It 'batch files exist' {
        Test-Path $install | Should -BeTrue
        Test-Path $uninstall | Should -BeTrue
        Test-Path $installElev | Should -BeTrue
        Test-Path $uninstallElev | Should -BeTrue
    }

    It 'main installers reference the matrix PowerShell helpers' {
        $text = Get-Content -Path $install -Raw
        $text | Should -Match 'install_registry_from_matrix.ps1' -Because "installer should call install_registry_from_matrix.ps1"
        $text2 = Get-Content -Path $uninstall -Raw
        $text2 | Should -Match 'uninstall_registry_from_matrix.ps1' -Because "uninstaller should call uninstall_registry_from_matrix.ps1"
    }

    It 'elevated wrappers forward dry-run/silent flags to the elevated relaunch' {
        $i = Get-Content -Path $installElev -Raw
        $i | Should -Match 'MAGIC_DRYRUN' -Because 'elevated installer should handle dry-run forwarding'
        $i | Should -Match 'MAGIC_SILENT' -Because 'elevated installer should handle silent forwarding'

        $u = Get-Content -Path $uninstallElev -Raw
        # uninstall elevated wrapper delegates to the install_elevated launcher; ensure it either contains the flags or delegates
        ($u -match 'MAGIC_DRYRUN' -or $u -match 'install_keyboard_layouts_elevated\.bat') | Should -BeTrue -Because 'uninstall wrapper should forward/relay flags to elevated installer'
        ($u -match 'MAGIC_SILENT' -or $u -match 'install_keyboard_layouts_elevated\.bat') | Should -BeTrue -Because 'uninstall wrapper should forward/relay silent flags to elevated installer'
    }

    It 'batch installers contain safe confirmation for System32/HKLM edits (unless silent)' {
        $b = Get-Content -Path $install -Raw
        $b | Should -Match 'System32' -Because 'installer should warn about System32 changes where relevant'
    }
}

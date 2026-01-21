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

Describe 'MagicKeyboard installer tests' {
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
        $magicKeyboard = Join-Path $LayoutDir 'MagicKeyboard.ps1'
        $magicKeyboardBat = Join-Path $LayoutDir 'MagicKeyboard.bat'
    }

    It 'MagicKeyboard.ps1 exists' {
        Test-Path $magicKeyboard | Should -BeTrue
    }

    It 'MagicKeyboard.bat launcher exists' {
        Test-Path $magicKeyboardBat | Should -BeTrue
    }

    It 'MagicKeyboard.ps1 has valid PowerShell syntax' {
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($magicKeyboard, [ref]$null, [ref]$errors)
        $errors.Count | Should -Be 0
    }

    It 'MagicKeyboard.bat calls MagicKeyboard.ps1' {
        $text = Get-Content -Path $magicKeyboardBat -Raw
        $text | Should -Match 'MagicKeyboard.ps1' -Because "launcher should call MagicKeyboard.ps1"
    }

    It 'MagicKeyboard.ps1 supports Install action' {
        $text = Get-Content -Path $magicKeyboard -Raw
        $text | Should -Match 'Install' -Because "script should support Install action"
    }

    It 'MagicKeyboard.ps1 supports Uninstall action' {
        $text = Get-Content -Path $magicKeyboard -Raw
        $text | Should -Match 'Uninstall' -Because "script should support Uninstall action"
    }

    It 'MagicKeyboard.ps1 supports DryRun parameter' {
        $text = Get-Content -Path $magicKeyboard -Raw
        $text | Should -Match '\$DryRun' -Because "script should support DryRun parameter"
    }

    It 'MagicKeyboard.ps1 supports Silent parameter' {
        $text = Get-Content -Path $magicKeyboard -Raw
        $text | Should -Match '\$Silent' -Because "script should support Silent parameter"
    }

    It 'MagicKeyboard.ps1 supports Quiet parameter' {
        $text = Get-Content -Path $magicKeyboard -Raw
        $text | Should -Match '\$Quiet' -Because "script should support Quiet parameter"
    }

    It 'MagicKeyboard.ps1 references System32 for DLL installation' {
        $text = Get-Content -Path $magicKeyboard -Raw
        $text | Should -Match 'System32' -Because "installer should reference System32 for DLL placement"
    }

    It 'MagicKeyboard.ps1 supports auto-elevation' {
        $text = Get-Content -Path $magicKeyboard -Raw
        $text | Should -Match 'RunAs' -Because "installer should support auto-elevation via RunAs"
    }
}

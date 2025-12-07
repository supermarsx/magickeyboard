Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path "$ScriptRoot/../../../"
$LayoutDir = Join-Path $RepoRoot 'All Keyboard Layouts (1.0.3.40)'

Describe 'Batch/Wrapper script content tests' {
    BeforeAll {
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
        $u | Should -Match 'MAGIC_DRYRUN' -Because 'elevated uninstaller should handle dry-run forwarding'
        $u | Should -Match 'MAGIC_SILENT' -Because 'elevated uninstaller should handle silent forwarding'
    }

    It 'batch installers contain safe confirmation for System32/HKLM edits (unless silent)' {
        $b = Get-Content -Path $install -Raw
        $b | Should -Match 'System32' -Because 'installer should warn about System32 changes where relevant'
    }
}

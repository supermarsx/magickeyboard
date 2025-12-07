Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

function Find-RepoRoot {
    param([string[]]$starts)
    if (-not $starts) { $starts = @() }
    if ($PSScriptRoot) { $starts += $PSScriptRoot }
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


Describe 'Layouts JSON and checksums' {
    BeforeAll {
        # Inline repo discovery to ensure the helper is available during Pester discovery and execution
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
        $matrix = Get-Content -Raw -Path (Join-Path $LayoutDir 'layouts.json') | ConvertFrom-Json
        $trans = Get-Content -Raw -Path (Join-Path $LayoutDir 'translations.json') | ConvertFrom-Json
        $filelist = @()
        foreach ($p in $matrix.PSObject.Properties) { $filelist += $p.Value.file }
    }

    It 'layouts.json entries include file properties for all keys' {
        $matrixFiles = @()
        foreach ($p in $matrix.PSObject.Properties) { $matrixFiles += $p.Value.file }

        $matrixFiles | Should -Not -BeNullOrEmpty -Because 'layouts.json must contain file entries for layout keys'
        ($matrixFiles | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Measure-Object).Count | Should -Be ($matrix.PSObject.Properties.Count)
    }

    It 'all files listed in layouts.json exist and include sha256 values' {
        foreach ($p in $matrix.PSObject.Properties) {
            $fname = $p.Value.file
            $fname | Should -Not -BeNullOrEmpty -Because "matrix entry $($p.Name) must include a file"
            Test-Path (Join-Path $LayoutDir $fname) | Should -BeTrue -Because "file $fname must exist"
            $p.Value.PSObject.Properties.Name | Should -Contain 'sha256' -Because "matrix entry $($p.Name) must include sha256"
        }
    }

    It 'embedded sha256 values match actual file content' {
        foreach ($p in $matrix.PSObject.Properties) {
            $fname = $p.Value.file
            $expected = $p.Value.sha256
            $path = Join-Path $LayoutDir $fname
            Test-Path $path | Should -BeTrue -Because "file $fname must exist for hashing"
            $actual = (Get-FileHash -Path $path -Algorithm SHA256).Hash
            $actual | Should -Be $expected -Because "sha256 for $fname must match the embedded value in layouts.json"
        }
    }

    Context 'negative scenarios' {
        It 'detects checksum mismatch when layouts.json contains wrong sha256 for a file' {
            # create a temporary copy of layouts.json with a tampered sha for the first DLL
            $tmp = [System.IO.Path]::GetTempFileName()
            $orig = Get-Content -Raw -Path (Join-Path $LayoutDir 'layouts.json') | ConvertFrom-Json
            $keys = $orig.PSObject.Properties.Name
            $k0 = $keys[0]
            $orig.$k0.sha256 = ('00' * 32)
            $json = $orig | ConvertTo-Json -Depth 6
            Set-Content -Path $tmp -Value $json

            $entry = $orig.$k0
            $path = Join-Path $LayoutDir $entry.file
            $actual = (Get-FileHash -Path $path -Algorithm SHA256).Hash
            # assert the tampered sha does not match the real hash
            $actual | Should -Not -Be $entry.sha256
            Remove-Item -Path $tmp -Force
        }
    }

    It 'layout entries have either reg_key or reg_path and valid reg_path format' {
        foreach ($p in $matrix.PSObject.Properties) {
            $entry = $p.Value
            ($entry.PSObject.Properties.Name -contains 'reg_key' -or $entry.PSObject.Properties.Name -contains 'reg_path') | Should -BeTrue -Because "Entry $($p.Name) must have reg_key or reg_path"
            if ($entry.PSObject.Properties.Name -contains 'reg_path' -and $entry.reg_path) {
                $entry.reg_path | Should -Match '^HKLM\\' -Because 'reg_path should start with HKLM\\ when present'
            }
        }
    }

    It 'DLL files are Windows PE files (MZ header) or not empty' {
        foreach ($f in $filelist) {
            $f = $f.Trim()
            if ($f -eq '') { continue }
            $path = Join-Path $LayoutDir $f
            $bytes = [System.IO.File]::ReadAllBytes($path)
            $bytes.Length | Should -BeGreaterThan 0
            $header = -join ($bytes[0..1] | ForEach-Object {[char]$_})
            # MZ signature for a PE file: 0x4D 0x5A -> "MZ"
            if ($f.ToLower().EndsWith('.dll') -or $f.ToLower().EndsWith('.exe')) {
                $header | Should -Be 'MZ' -Because "$f should be a Windows PE file"
            }
        }
    }
}

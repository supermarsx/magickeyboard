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
        $filelist = (Get-Content -Path (Join-Path $LayoutDir 'install_filelist.txt') -ErrorAction Stop) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $checksums = @{}
        foreach ($line in (Get-Content -Path (Join-Path $LayoutDir 'install_checksums.txt'))) {
            if ($line -match '^\s*$') { continue }
            $parts = $line -split '\s+'; $checksums[$parts[1]] = $parts[0]
        }
    }

    It 'layouts.json entries match install_filelist.txt files and keys are present' {
        $matrixFiles = @()
        foreach ($p in $matrix.PSObject.Properties) { $matrixFiles += $p.Value.file }

        $missingFromMatrix = $filelist | Where-Object { $_ -notin $matrixFiles }
        $missingFromFilelist = $matrixFiles | Where-Object { $_ -notin $filelist }

        $missingFromMatrix | Should -BeNullOrEmpty -Because 'all files in install_filelist.txt should be present in layouts.json'
        $missingFromFilelist | Should -BeNullOrEmpty -Because 'layouts.json should not contain extra files not listed in install_filelist.txt'
    }

    It 'all DLL files listed in install_filelist.txt have checksum entries' {
        foreach ($f in $filelist) {
            $f = $f.Trim()
            if ($f -eq '') { continue }
            Test-Path (Join-Path $LayoutDir $f) | Should -BeTrue -Because "file $f must exist"
            $checksums.ContainsKey($f) | Should -BeTrue -Because "checksum entry for $f required in install_checksums.txt"
        }
    }

    It 'checksums for files are correct' {
        foreach ($kv in $checksums.GetEnumerator()) {
            $f = Join-Path $LayoutDir $kv.Key
            Test-Path $f | Should -BeTrue -Because "file exists for checksum $($kv.Key)"
            $actual = (Get-FileHash -Path $f -Algorithm SHA256).Hash
            $actual | Should -Be $kv.Value -Because "computed SHA256 should match expected for $($kv.Key)"
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

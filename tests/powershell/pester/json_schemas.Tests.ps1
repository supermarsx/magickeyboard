Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

Describe 'JSON schemas' {
    BeforeAll {
        $starts = @()
        if ($PSCommandPath) { $starts += (Split-Path -Parent $PSCommandPath) }
        if ($PSScriptRoot) { $starts += $PSScriptRoot }
        if ($MyInvocation -and $MyInvocation.MyCommand.Path) { $starts += (Split-Path -Parent $MyInvocation.MyCommand.Path) }
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
        $script:RepoRoot = $found
        $script:LayoutDir = Join-Path $script:RepoRoot 'All Keyboard Layouts (1.0.3.40)'
    }

    It 'schema files exist and parse as JSON' {
        $schemaDir = Join-Path $script:RepoRoot 'schemas'
        $layoutSchemaPath = Join-Path $schemaDir 'layouts.schema.json'
        $translationsSchemaPath = Join-Path $schemaDir 'translations.schema.json'

        Test-Path $layoutSchemaPath | Should -BeTrue
        Test-Path $translationsSchemaPath | Should -BeTrue

        { Get-Content -Raw -Path $layoutSchemaPath | ConvertFrom-Json } | Should -Not -Throw
        { Get-Content -Raw -Path $translationsSchemaPath | ConvertFrom-Json } | Should -Not -Throw
    }

    It 'layouts.json satisfies basic schema invariants' {
        $layoutsJson = Join-Path $script:LayoutDir 'layouts.json'
        $matrix = Get-Content -Raw -Path $layoutsJson | ConvertFrom-Json
        foreach ($p in $matrix.PSObject.Properties) {
            $key = $p.Name
            $entry = $p.Value

            $key | Should -Match '^[A-Za-z0-9]+$'
            $entry.file | Should -Match '\.dll$'

            # sha256 should be 64 hex characters (tests also validate hashes elsewhere)
            $entry.sha256 | Should -Match '^[0-9A-Fa-f]{64}$'

            if ($entry.PSObject.Properties.Name -contains 'reg_key' -and $entry.reg_key) {
                $entry.reg_key | Should -Match '^[0-9A-Fa-f]{8}$'
            }
            if ($entry.PSObject.Properties.Name -contains 'reg_path' -and $entry.reg_path) {
                $entry.reg_path | Should -Match '^HKLM\\SYSTEM\\CurrentControlSet\\Control\\Keyboard Layouts\\[0-9A-Fa-f]{8}$'
            }
        }
    }

    It 'translations.json contains an English fallback for each layout key' {
        $layoutsJson = Join-Path $script:LayoutDir 'layouts.json'
        $translationsJson = Join-Path $script:LayoutDir 'translations.json'
        $matrix = Get-Content -Raw -Path $layoutsJson | ConvertFrom-Json
        $trans = Get-Content -Raw -Path $translationsJson | ConvertFrom-Json

        foreach ($p in $matrix.PSObject.Properties) {
            $key = $p.Name
            ($trans.PSObject.Properties.Name -contains $key) | Should -BeTrue -Because "translations.json should include key $key"
            $entry = $trans.$key
            ($entry.PSObject.Properties.Name -contains 'en') | Should -BeTrue -Because "translations.json.$key should include an 'en' fallback"
            $entry.en | Should -Not -BeNullOrEmpty
        }
    }
}

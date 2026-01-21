<#
.SYNOPSIS
    MagicKeyboard - Apple Keyboard Layouts Installer/Uninstaller for Windows
.DESCRIPTION
    A unified TUI-based installer for Apple Magic Keyboard layouts.
    Features auto-elevation, install/uninstall, registry backup/restore,
    dry-run simulation, and system restore point creation.
.NOTES
    Version: 1.0.0
    Requires: Windows PowerShell 5.1+ or PowerShell 7+
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Install', 'Uninstall', 'Backup', 'Restore', 'List', 'GetTranslation', 'Help', 'Menu', '')]
    [string]$Action = '',

    [string]$Layouts,
    [string]$Key,
    [string]$Locale,
    [string]$BackupPath,
    [string]$TranslationsFile,
    [switch]$DryRun,
    [switch]$Silent,
    [Alias('q')]
    [switch]$Quiet,
    [Alias('v')]
    [switch]$ShowDetails,
    [switch]$CreateRestorePoint,
    [switch]$NoLogo,
    [Alias('h', '?')]
    [switch]$Help
)

# Configuration
$script:Version = '1.0.0'
$script:ScriptDir = $PSScriptRoot
$script:LayoutsJsonPath = Join-Path $script:ScriptDir 'layouts.json'
$script:TranslationsJsonPath = if ($TranslationsFile -and (Test-Path $TranslationsFile)) { $TranslationsFile } else { Join-Path $script:ScriptDir 'translations.json' }
$script:FileListPath = Join-Path $script:ScriptDir 'install_filelist.txt'
$script:ChecksumsPath = Join-Path $script:ScriptDir 'install_checksums.txt'
$script:LogFile = Join-Path $env:TEMP 'magickeyboard.log'
$script:System32 = 'C:\Windows\System32'

# TUI Colors
$script:Colors = @{
    Title     = 'Cyan'
    Menu      = 'White'
    Highlight = 'Yellow'
    Success   = 'Green'
    Warning   = 'DarkYellow'
    Error     = 'Red'
    Info      = 'Gray'
    Accent    = 'Magenta'
}

function Test-IsElevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Elevate {
    param([string[]]$Arguments)
    
    $scriptPath = $PSCommandPath
    if (-not $scriptPath) { $scriptPath = $MyInvocation.PSCommandPath }
    
    $argString = $Arguments -join ' '
    
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = 'powershell.exe'
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $argString"
        $psi.Verb = 'RunAs'
        $psi.UseShellExecute = $true
        
        $process = [System.Diagnostics.Process]::Start($psi)
        if ($process) {
            $process.WaitForExit()
            return $process.ExitCode
        }
    }
    catch {
        Write-ColorText "Failed to elevate: $_" -Color $script:Colors.Error
        return 1
    }
    return 0
}

function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = 'White',
        [switch]$NoNewline
    )
    if ($Quiet) { return }
    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    }
    else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Write-Logo {
    if ($NoLogo -or $Quiet) { return }
    
    Clear-Host
    Write-Host ""
    Write-ColorText "  =================================================================" -Color $script:Colors.Title
    Write-ColorText "                                                                   " -Color $script:Colors.Title
    Write-ColorText "    M A G I C   K E Y B O A R D                                    " -Color $script:Colors.Title
    Write-ColorText "                                                                   " -Color $script:Colors.Title
    Write-ColorText "    Apple Keyboard Layouts for Windows                             " -Color $script:Colors.Title
    Write-ColorText "    Version $($script:Version)                                                     " -Color $script:Colors.Title
    Write-ColorText "                                                                   " -Color $script:Colors.Title
    Write-ColorText "  =================================================================" -Color $script:Colors.Title
    Write-Host ""
}

function Write-Header {
    param([string]$Title)
    if ($Quiet) { return }
    $width = 65
    $line = '=' * $width
    
    Write-Host ""
    Write-ColorText "  $line" -Color $script:Colors.Accent
    Write-ColorText "    $Title" -Color $script:Colors.Accent
    Write-ColorText "  $line" -Color $script:Colors.Accent
    Write-Host ""
}

function Write-MenuOption {
    param(
        [string]$Key,
        [string]$Description,
        [switch]$Disabled
    )
    $color = if ($Disabled) { 'DarkGray' } else { $script:Colors.Menu }
    Write-ColorText "    [$Key] $Description" -Color $color
}

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )
    if ($Quiet) { return }
    $prefix = switch ($Type) {
        'Info' { '  [i] ' }
        'Success' { '  [+] ' }
        'Warning' { '  [!] ' }
        'Error' { '  [-] ' }
    }
    $color = switch ($Type) {
        'Info' { $script:Colors.Info }
        'Success' { $script:Colors.Success }
        'Warning' { $script:Colors.Warning }
        'Error' { $script:Colors.Error }
    }
    Write-ColorText "$prefix$Message" -Color $color
}

function Write-ProgressBar {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Activity = 'Processing'
    )
    if ($Quiet) { return }
    $percent = if ($Total -gt 0) { [math]::Round(($Current / $Total) * 100) } else { 0 }
    $barLength = 40
    $filled = [math]::Round($barLength * $Current / [math]::Max(1, $Total))
    $empty = $barLength - $filled
    
    $bar = ('#' * $filled) + ('-' * $empty)
    Write-Host ("`r  [$bar] $percent% - $Activity ($Current/$Total)    ") -NoNewline
}

function Read-MenuChoice {
    param([string]$Prompt = 'Select an option')
    Write-Host ""
    Write-ColorText "  $Prompt : " -Color $script:Colors.Menu -NoNewline
    return $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').Character.ToString().ToUpper()
}

function Read-YesNo {
    param([string]$Prompt, [bool]$Default = $false)
    $defaultText = if ($Default) { '[Y/n]' } else { '[y/N]' }
    Write-ColorText "  $Prompt $defaultText : " -Color $script:Colors.Menu -NoNewline
    $response = Read-Host
    if ([string]::IsNullOrWhiteSpace($response)) { return $Default }
    return $response -match '^[Yy]'
}

function Show-PausePrompt {
    if (-not $Silent) {
        Write-Host ""
        Write-ColorText "  Press any key to continue..." -Color $script:Colors.Info
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Get-LayoutMatrix {
    if (-not (Test-Path $script:LayoutsJsonPath)) {
        throw "layouts.json not found at: $script:LayoutsJsonPath"
    }
    return Get-Content -Raw -Path $script:LayoutsJsonPath | ConvertFrom-Json
}

function Get-Translations {
    if (-not (Test-Path $script:TranslationsJsonPath)) {
        return $null
    }
    return Get-Content -Raw -Path $script:TranslationsJsonPath | ConvertFrom-Json
}

function Get-TranslatedName {
    param(
        [string]$Key,
        [object]$Translations,
        [string]$RequestedLocale
    )
    
    if (-not $Translations) { return $Key }
    
    $loc = if ($RequestedLocale) { $RequestedLocale } else { (Get-UICulture).Name }
    $loc = $loc -replace '\..*$', '' -replace '_', '-'
    
    if ($loc -match '-') {
        $parts = $loc -split '-'
        $lang = $parts[0].ToLower()
        $region = $parts[1].ToUpper()
        $loc = "$lang-$region"
    }
    else {
        $lang = $loc.ToLower()
    }
    
    $entry = $null
    if ($Translations.PSObject.Properties.Name -contains $Key) {
        $entry = $Translations.$Key
    }
    
    if ($entry) {
        foreach ($tryLocale in @($loc, $lang, 'en')) {
            if ($entry.PSObject.Properties.Name -contains $tryLocale) {
                return $entry.$tryLocale
            }
        }
        $firstProp = $entry.PSObject.Properties | Select-Object -First 1
        if ($firstProp) { return $firstProp.Value }
    }
    
    return $Key
}

function Get-ChecksumForFile {
    param([string]$FileName)
    
    if (-not (Test-Path $script:ChecksumsPath)) { return $null }
    
    $content = Get-Content -Path $script:ChecksumsPath
    foreach ($line in $content) {
        if ($line -match '^\s*([a-fA-F0-9]{64})\s+(.+)$') {
            if ($Matches[2].Trim() -eq $FileName) {
                return $Matches[1].ToLower()
            }
        }
    }
    return $null
}

function Get-FileHash256 {
    param([string]$FilePath)
    return (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToLower()
}

function Get-RegistryPath {
    param([object]$Entry)
    
    if ($Entry.PSObject.Properties.Name -contains 'reg_path' -and $Entry.reg_path) {
        $full = $Entry.reg_path -replace '\\{2,}', '\\'
        if ($full -like 'HKLM\*') { $full = $full -replace '^HKLM\\', 'HKLM:\' }
        return $full
    }
    
    if ($Entry.PSObject.Properties.Name -contains 'reg_key' -and $Entry.reg_key) {
        return "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\$($Entry.reg_key)"
    }
    
    return $null
}

function New-RegistryBackup {
    param(
        [object]$Matrix,
        [string]$OutFile,
        [string[]]$LayoutFilter
    )
    
    $propertyNames = @('Layout Text', 'Layout File', 'Layout Id', 'Layout Component ID')
    $entries = @()
    
    foreach ($prop in $Matrix.PSObject.Properties) {
        $key = $prop.Name
        
        if ($LayoutFilter -and $LayoutFilter.Count -gt 0 -and ($LayoutFilter -notcontains $key)) {
            continue
        }
        
        $entry = $prop.Value
        $regPath = Get-RegistryPath -Entry $entry
        if (-not $regPath) { continue }
        
        $existed = $false
        $present = @{}
        $values = @{}
        
        try {
            if (Test-Path $regPath) {
                $existed = $true
                $item = Get-ItemProperty -Path $regPath -ErrorAction Stop
                foreach ($name in $propertyNames) {
                    if ($item.PSObject.Properties.Name -contains $name) {
                        $present[$name] = $true
                        $values[$name] = $item.$name -as [string]
                    }
                    else {
                        $present[$name] = $false
                    }
                }
            }
            else {
                foreach ($name in $propertyNames) { $present[$name] = $false }
            }
        }
        catch {
            foreach ($name in $propertyNames) { 
                if (-not $present.ContainsKey($name)) { $present[$name] = $false } 
            }
        }
        
        $entries += [pscustomobject]@{
            key     = $key
            regPath = $regPath
            existed = $existed
            present = $present
            values  = $values
        }
    }
    
    $backup = [pscustomobject]@{
        createdUtc = (Get-Date).ToUniversalTime().ToString('o')
        matrixPath = $script:LayoutsJsonPath
        layouts    = $LayoutFilter
        entries    = $entries
    }
    
    $backup | ConvertTo-Json -Depth 8 | Set-Content -Path $OutFile -Encoding UTF8
    return $OutFile
}

function Restore-RegistryBackup {
    param(
        [string]$BackupFile,
        [switch]$DryRunMode
    )
    
    if (-not (Test-Path $BackupFile)) {
        throw "Backup file not found: $BackupFile"
    }
    
    $backup = Get-Content -Raw -Path $BackupFile | ConvertFrom-Json
    if (-not $backup.entries) {
        throw "Invalid backup file format"
    }
    
    $propertyNames = @('Layout Text', 'Layout File', 'Layout Id', 'Layout Component ID')
    $count = 0
    
    foreach ($e in $backup.entries) {
        $regPath = $e.regPath
        if (-not $regPath) { continue }
        
        if (-not $e.existed) {
            if ($DryRunMode) {
                Write-Status "Would remove: $regPath (absent in backup)" -Type Info
            }
            else {
                if (Test-Path $regPath) {
                    Remove-Item -Path $regPath -Recurse -Force
                    Write-Status "Removed: $regPath" -Type Success
                }
            }
            $count++
            continue
        }
        
        if ($DryRunMode) {
            Write-Status "Would restore: $regPath" -Type Info
            $count++
            continue
        }
        
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        
        foreach ($name in $propertyNames) {
            $wasPresent = $false
            if ($e.present -and $e.present.PSObject.Properties.Name -contains $name) {
                $wasPresent = [bool]$e.present.$name
            }
            
            if ($wasPresent) {
                $val = $null
                if ($e.values -and $e.values.PSObject.Properties.Name -contains $name) {
                    $val = $e.values.$name
                }
                New-ItemProperty -Path $regPath -Name $name -Value ($val -as [string]) -PropertyType String -Force | Out-Null
            }
            else {
                try {
                    $cur = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
                    if ($cur -and $cur.PSObject.Properties.Name -contains $name) {
                        Remove-ItemProperty -Path $regPath -Name $name -ErrorAction SilentlyContinue
                    }
                }
                catch { }
            }
        }
        
        Write-Status "Restored: $regPath" -Type Success
        $count++
    }
    
    return $count
}

function Install-RegistryEntries {
    param(
        [object]$Matrix,
        [object]$Translations,
        [string]$RequestedLocale,
        [string[]]$LayoutFilter,
        [switch]$DryRunMode
    )
    
    $allKeys = @($Matrix.PSObject.Properties.Name)
    $keysToProcess = if ($LayoutFilter -and $LayoutFilter.Count -gt 0) {
        $allKeys | Where-Object { $LayoutFilter -contains $_ }
    }
    else { $allKeys }
    
    $total = @($keysToProcess).Count
    $count = 0
    $current = 0
    
    if (-not $Silent) {
        Write-Status "Processing $total registry entries..." -Type Info
    }
    
    foreach ($prop in $Matrix.PSObject.Properties) {
        $key = $prop.Name
        
        if ($LayoutFilter -and $LayoutFilter.Count -gt 0 -and ($LayoutFilter -notcontains $key)) {
            continue
        }
        
        $current++
        $entry = $prop.Value
        $layoutText = Get-TranslatedName -Key $key -Translations $Translations -RequestedLocale $RequestedLocale
        $regPath = Get-RegistryPath -Entry $entry
        
        if (-not $regPath) {
            Write-Status "Skipping $key - no registry path" -Type Warning
            continue
        }
        
        if (-not $Silent) {
            Write-ProgressBar -Current $current -Total $total -Activity "Registry: $key"
        }
        
        if ($DryRunMode) {
            if (-not $Silent) { Write-Host "" }
            Write-Status "[$current/$total] Would create: $key" -Type Info
            if ($ShowDetails) {
                Write-Status "    Path: $regPath" -Type Info
                Write-Status "    Layout Text: $layoutText" -Type Info
                Write-Status "    Layout File: $($entry.file)" -Type Info
                Write-Status "    Layout Id: $($entry.layout_id)" -Type Info
            }
            $count++
            continue
        }
        
        try {
            $isNew = -not (Test-Path $regPath)
            if ($isNew) {
                New-Item -Path $regPath -Force | Out-Null
            }
            
            if ($layoutText) {
                New-ItemProperty -Path $regPath -Name 'Layout Text' -Value $layoutText -PropertyType String -Force | Out-Null
            }
            if ($entry.file) {
                New-ItemProperty -Path $regPath -Name 'Layout File' -Value $entry.file -PropertyType String -Force | Out-Null
            }
            if ($entry.layout_id) {
                New-ItemProperty -Path $regPath -Name 'Layout Id' -Value $entry.layout_id -PropertyType String -Force | Out-Null
            }
            if ($entry.component_id) {
                New-ItemProperty -Path $regPath -Name 'Layout Component ID' -Value $entry.component_id -PropertyType String -Force | Out-Null
            }
            
            if (-not $Silent) { Write-Host "" }
            $action = if ($isNew) { "Created" } else { "Updated" }
            Write-Status "[$current/$total] $action`: $key ($layoutText)" -Type Success
            if ($ShowDetails) {
                Write-Status "    Path: $regPath" -Type Info
                Write-Status "    File: $($entry.file)" -Type Info
            }
            $count++
        }
        catch {
            if (-not $Silent) { Write-Host "" }
            Write-Status "[$current/$total] Failed: $key - $_" -Type Error
            throw
        }
    }
    
    if (-not $Silent) { Write-Host "" }
    return $count
}

function Uninstall-RegistryEntries {
    param(
        [object]$Matrix,
        [string[]]$LayoutFilter,
        [switch]$DryRunMode
    )
    
    $allKeys = @($Matrix.PSObject.Properties.Name)
    $keysToProcess = if ($LayoutFilter -and $LayoutFilter.Count -gt 0) {
        $allKeys | Where-Object { $LayoutFilter -contains $_ }
    }
    else { $allKeys }
    
    $total = @($keysToProcess).Count
    $count = 0
    $current = 0
    
    if (-not $Silent) {
        Write-Status "Processing $total registry entries for removal..." -Type Info
    }
    
    foreach ($prop in $Matrix.PSObject.Properties) {
        $key = $prop.Name
        
        if ($LayoutFilter -and $LayoutFilter.Count -gt 0 -and ($LayoutFilter -notcontains $key)) {
            continue
        }
        
        $current++
        $entry = $prop.Value
        $regPath = Get-RegistryPath -Entry $entry
        
        if (-not $regPath) { 
            Write-Status "[$current/$total] Skipping $key - no registry path" -Type Warning
            continue 
        }
        
        if (-not $Silent) {
            Write-ProgressBar -Current $current -Total $total -Activity "Registry: $key"
        }
        
        $exists = Test-Path $regPath
        
        if ($DryRunMode) {
            if (-not $Silent) { Write-Host "" }
            if ($exists) {
                Write-Status "[$current/$total] Would delete: $key" -Type Info
                if ($ShowDetails) {
                    Write-Status "    Path: $regPath" -Type Info
                }
            }
            else {
                Write-Status "[$current/$total] Not present: $key" -Type Info
            }
            $count++
            continue
        }
        
        try {
            if ($exists) {
                Remove-Item -Path $regPath -Recurse -Force -ErrorAction Stop
                if (-not $Silent) { Write-Host "" }
                Write-Status "[$current/$total] Removed: $key" -Type Success
                if ($ShowDetails) {
                    Write-Status "    Path: $regPath" -Type Info
                }
                $count++
            }
            else {
                if (-not $Silent) { Write-Host "" }
                Write-Status "[$current/$total] Skipped (not found): $key" -Type Info
            }
        }
        catch {
            if (-not $Silent) { Write-Host "" }
            Write-Status "[$current/$total] Failed: $key - $_" -Type Error
            throw
        }
    }
    
    if (-not $Silent) { Write-Host "" }
    return $count
}

function Get-FilesToProcess {
    param(
        [object]$Matrix,
        [string[]]$LayoutFilter
    )
    
    $files = @()
    
    if ($LayoutFilter -and $LayoutFilter.Count -gt 0) {
        foreach ($key in $LayoutFilter) {
            if ($Matrix.PSObject.Properties.Name -contains $key) {
                $files += $Matrix.$key.file
            }
        }
    }
    else {
        if (Test-Path $script:FileListPath) {
            $files = Get-Content -Path $script:FileListPath | Where-Object { $_.Trim() -ne '' }
        }
        else {
            foreach ($prop in $Matrix.PSObject.Properties) {
                if ($prop.Value.file) {
                    $files += $prop.Value.file
                }
            }
        }
    }
    
    return $files | Sort-Object -Unique
}

function Install-LayoutFiles {
    param(
        [string[]]$Files,
        [switch]$DryRunMode
    )
    
    $installed = 0
    $total = $Files.Count
    
    if (-not $Silent) {
        Write-Status "Processing $total DLL files..." -Type Info
    }
    
    foreach ($file in $Files) {
        $installed++
        $sourcePath = Join-Path $script:ScriptDir $file
        $destPath = Join-Path $script:System32 $file
        
        if (-not $Silent) {
            Write-ProgressBar -Current $installed -Total $total -Activity "Verifying: $file"
        }
        
        if (-not (Test-Path $sourcePath)) {
            if (-not $Silent) { Write-Host "" }
            Write-Status "[$installed/$total] Missing source file: $file" -Type Error
            throw "Source file not found: $sourcePath"
        }
        
        # Checksum verification
        $checksumOk = $false
        $expectedHash = Get-ChecksumForFile -FileName $file
        if ($expectedHash) {
            $actualHash = Get-FileHash256 -FilePath $sourcePath
            if ($actualHash -ne $expectedHash) {
                if (-not $Silent) { Write-Host "" }
                Write-Status "[$installed/$total] Checksum FAILED: $file" -Type Error
                if ($ShowDetails) {
                    Write-Status "    Expected: $expectedHash" -Type Error
                    Write-Status "    Actual:   $actualHash" -Type Error
                }
                throw "Checksum verification failed for $file"
            }
            $checksumOk = $true
        }
        else {
            if ($ShowDetails -and -not $Silent) {
                Write-Host ""
                Write-Status "[$installed/$total] No checksum entry for $file" -Type Warning
            }
        }
        
        # Signature verification
        $signatureOk = $false
        try {
            $sig = Get-AuthenticodeSignature -FilePath $sourcePath
            $signatureOk = ($sig.Status -eq 'Valid')
            if (-not $signatureOk -and $ShowDetails -and -not $Silent) {
                Write-Host ""
                Write-Status "[$installed/$total] Signature: $($sig.Status) for $file" -Type Warning
            }
        }
        catch {
            if ($ShowDetails -and -not $Silent) {
                Write-Host ""
                Write-Status "[$installed/$total] Could not verify signature for $file" -Type Warning
            }
        }
        
        if ($DryRunMode) {
            if (-not $Silent) { Write-Host "" }
            $verifyStatus = @()
            if ($checksumOk) { $verifyStatus += "checksum OK" }
            if ($signatureOk) { $verifyStatus += "signed" }
            $verifyText = if ($verifyStatus.Count -gt 0) { " (" + ($verifyStatus -join ", ") + ")" } else { "" }
            Write-Status "[$installed/$total] Would copy: $file$verifyText" -Type Info
            if ($ShowDetails) {
                Write-Status "    Source: $sourcePath" -Type Info
                Write-Status "    Dest:   $destPath" -Type Info
            }
        }
        else {
            if (-not $Silent) {
                Write-ProgressBar -Current $installed -Total $total -Activity "Copying: $file"
            }
            Copy-Item -Path $sourcePath -Destination $destPath -Force -ErrorAction Stop
            if (-not $Silent) { Write-Host "" }
            $verifyStatus = @()
            if ($checksumOk) { $verifyStatus += "checksum OK" }
            if ($signatureOk) { $verifyStatus += "signed" }
            $verifyText = if ($verifyStatus.Count -gt 0) { " (" + ($verifyStatus -join ", ") + ")" } else { "" }
            Write-Status "[$installed/$total] Copied: $file$verifyText" -Type Success
        }
    }
    
    return $installed
}

function Uninstall-LayoutFiles {
    param(
        [string[]]$Files,
        [switch]$DryRunMode
    )
    
    $removed = 0
    $skipped = 0
    $total = $Files.Count
    
    if (-not $Silent) {
        Write-Status "Processing $total DLL files for removal..." -Type Info
    }
    
    foreach ($file in $Files) {
        $current = $removed + $skipped + 1
        $destPath = Join-Path $script:System32 $file
        
        if (-not $Silent) {
            Write-ProgressBar -Current $current -Total $total -Activity "Checking: $file"
        }
        
        $exists = Test-Path $destPath
        
        if ($DryRunMode) {
            if (-not $Silent) { Write-Host "" }
            if ($exists) {
                Write-Status "[$current/$total] Would delete: $file" -Type Info
                if ($ShowDetails) {
                    Write-Status "    Path: $destPath" -Type Info
                }
                $removed++
            }
            else {
                Write-Status "[$current/$total] Not present: $file" -Type Info
                $skipped++
            }
        }
        else {
            if ($exists) {
                Remove-Item -Path $destPath -Force -ErrorAction SilentlyContinue
                if (-not $Silent) { Write-Host "" }
                Write-Status "[$current/$total] Deleted: $file" -Type Success
                $removed++
            }
            else {
                if (-not $Silent) { Write-Host "" }
                Write-Status "[$current/$total] Skipped (not found): $file" -Type Info
                $skipped++
            }
        }
    }
    
    if (-not $Silent -and $skipped -gt 0) {
        Write-Status "Skipped $skipped files (not present)" -Type Info
    }
    
    return $removed
}

function New-SystemRestorePoint {
    param([string]$Description)
    
    try {
        Checkpoint-Computer -Description $Description -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        Write-Status "System restore point created" -Type Success
        return $true
    }
    catch {
        Write-Status "Could not create restore point: $_" -Type Warning
        return $false
    }
}

function Show-MainMenu {
    Write-Logo
    Write-Header "Main Menu"
    
    $isElevated = Test-IsElevated
    $elevationNote = if ($isElevated) { " (Running as Administrator)" } else { " (Will request elevation)" }
    
    Write-MenuOption -Key '1' -Description "Install keyboard layouts$elevationNote"
    Write-MenuOption -Key '2' -Description "Uninstall keyboard layouts$elevationNote"
    Write-MenuOption -Key '3' -Description "Backup current registry entries"
    Write-MenuOption -Key '4' -Description "Restore registry from backup$elevationNote"
    Write-MenuOption -Key '5' -Description "View installed layouts"
    Write-MenuOption -Key '6' -Description "Dry-run install (simulation)"
    Write-MenuOption -Key '7' -Description "Dry-run uninstall (simulation)"
    Write-Host ""
    Write-MenuOption -Key 'Q' -Description "Quit"
    
    return Read-MenuChoice -Prompt 'Select an option'
}

function Invoke-InstallAction {
    param(
        [string[]]$LayoutFilter,
        [switch]$DryRunMode
    )
    
    $dryLabel = if ($DryRunMode) { " (DRY RUN)" } else { "" }
    Write-Header "Installing Layouts$dryLabel"
    
    if (-not $DryRunMode -and -not (Test-IsElevated)) {
        Write-Status "Requesting elevation..." -Type Info
        $elevArgs = @('-Action', 'Install')
        if ($LayoutFilter) { $elevArgs += @('-Layouts', ($LayoutFilter -join ',')) }
        if ($Locale) { $elevArgs += @('-Locale', $Locale) }
        if ($CreateRestorePoint) { $elevArgs += '-CreateRestorePoint' }
        if ($Silent) { $elevArgs += '-Silent' }
        if ($Quiet) { $elevArgs += '-Quiet' }
        if ($ShowDetails) { $elevArgs += '-ShowDetails' }
        $elevArgs += '-NoLogo'
        
        $exitCode = Invoke-Elevate -Arguments $elevArgs
        return $exitCode
    }
    
    try {
        $matrix = Get-LayoutMatrix
        $translations = Get-Translations
        
        if ($CreateRestorePoint -and -not $DryRunMode) {
            Write-Status "Creating system restore point..." -Type Info
            New-SystemRestorePoint -Description 'MagicKeyboard layouts install'
        }
        
        Write-Status "Installing registry entries..." -Type Info
        $regCount = Install-RegistryEntries -Matrix $matrix -Translations $translations -RequestedLocale $Locale -LayoutFilter $LayoutFilter -DryRunMode:$DryRunMode
        
        Write-Status "Copying layout files to System32..." -Type Info
        $files = Get-FilesToProcess -Matrix $matrix -LayoutFilter $LayoutFilter
        $fileCount = Install-LayoutFiles -Files $files -DryRunMode:$DryRunMode
        
        Write-Host ""
        Write-Header "Installation Complete$dryLabel"
        Write-Status "Registry entries: $regCount" -Type Success
        Write-Status "Files copied: $fileCount" -Type Success
        
        return 0
    }
    catch {
        Write-Status "Installation failed: $_" -Type Error
        return 1
    }
}

function Invoke-UninstallAction {
    param(
        [string[]]$LayoutFilter,
        [switch]$DryRunMode
    )
    
    $dryLabel = if ($DryRunMode) { " (DRY RUN)" } else { "" }
    Write-Header "Uninstalling Layouts$dryLabel"
    
    if (-not $DryRunMode -and -not (Test-IsElevated)) {
        Write-Status "Requesting elevation..." -Type Info
        $elevArgs = @('-Action', 'Uninstall')
        if ($LayoutFilter) { $elevArgs += @('-Layouts', ($LayoutFilter -join ',')) }
        if ($CreateRestorePoint) { $elevArgs += '-CreateRestorePoint' }
        if ($Silent) { $elevArgs += '-Silent' }
        if ($Quiet) { $elevArgs += '-Quiet' }
        if ($ShowDetails) { $elevArgs += '-ShowDetails' }
        $elevArgs += '-NoLogo'
        
        $exitCode = Invoke-Elevate -Arguments $elevArgs
        return $exitCode
    }
    
    if (-not $DryRunMode -and -not $Silent) {
        Write-Host ""
        Write-ColorText "  WARNING: This will delete files from System32 and remove registry keys!" -Color $script:Colors.Warning
        if (-not (Read-YesNo -Prompt 'Are you sure you want to continue?')) {
            Write-Status "Uninstall cancelled by user" -Type Info
            return 0
        }
    }
    
    try {
        $matrix = Get-LayoutMatrix
        
        if ($CreateRestorePoint -and -not $DryRunMode) {
            Write-Status "Creating system restore point..." -Type Info
            New-SystemRestorePoint -Description 'MagicKeyboard layouts uninstall'
        }
        
        Write-Status "Removing registry entries..." -Type Info
        $regCount = Uninstall-RegistryEntries -Matrix $matrix -LayoutFilter $LayoutFilter -DryRunMode:$DryRunMode
        
        Write-Status "Deleting layout files from System32..." -Type Info
        $files = Get-FilesToProcess -Matrix $matrix -LayoutFilter $LayoutFilter
        $fileCount = Uninstall-LayoutFiles -Files $files -DryRunMode:$DryRunMode
        
        Write-Host ""
        Write-Header "Uninstall Complete$dryLabel"
        Write-Status "Registry entries removed: $regCount" -Type Success
        Write-Status "Files deleted: $fileCount" -Type Success
        
        return 0
    }
    catch {
        Write-Status "Uninstall failed: $_" -Type Error
        return 1
    }
}

function Invoke-BackupAction {
    Write-Header "Registry Backup"
    
    try {
        $matrix = Get-LayoutMatrix
        
        $stamp = (Get-Date).ToString('yyyyMMddHHmmss')
        $defaultPath = Join-Path $env:TEMP "magickeyboard_backup_$stamp.json"
        
        $outFile = if ($BackupPath) { $BackupPath } else { $defaultPath }
        
        Write-Status "Creating backup..." -Type Info
        $result = New-RegistryBackup -Matrix $matrix -OutFile $outFile -LayoutFilter $null
        
        Write-Host ""
        Write-Status "Backup saved to: $result" -Type Success
        return 0
    }
    catch {
        Write-Status "Backup failed: $_" -Type Error
        return 1
    }
}

function Invoke-RestoreAction {
    Write-Header "Registry Restore"
    
    if (-not (Test-IsElevated)) {
        Write-Status "Requesting elevation..." -Type Info
        $elevArgs = @('-Action', 'Restore', '-BackupPath', $BackupPath)
        if ($Silent) { $elevArgs += '-Silent' }
        if ($Quiet) { $elevArgs += '-Quiet' }
        if ($ShowDetails) { $elevArgs += '-ShowDetails' }
        $elevArgs += '-NoLogo'
        
        return Invoke-Elevate -Arguments $elevArgs
    }
    
    if (-not $BackupPath -or -not (Test-Path $BackupPath)) {
        Write-Status "Please provide a valid backup file path with -BackupPath" -Type Error
        return 1
    }
    
    try {
        Write-Status "Restoring from: $BackupPath" -Type Info
        $count = Restore-RegistryBackup -BackupFile $BackupPath -DryRunMode:$DryRun
        
        Write-Host ""
        Write-Status "Restored $count registry entries" -Type Success
        return 0
    }
    catch {
        Write-Status "Restore failed: $_" -Type Error
        return 1
    }
}

function Show-InstalledLayouts {
    Write-Header "Installed Layouts"
    
    try {
        $matrix = Get-LayoutMatrix
        $translations = Get-Translations
        $installed = @()
        $notInstalled = @()
        
        # Show current locale and translations file being used
        $currentLocale = if ($Locale) { $Locale } else { (Get-UICulture).Name }
        Write-ColorText "  Locale: $currentLocale" -Color $script:Colors.Info
        Write-ColorText "  Translations: $($script:TranslationsJsonPath)" -Color $script:Colors.Info
        Write-Host ""
        
        foreach ($prop in $matrix.PSObject.Properties) {
            $key = $prop.Name
            $entry = $prop.Value
            $regPath = Get-RegistryPath -Entry $entry
            $name = Get-TranslatedName -Key $key -Translations $translations -RequestedLocale $Locale
            
            $regExists = $regPath -and (Test-Path $regPath)
            $dllPath = Join-Path $script:System32 $entry.file
            $dllExists = Test-Path $dllPath
            
            if ($regExists -and $dllExists) {
                $installed += [pscustomobject]@{ Name = $name; Key = $key; File = $entry.file }
            }
            else {
                $notInstalled += [pscustomobject]@{ Name = $name; Key = $key; File = $entry.file }
            }
        }
        
        Write-ColorText "  Installed ($($installed.Count)):" -Color $script:Colors.Success
        foreach ($item in ($installed | Sort-Object -Property Name)) {
            Write-ColorText "    [+] $($item.Name)" -Color $script:Colors.Success
            Write-ColorText "        Key: $($item.Key)  File: $($item.File)" -Color $script:Colors.Info
        }
        
        if ($notInstalled.Count -gt 0) {
            Write-Host ""
            Write-ColorText "  Not Installed ($($notInstalled.Count)):" -Color $script:Colors.Menu
            foreach ($item in ($notInstalled | Sort-Object -Property Name)) {
                Write-ColorText "    [ ] $($item.Name)" -Color $script:Colors.Menu
                Write-ColorText "        Key: $($item.Key)  File: $($item.File)" -Color $script:Colors.Info
            }
        }
    }
    catch {
        Write-Status "Error checking layouts: $_" -Type Error
    }
}

function Show-Help {
    $helpText = @"

MagicKeyboard - Apple Keyboard Layouts Installer for Windows
Version: $($script:Version)

USAGE:
    MagicKeyboard.ps1 [[-Action] <action>] [options]
    MagicKeyboard.ps1 -Help

ACTIONS:
    (none)      Launch interactive TUI menu
    Install     Install keyboard layouts (requires elevation)
    Uninstall   Uninstall keyboard layouts (requires elevation)
    List        List all available layouts and their installation status
    Backup      Backup current registry entries to JSON file
    Restore     Restore registry from a backup file (requires elevation)
    Help        Show this help message

OPTIONS:
    -Layouts <keys>       Comma-separated layout keys to process
                          Example: -Layouts "GermanA,FrenchA,SpanishA"

    -Locale <locale>      Override OS locale for display names
                          Example: -Locale de-DE

    -TranslationsFile <path>  Use custom translations JSON file
                          Example: -TranslationsFile "C:\my_translations.json"

    -BackupPath <path>    Path for backup/restore operations
                          Example: -BackupPath "C:\backup.json"

    -DryRun               Simulate operations without making changes

    -Silent               Run without interactive prompts or progress bars

    -Quiet, -q            Fully silent mode - suppress ALL output
                          Only exit code indicates success (0) or failure (1)

    -ShowDetails, -v      Show detailed progress for each operation
                          Displays checksums, paths, and verification status

    -CreateRestorePoint   Create Windows restore point before changes

    -NoLogo               Suppress the logo banner

    -Help, -h, -?         Show this help message

EXAMPLES:
    # Launch interactive menu
    .\MagicKeyboard.ps1

    # List available layouts (uses OS language)
    .\MagicKeyboard.ps1 -Action List

    # List layouts with German translations
    .\MagicKeyboard.ps1 -Action List -Locale de-DE

    # Install all layouts (will prompt for elevation)
    .\MagicKeyboard.ps1 -Action Install

    # Install specific layouts only
    .\MagicKeyboard.ps1 -Action Install -Layouts "GermanA,FrenchA"

    # Install with detailed progress output
    .\MagicKeyboard.ps1 -Action Install -ShowDetails

    # Dry-run install (no changes made)
    .\MagicKeyboard.ps1 -Action Install -DryRun

    # Dry-run with verbose output
    .\MagicKeyboard.ps1 -Action Install -DryRun -ShowDetails

    # Silent install with restore point
    .\MagicKeyboard.ps1 -Action Install -Silent -CreateRestorePoint

    # Fully silent install (no output, check exit code)
    .\MagicKeyboard.ps1 -Action Install -Quiet

    # Backup registry before manual changes
    .\MagicKeyboard.ps1 -Action Backup -BackupPath "C:\my_backup.json"

    # Restore from backup
    .\MagicKeyboard.ps1 -Action Restore -BackupPath "C:\my_backup.json"

    # Uninstall all layouts
    .\MagicKeyboard.ps1 -Action Uninstall

LAYOUT KEYS:
    BelgiumA, BritishA, CanadaA, ChinaSA, ChinaTA, CzechA, DanishA,
    DutchA, FinnishA, FrenchA, GermanA, HungaryA, IntlEngA, ItalianA,
    NorwayA, PolishA, PortuguA, RussianA, SpanishA, SwedishA, SwissA,
    TurkeyA, TurkeyQA, USA

    Use -Action List to see all layouts with translated names.

"@
    Write-Host $helpText
}

function Main {
    # Handle help request
    if ($Help -or $Action -eq 'Help') {
        Show-Help
        return 0
    }
    
    if ($Action -and $Action -ne 'Menu') {
        $layoutFilter = if ($Layouts) { $Layouts -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } } else { $null }
        
        $result = switch ($Action) {
            'Install' { Invoke-InstallAction -LayoutFilter $layoutFilter -DryRunMode:$DryRun }
            'Uninstall' { Invoke-UninstallAction -LayoutFilter $layoutFilter -DryRunMode:$DryRun }
            'Backup' { Invoke-BackupAction }
            'Restore' { Invoke-RestoreAction }
            'List' { 
                if (-not $NoLogo) { Write-Logo }
                Show-InstalledLayouts
                0
            }
            'GetTranslation' {
                if (-not $Key) {
                    Write-Error "-Key parameter is required for GetTranslation action"
                    $script:MainExitCode = 1
                    return
                } else {
                    $translations = Get-Translations
                    $translatedName = Get-TranslatedName -Key $Key -Translations $translations -RequestedLocale $Locale
                    Write-Output $translatedName
                    $script:MainExitCode = 0
                    return
                }
            }
        }
        
        # Press Enter prompt (unless Silent, Quiet, or GetTranslation action)
        if (-not $Silent -and -not $Quiet -and $Action -ne 'GetTranslation') {
            Show-PausePrompt
        }
        
        return $result
    }
    
    while ($true) {
        $choice = Show-MainMenu
        
        switch ($choice) {
            '1' {
                $null = Invoke-InstallAction -DryRunMode:$false
                Show-PausePrompt
            }
            '2' {
                $null = Invoke-UninstallAction -DryRunMode:$false
                Show-PausePrompt
            }
            '3' {
                Write-Logo
                $null = Invoke-BackupAction
                Show-PausePrompt
            }
            '4' {
                Write-Logo
                Write-Header "Restore from Backup"
                Write-ColorText "  Enter backup file path: " -Color $script:Colors.Menu -NoNewline
                $path = Read-Host
                if ($path -and (Test-Path $path)) {
                    $script:BackupPath = $path
                    $null = Invoke-RestoreAction
                }
                else {
                    Write-Status "Invalid path or file not found" -Type Error
                }
                Show-PausePrompt
            }
            '5' {
                Write-Logo
                Show-InstalledLayouts
                Show-PausePrompt
            }
            '6' {
                Write-Logo
                $null = Invoke-InstallAction -DryRunMode:$true
                Show-PausePrompt
            }
            '7' {
                Write-Logo
                $null = Invoke-UninstallAction -DryRunMode:$true
                Show-PausePrompt
            }
            'Q' {
                Write-Host ""
                Write-ColorText "  Goodbye!" -Color $script:Colors.Title
                Write-Host ""
                return 0
            }
        }
    }
}

# Run main and capture exit code, but let output pass through
$script:MainExitCode = 0
Main | ForEach-Object { $_ }  # Pass through any output
exit $script:MainExitCode

# All Keyboard Layouts (1.0.3.40)

This folder contains the MagicKeyboard installer for Apple-style keyboard layouts on Windows, along with the associated layout DLL files.

## Quick Start

### Interactive Mode (TUI)

Double-click `MagicKeyboard.bat` or run:

```powershell
.\MagicKeyboard.ps1
```

This launches an interactive menu where you can install, uninstall, backup, restore, or view layouts.

![MagicKeyboard TUI](../assets/example-tui.png)

### Command Line

```powershell
# Install all layouts
.\MagicKeyboard.ps1 -Action Install

# Uninstall all layouts  
.\MagicKeyboard.ps1 -Action Uninstall

# List available layouts
.\MagicKeyboard.ps1 -Action List
```

## Files

| File | Description |
|------|-------------|
| `MagicKeyboard.ps1` | Main PowerShell installer with TUI and CLI support |
| `MagicKeyboard.bat` | Simple launcher for the PowerShell script |
| `layouts.json` | Layout definitions (registry keys, DLL filenames, IDs) |
| `translations.json` | Localized layout names for different languages |
| `install_filelist.txt` | List of DLL files to install |
| `install_checksums.txt` | SHA256 checksums for DLL verification |
| `layouts.checksums.json` | JSON checksums for data files |
| `*.dll` | Apple keyboard layout DLL files |

## Actions

| Action | Description |
|--------|-------------|
| `Install` | Install keyboard layouts (registry + DLLs to System32) |
| `Uninstall` | Remove keyboard layouts (registry + DLLs from System32) |
| `Reinstall` | Uninstall then reinstall layouts (refreshes registry and files) |
| `List` | Show all layouts with installation status |
| `Backup` | Save current registry state to JSON file |
| `Restore` | Restore registry from a backup file |
| `GetTranslation` | Get translated layout name for a specific key |
| `Help` | Display help information |

## Command Line Options

### Basic Options

| Option | Description |
|--------|-------------|
| `-Action <action>` | Action to perform: Install, Uninstall, Reinstall, List, Backup, Restore, GetTranslation, Help |
| `-Layouts <keys>` | Comma-separated layout keys to process (e.g., `"GermanA,FrenchA"`) |
| `-Key <key>` | Layout key for GetTranslation action (e.g., `BelgiumA`) |
| `-Help`, `-h`, `-?` | Show help message |

### Localization Options

| Option | Description |
|--------|-------------|
| `-Locale <locale>` | Override OS locale for display names (e.g., `de-DE`, `fr-FR`) |
| `-TranslationsFile <path>` | Use a custom translations JSON file |

### Output Control

| Option | Description |
|--------|-------------|
| `-Silent` | Suppress progress bars and interactive prompts |
| `-Quiet`, `-q` | Fully silent mode - no output at all (check exit code) |
| `-ShowDetails`, `-v` | Show detailed progress (checksums, paths, verification) |
| `-NoLogo` | Suppress the logo banner |

### Safety Options

| Option | Description |
|--------|-------------|
| `-DryRun` | Simulate operations without making any changes |
| `-CreateRestorePoint` | Create Windows restore point before changes |
| `-BackupPath <path>` | Path for backup/restore operations |

## Examples

### Installation

```powershell
# Install all layouts (will prompt for elevation)
.\MagicKeyboard.ps1 -Action Install

# Install specific layouts only
.\MagicKeyboard.ps1 -Action Install -Layouts "GermanA,FrenchA,SpanishA"

# Install with detailed progress
.\MagicKeyboard.ps1 -Action Install -ShowDetails

# Dry-run to preview changes
.\MagicKeyboard.ps1 -Action Install -DryRun

# Dry-run with verbose output
.\MagicKeyboard.ps1 -Action Install -DryRun -ShowDetails

# Silent install with system restore point
.\MagicKeyboard.ps1 -Action Install -Silent -CreateRestorePoint

# Fully silent install (for automation)
.\MagicKeyboard.ps1 -Action Install -Quiet
```

### Uninstallation

```powershell
# Uninstall all layouts
.\MagicKeyboard.ps1 -Action Uninstall

# Uninstall specific layouts
.\MagicKeyboard.ps1 -Action Uninstall -Layouts "GermanA,FrenchA"

# Preview uninstall
.\MagicKeyboard.ps1 -Action Uninstall -DryRun
```

### Reinstallation

```powershell
# Reinstall all layouts (uninstall + install)
.\MagicKeyboard.ps1 -Action Reinstall

# Reinstall specific layouts
.\MagicKeyboard.ps1 -Action Reinstall -Layouts "GermanA,FrenchA"

# Preview reinstall
.\MagicKeyboard.ps1 -Action Reinstall -DryRun
```

### Listing Layouts

```powershell
# List layouts (uses OS language)
.\MagicKeyboard.ps1 -Action List

# List with German translations
.\MagicKeyboard.ps1 -Action List -Locale de-DE

# List with French translations
.\MagicKeyboard.ps1 -Action List -Locale fr-FR
```

### Getting Translated Names

```powershell
# Get translated name for a layout key
.\MagicKeyboard.ps1 -Action GetTranslation -Key BelgiumA -Locale fr-FR
# Output: Belge (Apple)

# Use default system locale
.\MagicKeyboard.ps1 -Action GetTranslation -Key GermanA
# Output: German (Apple)  # or localized based on OS
```

### Backup & Restore

```powershell
# Backup registry to default location (%TEMP%)
.\MagicKeyboard.ps1 -Action Backup

# Backup to specific file
.\MagicKeyboard.ps1 -Action Backup -BackupPath "C:\Backups\keyboard_backup.json"

# Restore from backup
.\MagicKeyboard.ps1 -Action Restore -BackupPath "C:\Backups\keyboard_backup.json"
```

### Automation Examples

```powershell
# Silent install for deployment scripts
.\MagicKeyboard.ps1 -Action Install -Quiet
if ($LASTEXITCODE -eq 0) { Write-Host "Success" } else { Write-Host "Failed" }

# CI/CD dry-run validation
.\MagicKeyboard.ps1 -Action Install -DryRun -Quiet
```

## Available Layout Keys

| Key | Layout |
|-----|--------|
| `BelgiumA` | Belgian (Apple) |
| `BritishA` | British (Apple) |
| `CanadaA` | Canadian (Apple) |
| `ChinaSA` | Chinese Simplified (Apple) |
| `ChinaTA` | Chinese Traditional (Apple) |
| `CzechA` | Czech (Apple) |
| `DanishA` | Danish (Apple) |
| `DutchA` | Dutch (Apple) |
| `FinnishA` | Finnish (Apple) |
| `FrenchA` | French (Apple) |
| `GermanA` | German (Apple) |
| `HungaryA` | Hungarian (Apple) |
| `IntlEngA` | International English (Apple) |
| `ItalianA` | Italian (Apple) |
| `NorwayA` | Norwegian (Apple) |
| `PolishA` | Polish (Apple) |
| `PortuguA` | Portuguese (Apple) |
| `RussianA` | Russian (Apple) |
| `SpanishA` | Spanish (Apple) |
| `SwedishA` | Swedish (Apple) |
| `SwissA` | Swiss (Apple) |
| `TurkeyA` | Turkish (Apple) |
| `TurkeyQA` | Turkish Q (Apple) |
| `USA` | US (Apple) |

Use `-Action List` to see layouts with localized names in your language.

## Auto-Elevation

The installer automatically requests Administrator privileges when needed. Actions that modify the system (Install, Uninstall, Restore) will trigger a UAC prompt if not already running elevated.

All command-line options are preserved when elevating, so you can run:

```powershell
.\MagicKeyboard.ps1 -Action Install -Layouts "GermanA" -ShowDetails
```

...and the elevated process will use the same options.

## Security & Verification

The installer performs security checks before copying files:

1. **Checksum Verification**: SHA256 checksums from `install_checksums.txt` are verified for each DLL
2. **Authenticode Signature**: Digital signatures are checked (warnings shown for unsigned files)

These checks run automatically. Use `-ShowDetails` to see verification status for each file.

## Output Modes

| Mode | Progress Bars | Status Messages | Details |
|------|---------------|-----------------|---------|
| Default | ✓ | ✓ | ✗ |
| `-ShowDetails` | ✓ | ✓ | ✓ |
| `-Silent` | ✗ | ✓ | ✗ |
| `-Quiet` | ✗ | ✗ | ✗ |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error occurred |

## Localization

The installer automatically detects your Windows UI language and displays layout names in your language (if translations are available in `translations.json`).

Supported languages include: English, German, French, Spanish, Italian, Portuguese, Dutch, Polish, Czech, Hungarian, Danish, Finnish, Norwegian, Swedish, Russian, Turkish, Chinese (Simplified & Traditional), and more.

To override the detected locale:

```powershell
.\MagicKeyboard.ps1 -Action List -Locale ja-JP
```

## Troubleshooting

### Layouts not appearing after install

1. Log out and log back in, or restart Windows
2. Check registry: `HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts`
3. Verify DLLs exist in `C:\Windows\System32`

### Permission denied errors

Run the script as Administrator or let auto-elevation handle it.

### Checksum verification failed

The DLL file may be corrupted. Re-download the package or regenerate checksums with:

```bash
scripts/compute_checksums.bat
```

## Legacy Scripts

Previous versions used separate batch files. These have been moved to `legacy_scripts/` for reference but are no longer needed. Use `MagicKeyboard.ps1` instead.

## License & Support

See repository root `readme.md` for license and contact details.

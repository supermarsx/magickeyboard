# All Keyboard Layouts (1.0.3.40)

This folder contains the Windows batch installer and uninstaller for Apple-style keyboard layouts and the associated layout DLL files.

## Files

- `install_keyboard_layouts.bat` — Adds registry entries for each layout and copies the DLLs listed in `install_filelist.txt` to `C:\Windows\System32`. Requires Administrator privileges.
- `uninstall_keyboard_layouts.bat` — Deletes the registry keys and removes the DLLs from `C:\Windows\System32` (based on `install_filelist.txt`). Requires Administrator privileges.
- `install_filelist.txt` — List of layout DLL filenames to copy/delete.

## Usage

1. Right-click `install_keyboard_layouts.bat` and select **Run as administrator**. The installer will add registry keys and copy DLLs into System32.
2. To uninstall, right-click `uninstall_keyboard_layouts.bat` and select **Run as administrator**.

## Automated / Self‑Elevating Installer (added)

This release includes `install_keyboard_layouts_elevated.bat` — a self‑elevating wrapper that automates elevation (UAC) and can run interactively or silently.

Examples (from the `All Keyboard Layouts (1.0.3.40)` directory):

- Interactive install (UAC dialog will appear):

```bat
install_keyboard_layouts_elevated.bat
```

- Silent (unattended) install — does not pause and writes a log to `%TEMP%\magickeyboard_install.log`:

```bat
install_keyboard_layouts_elevated.bat /SILENT
```

- Silent uninstall:

```bat
install_keyboard_layouts_elevated.bat /UNINSTALL /SILENT
```

Subset install / uninstall

You can install or uninstall only a subset of layouts by passing a comma-separated list of layout keys from `layouts.json`:

```bat
install_keyboard_layouts_elevated.bat /LAYOUTS=GermanA,FrenchA
install_keyboard_layouts_elevated.bat /UNINSTALL /LAYOUTS=GermanA,FrenchA
```

Safety switches (optional)

- Create a system restore point before making changes (best-effort; may fail if System Protection is disabled):

```bat
install_keyboard_layouts_elevated.bat /RESTOREPOINT
```

- Backup the registry keys touched by `layouts.json` before making changes:

```bat
install_keyboard_layouts_elevated.bat /REG_BACKUP
install_keyboard_layouts_elevated.bat /REG_BACKUP=C:\temp\magickb_backup.json
```

- Restore the registry keys from a prior backup JSON (does not install/uninstall; runs restore and exits):

```bat
install_keyboard_layouts_elevated.bat /REG_RESTORE=C:\temp\magickb_backup.json
```

Notes:
- The wrapper uses the standard Windows UAC prompt — it cannot automatically bypass elevation without credentials.
- The wrapper sets `MAGIC_SILENT` for called scripts so they run without an interactive pause.

Locale-aware layout titles

The installer now detects the system UI locale and will set the `Layout Text` registry value using a translations file (`translations.json`) shipped with this folder. Translations are looked up by layout key (matching the DLL filename, without extension) and the system UI locale (for example: `fr-FR`, `de-DE`, `es-ES`). If a translated name is not available for the current locale the installer falls back to English (`en`).

PowerShell helper `get_translation.ps1` is used internally by `install_keyboard_layouts.bat` to fetch the most appropriate translated string and write it to the registry.

If you want to add or improve translations, edit `translations.json` and use `scripts/compute_checksums.bat` or `scripts/compute_checksums.sh` to refresh tests.

Security & verification (added):

- A checksum manifest `install_checksums.txt` is included — the installer will require this file and verify the SHA256 checksum for every DLL before copying to `C:\Windows\System32`.
- The installer also performs an Authenticode signature check (via PowerShell) and will refuse to copy unsigned or invalid packages.
 - A checksum manifest `install_checksums.txt` is included — the installer requires this file and verifies the SHA256 checksum for every DLL before copying to `C:\Windows\System32`.
 - The installer also performs an Authenticode signature check (via PowerShell). Signature failures now produce a WARNING but the installer will continue (it will still respect checksum mismatches which remain fatal). You can use `/DRYRUN` to simulate installs without copying files and to validate checks locally.

Log rotation & retention:

- The elevated installer rotates the main logfile (`%TEMP%\magickeyboard_install.log`) when it starts and keeps archived logs for a configurable retention period (default 7 days). Use `/LOG=<path>` and `/LOGR=<days>` to customize.
 - The elevated installer rotates the main logfile (`%TEMP%\magickeyboard_install.log`) when it starts and keeps archived logs for a configurable retention period (default 7 days). Use `/LOG=<path>` and `/LOGR=<days>` to customize.
 - Use `/DRYRUN` to simulate an install/uninstall. DRYRUN will skip registry writes and file copies so you can safely test the process or run CI checks without elevated privileges.

Release creation

- A helper script `scripts/create-release.sh <n>` will package the layouts and create a git tag named `Release-<n>` and, if the `gh` CLI is available and authenticated, create a GitHub release and upload the generated archive. To create "Release 2":

```bash
scripts/create-release.sh 2
```

Windows (PowerShell) usage

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\create-release.ps1 -ReleaseNumber 2
```

This will create an archive under `dist/`, tag the repo as `Release-2`, and attempt to create a GitHub release if the `gh` CLI is present and authenticated.

The script uses `scripts/package_layouts.sh` to create an archive under `dist/` and then tags the repo with `Release-2` (and pushes tags if a remote is present). If you want the release published to GitHub, install and authenticate the `gh` CLI before running the script.

Utility scripts (added):

- `verify_install_filelist.bat` — quick check to ensure all files listed in `install_filelist.txt` are present.

Friendly installer messages & dry-run

- Installer and uninstaller now include clear, friendly start banners, progress messages and a final summary. These are safe to inspect in `/DRYRUN` mode where no writes are performed.
- `install_checksums.txt` — SHA256 checksums for the layout DLLs (used by the installer for verification).
- `install_keyboard_layouts_elevated.bat` — self-elevating installer (documented above)
- `uninstall_keyboard_layouts_elevated.bat` — helper wrapper that elevates and uninstalls
- `verify_install_filelist.bat` — verify presence of files before attempting an install

Maintenance scripts:

- `scripts/compute_checksums.sh` — recompute `install_checksums.txt` from files listed in `install_filelist.txt` (useful when updating DLLs)
- `scripts/package_layouts.sh` — create a distributable zip from this folder (also generates checksums if missing)
- `scripts/verify_install_filelist.bat` — alias for verifying the filelist

## Safety & Troubleshooting

- Always verify DLLs before copying to System32. Replacing System files can break the system.
- If you experience issues adding layouts, run the scripts manually and remove the `>nul 2>&1` redirects to see full error messages.
- Use `regedit` to inspect `HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts` if entries do not appear.

### Quick verification before install

You can verify that every DLL listed in `install_filelist.txt` is present with the bundled helper:

```bat
verify_install_filelist.bat
```

This returns exit code 0 if all files are present, or non-zero when missing files are detected.

## License & Support

See repository root `readme.md` for license and contact details.

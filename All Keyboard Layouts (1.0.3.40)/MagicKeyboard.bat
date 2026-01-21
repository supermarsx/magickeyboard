@echo off
:: MagicKeyboard Launcher
:: Double-click to run the interactive TUI installer
:: Supports passing command-line arguments to the PowerShell script
::
:: Usage:
::   MagicKeyboard.bat                    - Interactive menu
::   MagicKeyboard.bat -Action List       - List all available layouts and installation status
::   MagicKeyboard.bat -Action List -Locale fr-FR  - List with French translations
::   MagicKeyboard.bat -Action Install    - Install all layouts (will request elevation)
::   MagicKeyboard.bat -Action Uninstall  - Uninstall all layouts (will request elevation)
::   MagicKeyboard.bat -Action Install -DryRun   - Simulate install
::   MagicKeyboard.bat -Action Install -Silent   - Silent install (no prompts)
::   MagicKeyboard.bat -Layouts GermanA,FrenchA  - Install specific layouts only
::   MagicKeyboard.bat -Action Backup     - Backup registry entries
::   MagicKeyboard.bat -Action Restore -BackupPath <file>  - Restore from backup
::
:: Note: Layout names are automatically translated based on your OS language,
::       or you can override with -Locale (e.g., -Locale de-DE for German)

title MagicKeyboard - Apple Keyboard Layouts Installer

:: Run the PowerShell TUI script with all arguments forwarded
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0MagicKeyboard.ps1" %*

exit /b %ERRORLEVEL%

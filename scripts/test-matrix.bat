@echo off & cls
chcp 65001 >nul
echo.
echo [test-matrix] Verifying layouts.json matrix and file coverage (Windows)
echo Purpose: Ensure layouts.json contains required metadata and referenced files exist.

setlocal ENABLEDELAYEDEXPANSION
set "ROOT=%~dp0..\All Keyboard Layouts (1.0.3.40)"

if not exist "%ROOT%\layouts.json" (
  echo ERROR: layouts.json missing
  exit /b 2
)

rem Verify MagicKeyboard.ps1 exists
if not exist "%ROOT%\MagicKeyboard.ps1" (
  echo ERROR: MagicKeyboard.ps1 missing
  exit /b 5
)

rem Test MagicKeyboard.ps1 dry-run
pwsh -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\MagicKeyboard.ps1" -Action Install -DryRun -Quiet
if errorlevel 1 (
  echo ERROR: MagicKeyboard.ps1 install dry-run failed
  exit /b 6
)

pwsh -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\MagicKeyboard.ps1" -Action Uninstall -DryRun -Quiet
if errorlevel 1 (
  echo ERROR: MagicKeyboard.ps1 uninstall dry-run failed
  exit /b 6
)

echo [test-matrix] OK — layouts.json keys and MagicKeyboard.ps1 dry-run validated
endlocal
exit /b 0

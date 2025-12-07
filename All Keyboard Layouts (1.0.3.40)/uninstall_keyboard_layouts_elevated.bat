@echo off
cls
REM Purpose:
REM   Small convenience wrapper to uninstall using the elevated installer.
REM   Supports passing through switches to the elevated installer (/DRYRUN, /SILENT, etc.).

REM If we're already elevated, just call uninstall
net session >nul 2>&1
if %errorlevel% neq 0 (
  set "ARGS=/UNINSTALL %*"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~dp0install_keyboard_layouts_elevated.bat' -ArgumentList '%ARGS%' -Verb RunAs"
  exit /b %errorlevel%
)

REM Elevated already
call "%~dp0install_keyboard_layouts_elevated.bat" /UNINSTALL %*

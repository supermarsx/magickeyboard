@echo off
cls
REM Purpose:
REM   Small convenience wrapper to uninstall using the elevated installer.
REM   Supports passing through switches to the elevated installer (/DRYRUN, /SILENT, etc.).

REM If we're already elevated, just call uninstall
net session >nul 2>&1
if %errorlevel% neq 0 (
  rem Preserve all flags and forward them when asking for elevation. Common ones: /DRYRUN /SILENT /UNINSTALL
  set "ARGS=%*"
  rem If caller didn't include /UNINSTALL, ensure it's present
  echo %ARGS% | findstr /I "/UNINSTALL" >nul || set "ARGS=/UNINSTALL %ARGS%"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~dp0install_keyboard_layouts_elevated.bat' -ArgumentList '%ARGS%' -Verb RunAs"
  exit /b %errorlevel%
)

REM Elevated already — forward all args (ensures /DRYRUN, /SILENT are passed through)
call "%~dp0install_keyboard_layouts_elevated.bat" %*

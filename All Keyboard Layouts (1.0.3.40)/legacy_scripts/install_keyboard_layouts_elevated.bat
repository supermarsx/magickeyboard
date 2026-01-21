@echo off & cls

REM ---------------------------------------------------------------------------
REM install_keyboard_layouts_elevated.bat
REM
REM Purpose:
REM   Self-elevating wrapper for install/uninstall of the Apple keyboard layouts.
REM
REM Features:
REM   - Automatically requests UAC elevation (using PowerShell Start-Process -Verb RunAs)
REM   - Supports the following switches when launching this script:
REM       /SILENT    or /S  -> Run without interactive prompts (no pause)
REM       /UNINSTALL or /U  -> Run uninstall flow instead of install
REM       /LOG=<path>       -> Use custom logfile path; default is %TEMP%\magickeyboard_install.log
REM       /DRYRUN            -> Simulate actions (no files copied and no registry writes). Useful for testing.
REM       /RESTOREPOINT      -> Create a system restore point before changes (best-effort).
REM       /REG_BACKUP[=<p>]  -> Backup relevant registry keys before changes.
REM       /REG_RESTORE=<p>   -> Restore registry keys from a prior backup JSON and exit.
REM
REM Behavior:
REM   - If not already running elevated the script will re-launch itself elevated
REM     with the same switches (will prompt UAC once).
REM   - When elevated the wrapper will set MAGIC_SILENT and call the existing
REM     install_keyboard_layouts.bat or uninstall_keyboard_layouts.bat so we
REM     avoid duplicating the registry commands.
REM
REM NOTE: There is no way to bypass UAC programmatically on a stock Windows
REM       machine without credentials. The launcher will show the standard UAC
REM       consent dialog when elevation is required.
REM ---------------------------------------------------------------------------

setlocal enabledelayedexpansion

rem Use the shared parser so elevated and non-elevated wrappers stay in sync
call "%~dp0parse_args.bat" %*

rem PASS_ARGS, MAGIC_SILENT, MAGIC_DRYRUN, MAGIC_LOCALE, MAGIC_LAYOUTS and MODE are set by parse_args.bat

rem --- detect elevation ---
net session >nul 2>&1
if %errorlevel% neq 0 (
  if defined MAGIC_DRYRUN (
    echo Running in DRYRUN mode without elevation (simulation only) ...
    set "MAGIC_DRYRUN=1"
  ) else (
    echo Requesting elevated privileges (UAC prompt) ...
    rem Re-launch with same arguments; ensure full path is used
    set "ARGS=%*"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -ArgumentList '%ARGS%' -Verb RunAs"
    if %errorlevel% neq 0 exit /b %errorlevel%
    exit /b 0
  )
)

rem We're elevated from here on
echo Running elevated: %~f0 %*
echo Log: %LOGFILE%

if defined MAGIC_DRYRUN (
  echo NOTE: running in DRYRUN mode — no files will be copied and registry writes will be simulated.
)

rem Mark scripts as silent if requested
if defined MAGIC_SILENT (
  set "MAGIC_SILENT=1"
) else (
  set "MAGIC_SILENT="
)

if defined MAGIC_DRYRUN (
  set "MAGIC_DRYRUN=1"
) else (
  set "MAGIC_DRYRUN="
)

rem Helper to log
set LOG_DATE=%DATE% %TIME%
echo ----- %LOG_DATE% - %MODE% started ----->> "%LOGFILE%" 2>&1

rem Optional one-shot registry restore mode.
if defined MAGIC_REG_RESTORE (
  if "%MAGIC_REG_RESTORE%"=="1" (
    echo ERROR: /REG_RESTORE requires a file path. Example: /REG_RESTORE=C:\path\backup.json>> "%LOGFILE%" 2>&1
    echo ERROR: /REG_RESTORE requires a file path. Example: /REG_RESTORE=C:\path\backup.json
    exit /b 9
  )
  echo Restoring registry from backup: %MAGIC_REG_RESTORE%>> "%LOGFILE%" 2>&1
  pushd "%~dp0"
  if defined MAGIC_DRYRUN (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore_registry_backup.ps1" -BackupPath "%MAGIC_REG_RESTORE%" -DryRun >> "%LOGFILE%" 2>&1
  ) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore_registry_backup.ps1" -BackupPath "%MAGIC_REG_RESTORE%" >> "%LOGFILE%" 2>&1
  )
  set "RESULT=%ERRORLEVEL%"
  popd
  if %RESULT% neq 0 (
    echo ERROR: registry restore returned exit code %RESULT%>> "%LOGFILE%"
    echo Registry restore failed (see logfile: %LOGFILE%)
    exit /b %RESULT%
  )
  echo Registry restore completed successfully>> "%LOGFILE%"
  if not defined MAGIC_SILENT pause
  endlocal
  exit /b 0
)

if /I "%MODE%"=="INSTALL" (
  echo Performing install...>> "%LOGFILE%" 2>&1
  rem Call the original installer. It will check elevation, but we're elevated.
  pushd "%~dp0"
  rem forward all original args to the inner installer
  call "%~dp0install_keyboard_layouts.bat" %PASS_ARGS% >> "%LOGFILE%" 2>&1
  popd
  set "RESULT=%ERRORLEVEL%"
  if %RESULT% neq 0 (
    echo ERROR: install returned exit code %RESULT%>> "%LOGFILE%"
    echo Install failed (see logfile: %LOGFILE%)
    exit /b %RESULT%
  )
  echo Install completed successfully>> "%LOGFILE%"
  if not defined MAGIC_SILENT pause
  endlocal
  exit /b 0
)

if /I "%MODE%"=="UNINSTALL" (
  echo Performing uninstall...>> "%LOGFILE%" 2>&1
  pushd "%~dp0"
  call "%~dp0uninstall_keyboard_layouts.bat" %PASS_ARGS% >> "%LOGFILE%" 2>&1
  popd
  set "RESULT=%ERRORLEVEL%"
  if %RESULT% neq 0 (
    echo ERROR: uninstall returned exit code %RESULT%>> "%LOGFILE%"
    echo Uninstall failed (see logfile: %LOGFILE%)
    exit /b %RESULT%
  )
  echo Uninstall completed successfully>> "%LOGFILE%"
  if not defined MAGIC_SILENT pause
  endlocal
  exit /b 0
)

echo Unknown mode: %MODE%
endlocal
exit /b 1

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

rem --- parse arguments ---
set "MODE=INSTALL"
set "MAGIC_SILENT_FLAG="
set "LOGFILE=%TEMP%\magickeyboard_install.log"
set "LOG_RETENTION_DAYS=7"

:arg_loop
if "%~1"=="" goto arg_done
  set "arg=%~1"
  set "arg_upper=!arg:~0,6!"
  if /I "!arg:~0,6!"=="/LOGR=" (
    set "LOG_RETENTION_DAYS=%arg:~6%"
    shift
    goto arg_loop
  )
  if /I "!arg:~0,5!"=="/LOG=" (
    set "LOGFILE=%arg:~5%"
    shift
    goto arg_loop
  )
  if /I "%arg%"=="/SILENT" set "MAGIC_SILENT_FLAG=/SILENT" & shift & goto arg_loop
  if /I "%arg%"=="/S" set "MAGIC_SILENT_FLAG=/SILENT" & shift & goto arg_loop
  if /I "%arg%"=="/DRYRUN" set "MAGIC_DRYRUN_FLAG=/DRYRUN" & shift & goto arg_loop
  if /I "%arg%"=="/UNINSTALL" set "MODE=UNINSTALL" & shift & goto arg_loop
  if /I "%arg%"=="/U" set "MODE=UNINSTALL" & shift & goto arg_loop
  rem unknown arg -> ignore
  shift & goto arg_loop
:arg_done

rem --- detect elevation ---
net session >nul 2>&1
if %errorlevel% neq 0 (
  if defined MAGIC_DRYRUN_FLAG (
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
if defined MAGIC_SILENT_FLAG (
  set "MAGIC_SILENT=1"
) else (
  set "MAGIC_SILENT="
)

if defined MAGIC_DRYRUN_FLAG (
  set "MAGIC_DRYRUN=1"
) else (
  set "MAGIC_DRYRUN="
)

rem Rotate old logs and enforce retention
if exist "%LOGFILE%" (
  powershell -NoProfile -Command "try { Rename-Item -LiteralPath '%LOGFILE%' -NewName ('magickeyboard_install_' + (Get-Date -Format 'yyyyMMddHHmmss') + '.log') -ErrorAction Stop } catch { }"
  powershell -NoProfile -Command "Get-ChildItem -Path (Split-Path '%LOGFILE%') -Filter 'magickeyboard_install.log*' | Where-Object { ($_.LastWriteTime -lt (Get-Date).AddDays(-%LOG_RETENTION_DAYS%)) } | Remove-Item -Force -ErrorAction SilentlyContinue"
)

rem Helper to log
set LOG_DATE=%DATE% %TIME%
echo ----- %LOG_DATE% - %MODE% started ----->> "%LOGFILE%" 2>&1

if /I "%MODE%"=="INSTALL" (
  echo Performing install...>> "%LOGFILE%" 2>&1
  rem Call the original installer. It will check elevation, but we're elevated.
  pushd "%~dp0"
  call "%~dp0install_keyboard_layouts.bat" >> "%LOGFILE%" 2>&1
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
  call "%~dp0uninstall_keyboard_layouts.bat" >> "%LOGFILE%" 2>&1
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

@echo OFF & cls & echo.

REM ---------------------------------------------------------------------------
REM uninstall_keyboard_layouts.bat
REM
REM Purpose:
REM   Remove registry entries for installed keyboard layouts and delete the
REM   corresponding DLL files from C:\Windows\System32 (based on install_filelist.txt).
REM
REM How it works:
REM   1) Requires Administrator privileges. Detects elevation via "net session".
REM   2) Deletes the HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts keys
REM      for the layouts installed by the installer script.
REM   3) Deletes DLL files listed in install_filelist.txt from C:\Windows\System32\
REM
REM Usage:
REM   Run as Administrator. To script this unattended use the self-elevating
REM   installer/uninstaller (install_keyboard_layouts_elevated.bat or add an
REM   unattended switch to call this file).
REM
REM Safety & Notes:
REM   - This removes registry keys and deletes files from System32. Only run
REM     if you want these layouts removed. There is no recovery from file deletion
REM     other than restoring from backups.
REM ---------------------------------------------------------------------------

REM If DRYRUN is active, skip elevation check so simulation can be run without admin privileges
if defined MAGIC_DRYRUN (
  echo DRYRUN: skipping elevation check (no admin required in simulation mode)
) else (
  net session >nul 2>&1
  if %errorlevel% neq 0 (
    echo ERROR: Administrator privileges required. Right-click and choose "Run as Administrator".
    echo Exiting...
    echo.
    pause
    exit /b 1
  )
)

echo ================================================================
echo Uninstalling Apple keyboard layouts — Magic Keyboard collection
echo Started at %DATE% %TIME%
echo ================================================================

rem Centralized argument parsing — use the shared helper so flags are consistent
call "%~dp0parse_args.bat" %*

rem parse_args.bat sets: PASS_ARGS, MAGIC_SILENT, MAGIC_DRYRUN, MAGIC_LOCALE, MAGIC_LAYOUTS, MODE

REM Count targets
set "TOTAL=0"
for /F "usebackq tokens=*" %%A in ("install_filelist.txt") do set /a TOTAL+=1
echo Files listed for uninstall: %TOTAL%
set "REMOVED=0"
echo.

REM Detect dry-run (simulated) mode
set "DRYRUN=0"
if defined MAGIC_DRYRUN set "DRYRUN=1"

REM If not silent and not a dry-run, warn user about deleting files from System32
if not defined MAGIC_SILENT if "%DRYRUN%"=="0" (
  echo.
  echo ================================================================
  echo WARNING: This script will DELETE files from C:\Windows\System32 and remove registry keys.
  echo Deleting files from System32 is risky and may break the OS. Proceed only if you are sure.
  echo ================================================================
  echo.
  choice /M "Do you want to continue with the uninstall?" >nul
  if errorlevel 2 (
    echo Uninstall aborted by user
    exit /b 0
  )
)

echo "Removing Registry keys (via layouts.json -> uninstall_registry_from_matrix.ps1)"

if "%DRYRUN%"=="1" (
  set "LAYOUTS_ARG="
  if defined MAGIC_LAYOUTS set "LAYOUTS_ARG=-Layouts \"%MAGIC_LAYOUTS%\""
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall_registry_from_matrix.ps1" -MatrixPath "%~dp0layouts.json" -DryRun %LAYOUTS_ARG%
  if errorlevel 1 (
    echo ERROR: registry dry-run failed
    exit /b 6
  )
) else (
  set "LAYOUTS_ARG="
  if defined MAGIC_LAYOUTS set "LAYOUTS_ARG=-Layouts \"%MAGIC_LAYOUTS%\""
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall_registry_from_matrix.ps1" -MatrixPath "%~dp0layouts.json" %LAYOUTS_ARG%
  if errorlevel 1 (
    echo ERROR: registry uninstall failed
    exit /b 6
  )
)

echo "Deleting copied DLL layout files from system32"
for /F "usebackq tokens=*" %%f in ("install_filelist.txt") do (
  if "%DRYRUN%"=="1" (
    echo DRYRUN: would delete C:\Windows\System32\%%f
    set /a REMOVED+=1
  ) else (
    del "C:\Windows\System32\%%f" >nul 2>&1
    if not errorlevel 1 set /a REMOVED+=1
  )
)

echo.
echo ================================================================
echo Completed uninstall summary:
echo   Files listed: %TOTAL%
echo   Files removed/simulated: %REMOVED%
echo ================================================================
echo "Finished uninstalling layouts"
echo.

REM If MAGIC_SILENT is defined, skip interactive pause (used by automated uninstallers)
if not defined MAGIC_SILENT pause

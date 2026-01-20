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

echo ================================================================
echo Uninstalling Apple keyboard layouts — Magic Keyboard collection
echo Started at %DATE% %TIME%
echo ================================================================

rem Centralized argument parsing — use the shared helper so flags are consistent
call "%~dp0parse_args.bat" %*

rem parse_args.bat sets: PASS_ARGS, MAGIC_SILENT, MAGIC_DRYRUN, MAGIC_LOCALE, MAGIC_LAYOUTS, MAGIC_RESTOREPOINT, MAGIC_REG_BACKUP

REM Detect dry-run (simulated) mode
set "DRYRUN=0"
if defined MAGIC_DRYRUN set "DRYRUN=1"

REM Require elevation unless DRYRUN
if "%DRYRUN%"=="0" (
  net session >nul 2>&1
  if %errorlevel% neq 0 (
    echo ERROR: Administrator privileges required. Right-click and choose "Run as Administrator".
    echo Exiting...
    echo.
    pause
    exit /b 1
  )
) else (
  echo DRYRUN: skipping elevation check (simulation only)
)

REM Optional: create a system restore point before any changes (best-effort)
if defined MAGIC_RESTOREPOINT if "%DRYRUN%"=="0" (
  echo Creating system restore point (best-effort)...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Checkpoint-Computer -Description 'MagicKeyboard layouts uninstall' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; Write-Output 'OK: restore point created' } catch { Write-Warning ('Restore point not created: ' + $_.Exception.Message) }"
)

REM Optional: registry backup (recommended for safety)
set "REG_BACKUP_PATH="
if defined MAGIC_REG_BACKUP (
  if "%MAGIC_REG_BACKUP%"=="1" (
    for /f "tokens=1-4 delims=/:. " %%a in ("%date% %time%") do set "STAMP=%%a%%b%%c%%d"
    set "REG_BACKUP_PATH=%TEMP%\magickeyboard_registry_backup_%STAMP%.json"
  ) else (
    set "REG_BACKUP_PATH=%MAGIC_REG_BACKUP%"
  )
  echo Creating registry backup: %REG_BACKUP_PATH%
  set "LAYOUTS_ARG="
  if defined MAGIC_LAYOUTS set "LAYOUTS_ARG=-Layouts \"%MAGIC_LAYOUTS%\""
  if "%DRYRUN%"=="1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0backup_registry_from_matrix.ps1" -MatrixPath "%~dp0layouts.json" -OutFile "%REG_BACKUP_PATH%" -DryRun %LAYOUTS_ARG%
  ) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0backup_registry_from_matrix.ps1" -MatrixPath "%~dp0layouts.json" -OutFile "%REG_BACKUP_PATH%" %LAYOUTS_ARG%
  )
  if errorlevel 1 (
    echo ERROR: registry backup failed; refusing to continue.
    exit /b 8
  )
)

REM Determine which DLL files to delete based on /LAYOUTS filter
set "FILELIST=install_filelist.txt"
if defined MAGIC_LAYOUTS (
  set "FILELIST=%TEMP%\magickb-uninstall-filelist.txt"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$m=Get-Content -Raw '%~dp0layouts.json' | ConvertFrom-Json; $keys='%MAGIC_LAYOUTS%'.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }; $files=@(); foreach($k in $keys){ if($m.PSObject.Properties.Name -contains $k){ $files += $m.$k.file } else { Write-Error ('Unknown layout key: ' + $k); exit 9 } }; $files | Sort-Object -Unique | Set-Content -Path '%FILELIST%' -Encoding ASCII" >nul 2>&1
  if errorlevel 1 (
    echo ERROR: invalid /LAYOUTS value; expected comma-separated keys from layouts.json (e.g. GermanA,FrenchA)
    exit /b 9
  )
)

REM Count targets (after applying /LAYOUTS filter)
set "TOTAL=0"
for /F "usebackq tokens=*" %%A in ("%FILELIST%") do set /a TOTAL+=1
echo Files listed for uninstall: %TOTAL%
set "REMOVED=0"
echo.

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
for /F "usebackq tokens=*" %%f in ("%FILELIST%") do (
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

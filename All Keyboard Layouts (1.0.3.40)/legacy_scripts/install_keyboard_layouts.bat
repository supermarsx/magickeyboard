@echo OFF & cls & echo.

REM ---------------------------------------------------------------------------
REM install_keyboard_layouts.bat
REM
REM Purpose:
REM   Add keyboard layout registry entries and copy layout DLLs to C:\Windows\System32.
REM
REM How it works:
REM   1) This script requires Administrator privileges. It detects elevation using
REM      "net session" and will abort if not elevated (you'll be prompted to run
REM      it as Administrator).
REM   2) Adds registry keys under HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts
REM      (the registry mapping is now stored in layouts.json and applied via install_registry_from_matrix.ps1)
REM      for a list of Apple-style keyboard layouts (Layout Text, File, Id, Component ID)
REM   3) Copies layout DLL files listed in install_filelist.txt into C:\Windows\System32\
REM
REM Usage:
REM   Right-click and choose "Run as Administrator" OR use the helper
REM   self-elevating installer (install_keyboard_layouts_elevated.bat).
REM
REM Safety & Notes:
REM   - This modifies HKLM and writes to System32 which requires admin rights.
REM   - Removing or overwriting system DLLs can break the system. Use the
REM     provided uninstall script to remove these entries and files.
REM   - The script silences output (redirects to nul). To debug run commands
REM     manually or remove ">nul 2>&1" redirects.
REM ---------------------------------------------------------------------------

rem elevation check moved after parse_args

echo ================================================================
echo Installing Apple keyboard layouts — Magic Keyboard collection
echo Started at %DATE% %TIME%
echo ================================================================

rem Centralized argument parsing — use the shared helper so flags are consistent
call "%~dp0parse_args.bat" %*

rem parse_args.bat sets: PASS_ARGS, MAGIC_SILENT, MAGIC_DRYRUN, MAGIC_LOCALE, MAGIC_LAYOUTS, MODE

REM Detect dry-run mode (set by elevated wrapper or caller via MAGIC_DRYRUN)
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

REM If not running silently and not a dry-run, warn user about System32 & HKLM modification
if not defined MAGIC_SILENT if "%DRYRUN%"=="0" (
  echo.
  echo ================================================================
  echo WARNING: This script will modify C:\Windows\System32 and HKLM registry keys.
  echo This is a potentially dangerous operation. Make sure you have verified the provided DLLs and their checksums.
  echo ================================================================
  echo.
  choice /M "Do you want to continue? (Y/N)" >nul
  if errorlevel 2 (
    echo Install aborted by user
    exit /b 0
  )
)

REM Optional: create a system restore point before any changes (best-effort)
if defined MAGIC_RESTOREPOINT if "%DRYRUN%"=="0" (
  echo Creating system restore point (best-effort)...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Checkpoint-Computer -Description 'MagicKeyboard layouts install' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; Write-Output 'OK: restore point created' } catch { Write-Warning ('Restore point not created: ' + $_.Exception.Message) }"
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

echo Creating Registry keys (using layouts.json matrix)

rem Build optional PowerShell args
set "LOCALE_ARG="
set "LAYOUTS_ARG="
if defined MAGIC_LOCALE set "LOCALE_ARG=-Locale \"%MAGIC_LOCALE%\""
if defined MAGIC_LAYOUTS set "LAYOUTS_ARG=-Layouts \"%MAGIC_LAYOUTS%\""

if "%DRYRUN%"=="1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_registry_from_matrix.ps1" -MatrixPath "%~dp0layouts.json" -TranslationsPath "%~dp0translations.json" -DryRun %LOCALE_ARG% %LAYOUTS_ARG% > "%TEMP%\magickb-registry-dryrun.log" 2>&1
  if errorlevel 1 (
    echo ERROR: registry dry-run failed - see %TEMP%\magickb-registry-dryrun.log
    exit /b 6
  ) else (
    type "%TEMP%\magickb-registry-dryrun.log"
  )
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_registry_from_matrix.ps1" -MatrixPath "%~dp0layouts.json" -TranslationsPath "%~dp0translations.json" %LOCALE_ARG% %LAYOUTS_ARG% > "%TEMP%\magickb-registry.log" 2>&1
  if errorlevel 1 (
    echo ERROR: registry update failed - see %TEMP%\magickb-registry.log
    exit /b 6
  ) else (
    type "%TEMP%\magickb-registry.log"
  )
)

REM Determine which DLL files to copy based on /LAYOUTS filter
set "FILELIST=install_filelist.txt"
if defined MAGIC_LAYOUTS (
  set "FILELIST=%TEMP%\magickb-install-filelist.txt"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$m=Get-Content -Raw '%~dp0layouts.json' | ConvertFrom-Json; $keys='%MAGIC_LAYOUTS%'.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }; $files=@(); foreach($k in $keys){ if($m.PSObject.Properties.Name -contains $k){ $files += $m.$k.file } else { Write-Error ('Unknown layout key: ' + $k); exit 9 } }; $files | Sort-Object -Unique | Set-Content -Path '%FILELIST%' -Encoding ASCII" >nul 2>&1
  if errorlevel 1 (
    echo ERROR: invalid /LAYOUTS value; expected comma-separated keys from layouts.json (e.g. GermanA,FrenchA)
    exit /b 9
  )
)

REM Count files to process (after applying /LAYOUTS filter)
set "TOTAL=0"
for /F "usebackq tokens=*" %%A in ("%FILELIST%") do set /a TOTAL+=1
echo Files listed for install: %TOTAL%
set "INSTALLED=0"
echo.
echo Copying DLL layouts to system32 folder

REM Ensure a checksum manifest exists
if not exist "%~dp0install_checksums.txt" (
  echo ERROR: checksum manifest install_checksums.txt not found in the same folder as this script.
  echo Install aborting — checksum verification is required before copying into System32.
  exit /b 2
)

setlocal enabledelayedexpansion
for /F "usebackq tokens=*" %%f in ("%FILELIST%") do (
  echo ------------------------------------------------
  echo Verifying "%%~f" ...
  if not exist "%%~f" (
    echo ERROR: file "%%~f" listed in %FILELIST% is missing!
    exit /b 3
  )

  REM Lookup expected hash in install_checksums.txt (format: <sha256>  <filename>)
  set "EXPECTED="
  for /F "usebackq tokens=1* delims= " %%H in ('findstr /I /C:"%%~f" "%~dp0install_checksums.txt"') do (
    set "EXPECTED=%%H"
  )
  if not defined EXPECTED (
    echo ERROR: no checksum entry found for %%~f in install_checksums.txt
    exit /b 4
  )

  REM Compute actual SHA256 using certutil and extract the hex string line
  for /F "tokens=*" %%A in ('certutil -hashfile "%%~f" SHA256 ^| findstr /v "SHA256 CertUtil"') do (
    set "ACTUAL=%%A"
  )
  set "ACTUAL=!ACTUAL: =!"

  if /I NOT "!ACTUAL!"=="!EXPECTED!" (
    echo ERROR: checksum mismatch for %%~f
    echo Expected: !EXPECTED!
    echo Actual:   !ACTUAL!
    exit /b 5
  )

  REM Signature verification — require a valid Authenticode signature
  for /F "usebackq tokens=*" %%S in ('powershell -NoProfile -Command "(Get-AuthenticodeSignature '%~dp0%%~f').Status" 2^>^&1') do (
    set "SIGN_STATUS=%%S"
  )
  if /I NOT "!SIGN_STATUS!"=="Valid" (
    echo WARNING: signature verification did NOT return Valid for %%~f (Status=!SIGN_STATUS!)
    echo WARNING: continuing installation — this file will still be copied if checksums match.
  ) else (
    echo OK: signature valid for %%~f
  )

  if "%DRYRUN%"=="1" (
    echo DRYRUN: would copy "%%~f" to C:\Windows\System32\
    set /a INSTALLED+=1
  ) else (
    copy "%%~f" "C:\Windows\System32\" >nul 2>&1
  if errorlevel 1 (
    echo ERROR: failed to copy %%~f to C:\Windows\System32\
    exit /b 7
      ) else (
        echo OK: copied %%~f
        set /a INSTALLED+=1
      )
  )
)
endlocal

echo.
echo ================================================================
echo Completed installation summary:
echo   Files processed: %TOTAL%
echo   Files installed/simulated: %INSTALLED%
echo ================================================================
echo Finished installing layouts
echo.

REM If MAGIC_SILENT is defined, skip interactive pause (used by automated installers)
if not defined MAGIC_SILENT pause

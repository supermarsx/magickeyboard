@echo off
chcp 65001 >nul
echo.
echo [test] Validating layout filelist and checksums (Windows)
REM Purpose:
REM   Execute the Windows test suite: file/checksum validation, translations tests,
REM   matrix integrity checks, and a dry-run using the elevated wrappers and
REM   PowerShell helpers where available.

setlocal ENABLEDELAYEDEXPANSION
set "ROOT=%~dp0..\All Keyboard Layouts (1.0.3.40)"

if not exist "%ROOT%\install_filelist.txt" (
  echo ERROR: install_filelist.txt missing in %ROOT%
  exit /b 2
)
if not exist "%ROOT%\install_checksums.txt" (
  echo ERROR: install_checksums.txt missing in %ROOT% — run compute_checksums.bat
  exit /b 2
)

set "FAILED=0"
for /F "usebackq delims=" %%L in ("%ROOT%\install_filelist.txt") do (
  if "%%L"=="" (goto :continue)
  if not exist "%ROOT%\%%L" (
    echo ERROR: referenced file missing: %%L
    set FAILED=1
    goto :continue
  )
  for /F "usebackq tokens=1,2* delims= " %%H in ('findstr /I /C:" %%L" "%ROOT%\install_checksums.txt"') do (
    set "EXPECTED=%%H"
  )
  if not defined EXPECTED (
    echo ERROR: checksum entry missing for %%L
    set FAILED=1
    goto :continue
  )
  for /f "usebackq tokens=* delims=" %%S in ('powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath '%ROOT%\%%L').Hash"') do set "ACTUAL=%%S"
  if /I not "!ACTUAL!"=="!EXPECTED!" (
    echo ERROR: checksum mismatch for %%L
    echo Expected: !EXPECTED!
    echo Actual:   !ACTUAL!
    set FAILED=1
  )
:continue
)

if %FAILED%==1 (
  echo [test] One or more tests failed
  exit /b 3
)

echo [test] All tests passed
endlocal

REM --- matrix test ---
echo.
echo [test] Running matrix coverage test (Windows)
scripts\test-matrix.bat


REM --- translations test ---
echo.
echo [test] Running translations test (Windows)
scripts\test-translations.bat

REM --- smoke test (dry-run) ---
echo.
echo [test] Running dry-run smoke test (simulated install)
set "MAGIC_DRYRUN=1"
set "MAGIC_SILENT=1"
call "%~dp0..\All Keyboard Layouts (1.0.3.40)\install_keyboard_layouts.bat"
if errorlevel 1 (
  echo [test] Dry-run install returned error: %ERRORLEVEL%
  exit /b 10
)
echo [test] Dry-run simulated install executed successfully

echo.
echo [test] Dry-run via elevated wrapper (no UAC expected) — install_keyboard_layouts_elevated.bat /DRYRUN /SILENT
powershell -NoProfile -Command "& { $p = Start-Process -FilePath '%~dp0..\All Keyboard Layouts (1.0.3.40)\install_keyboard_layouts_elevated.bat' -ArgumentList '/DRYRUN','/SILENT' -NoNewWindow -PassThru -Wait; exit $p.ExitCode }"
if errorlevel 1 (
  echo [test] elevated wrapper dry-run failed with exit code %ERRORLEVEL%
  exit /b 11
)
echo [test] Elevated wrapper dry-run OK

REM --- PowerShell matrix dry-run (Windows) ---
echo.
echo [test] Running PowerShell matrix installer dry-run (Windows)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\All Keyboard Layouts (1.0.3.40)\install_registry_from_matrix.ps1" -MatrixPath "%~dp0..\All Keyboard Layouts (1.0.3.40)\layouts.json" -TranslationsPath "%~dp0..\All Keyboard Layouts (1.0.3.40)\translations.json" -DryRun
if errorlevel 1 (
  echo [test] PowerShell matrix dry-run failed with exit code %ERRORLEVEL%
  exit /b 12
) else (
  echo [test] PowerShell matrix dry-run OK
)

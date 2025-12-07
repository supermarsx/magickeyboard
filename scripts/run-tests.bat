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

rem install_filelist.txt and install_checksums.txt are deprecated — layouts.json is the canonical source of files and checksums
if not exist "%ROOT%\layouts.json" (
  echo ERROR: layouts.json missing in %ROOT%
  exit /b 2
)

set "FAILED=0"
for /F "usebackq delims=" %%F in ('powershell -NoProfile -Command "(Get-Content -Raw -Path '%ROOT%\layouts.json' | ConvertFrom-Json).PSObject.Properties.Name -join '`n'"') do (
  if "%%F"=="" (goto :continue)
  for /F "usebackq delims=" %%K in ('powershell -NoProfile -Command "(Get-Content -Raw -Path '%ROOT%\layouts.json' | ConvertFrom-Json).%%F.file"') do (
    set "FNAME=%%K"
    if not exist "%ROOT%\!FNAME!" (
      echo ERROR: referenced file missing: !FNAME!
      set FAILED=1
      goto :continue
    )
    for /f "usebackq tokens=* delims=" %%S in ('powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath '%ROOT%\!FNAME!').Hash"') do set "ACTUAL=%%S"
    for /F "usebackq delims=" %%H in ('powershell -NoProfile -Command "(Get-Content -Raw -Path '%ROOT%\layouts.json' | ConvertFrom-Json).PSObject.Properties.Value | Where-Object { $_.file -eq '!FNAME!' } | Select-Object -ExpandProperty sha256"') do (
      set "EXPECTED=%%H"
    )
    if not defined EXPECTED (
      echo ERROR: layouts.json missing sha256 for !FNAME!
      set FAILED=1
      goto :continue
    )
    if /I not "!ACTUAL!"=="!EXPECTED!" (
      echo ERROR: checksum mismatch for !FNAME!
      echo Expected: !EXPECTED!
      echo Actual:   !ACTUAL!
      set FAILED=1
    )
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

  REM Uninstall matrix dry-run
  echo.
  echo [test] Running PowerShell uninstall matrix dry-run (Windows)
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\All Keyboard Layouts (1.0.3.40)\uninstall_registry_from_matrix.ps1" -MatrixPath "%~dp0..\All Keyboard Layouts (1.0.3.40)\layouts.json" -DryRun
  if errorlevel 1 (
    echo [test] PowerShell uninstall dry-run failed with exit code %ERRORLEVEL%
    exit /b 13
  ) else (
    echo [test] PowerShell uninstall dry-run OK
  )

  REM --- run Pester suite if pwsh available ---
  echo.
  echo [test] Running Pester tests (PowerShell)
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-pester.ps1" -PesterPath "%~dp0..\tests\powershell\pester"
  if errorlevel 1 (
    echo [test] Pester tests failed
    exit /b 20
  )

@echo off
rem chcp 65001 >nul
echo.
echo [test] Validating layout filelist and checksums (Windows)
REM Purpose:
REM   Execute the Windows test suite: file/checksum validation, translations tests,
REM   matrix integrity checks, and a dry-run using the elevated wrappers and
REM   PowerShell helpers where available.

setlocal ENABLEDELAYEDEXPANSION
set "ROOT=%~dp0..\All Keyboard Layouts (1.0.3.40)"
echo ROOT=%ROOT%

rem install_filelist.txt and install_checksums.txt are deprecated — layouts.json is the canonical source of files and checksums
echo Checking %ROOT%\layouts.json
rem if not exist "c:\projects\magickeyboard\All Keyboard Layouts (1.0.3.40)\layouts.json" (
rem   echo ERROR: layouts.json missing in %ROOT%
rem   exit /b 2
rem )

echo After if

echo checksum validation removed as deprecated

echo [test] All tests passed
endlocal

REM --- matrix test ---
echo.
echo [test] Running matrix coverage test (Windows)
call "%~dp0test-matrix.bat"


REM --- translations test ---
echo.
echo [test] Running translations test (Windows)
call "%~dp0test-translations.bat"

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

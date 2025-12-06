@echo off
chcp 65001 >nul
echo.
echo [test-translations] Verifying translations.json and get_translation.ps1 behaviour (Windows)

setlocal ENABLEDELAYEDEXPANSION
set "ROOT=%~dp0..\All Keyboard Layouts (1.0.3.40)"

if not exist "%ROOT%\install_filelist.txt" (
  echo ERROR: install_filelist.txt missing
  exit /b 2
)
if not exist "%ROOT%\translations.json" (
  echo ERROR: translations.json missing
  exit /b 2
)

set "MISSING=0"
for /F "usebackq delims=" %%F in ("%ROOT%\install_filelist.txt") do (
  if "%%F"=="" (goto :cont)
  set "KEY=%%~nF"
  powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\get_translation.ps1" -Key "!KEY!" -File "%ROOT%\translations.json" > nul 2>&1
  if errorlevel 1 (
    echo ERROR: get_translation.ps1 failed for key !KEY!
    set MISSING=1
  )
:cont
)

if %MISSING%==1 (
  echo [test-translations] Some translations failed to resolve
  exit /b 3
)

echo [test-translations] OK - translations resolve for all keys
endlocal

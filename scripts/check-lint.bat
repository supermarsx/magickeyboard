@echo off
chcp 65001 >nul
echo.
echo [lint] Checking batch header docs and harmful commands (Windows)

setlocal ENABLEDELAYEDEXPANSION
set "FAIL=0"

for %%F in ("All Keyboard Layouts (1.0.3.40)\*.bat") do (
  echo Checking %%~nxF ...
  findstr /I /C:"Purpose:" "%%~fF" >nul
  if errorlevel 1 (
    echo ERROR: %%~nxF is missing a 'Purpose:' header
    set FAIL=1
  )
  findstr /R /C:"del\s\+C:\\Windows\\System32" "%%~fF" >nul
  if not errorlevel 1 (
    echo ERROR: %%~nxF contains direct deletions in System32 — please review
    set FAIL=1
  )
)

if %FAIL%==1 (
  echo [lint] One or more checks failed.
  exit /b 1
)

echo [lint] OK
endlocal

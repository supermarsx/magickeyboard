@echo off
chcp 65001 >nul
echo.
echo [format] Checking .bat files for trailing whitespace and final newline (Windows)
REM Purpose:
REM   Ensure batch files follow formatting rules (no trailing whitespace, end with newline).
REM   This helps avoid accidental formatting changes and ensures consistent diffs.

setlocal ENABLEDELAYEDEXPANSION
set "FAIL=0"

for /R "." %%F in (*.bat) do (
  if exist "%%~fF" (
    echo Checking %%~nxF
    rem trailing spaces check
    powershell -NoProfile -Command "if ((Get-Content -Path '%%~fF' | Where-Object { $_ -match '\s$' }).Count -gt 0) { exit 1 } else { exit 0 }" >nul 2>&1
    if errorlevel 1 (
      echo ERROR: %%~nxF contains trailing whitespace
      set FAIL=1
    )
    rem final newline check — ensure file ends with newline by checking last char (CRLF)
    for /f "usebackq tokens=*" %%L in ('powershell -NoProfile -Command "(Get-Content -Raw -Path '%%~fF' -Encoding UTF8)[-1] -ne '\n'"') do (
      if "%%L"=="True" (
        echo ERROR: %%~nxF does not end with a newline
        set FAIL=1
      )
    )
  )
)

if %FAIL%==1 (
  echo [format] Issues found
  exit /b 1
)

echo [format] OK
endlocal

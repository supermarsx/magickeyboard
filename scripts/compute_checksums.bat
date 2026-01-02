@echo off
chcp 65001 >nul
echo.
echo [compute] Building SHA256 checksum manifest for layout files (Windows)
REM Purpose:
REM   Generate install_checksums.txt (SHA256) for the files listed in install_filelist.txt.
REM   This is used to validate files before copying to System32 during installation.

setlocal ENABLEDELAYEDEXPANSION
set "ROOT=%~dp0..\All Keyboard Layouts (1.0.3.40)"
if not exist "%ROOT%\layouts.json" (
  echo ERROR: layouts.json not found; please use layouts.json as the authoritative source for file/checksum info
  exit /b 2
)

pushd "%ROOT%"
del /Q layouts.checksums.json >nul 2>&1
echo { > layouts.checksums.json
set first=1
for %%F in (*.dll) do (
  for /f "tokens=* delims=" %%H in ('powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath '%%F').Hash"') do set "ACTUAL=%%H"
  if !first!==1 (
    set first=0
  ) else (
    echo ,>>layouts.checksums.json
  )
  echo   "%%F": "!ACTUAL!">>layouts.checksums.json
)
echo }>>layouts.checksums.json
popd

echo [compute] Wrote helper JSON: %ROOT%\layouts.checksums.json (merge into layouts.json if desired)
endlocal

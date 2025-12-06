@echo off
chcp 65001 >nul
echo.
echo [compute] Building SHA256 checksum manifest for layout files (Windows)

setlocal ENABLEDELAYEDEXPANSION
set "ROOT=%~dp0..\All Keyboard Layouts (1.0.3.40)"
if not exist "%ROOT%\install_filelist.txt" (
  echo ERROR: install_filelist.txt not found in %ROOT%
  exit /b 2
)

pushd "%ROOT%"
del /Q install_checksums.txt >nul 2>&1
for /F "usebackq delims=" %%F in ("install_filelist.txt") do (
  if "%%F"=="" (goto :cont)
  if exist "%%F" (
    for /f "tokens=* delims= " %%H in ('powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath '%%F').Hash"') do (
      echo %%H  %%F>>install_checksums.txt
    )
  ) else (
    echo WARN: skipping missing file %%F
  )
:cont
)
popd

echo [compute] Wrote manifest: %ROOT%\install_checksums.txt
endlocal

@echo off
cls
REM Purpose:
REM   Quick verification helper — checks all files listed in install_filelist.txt exist in this folder.
echo NOTE: install_filelist.txt is deprecated. Verifying files referenced in layouts.json exist in this folder

set "MISSING=0"

for /F "usebackq delims=" %%K in ('powershell -NoProfile -Command "(Get-Content -Raw -Path '%~dp0layouts.json' | ConvertFrom-Json).PSObject.Properties.Value | ForEach-Object { $_.file } -join '`n'"') do (
  if exist "%%~fK" (
    echo OK: %%~fK
  ) else (
    echo MISSING: %%~fK
    set "MISSING=1"
  )
)

if "%MISSING%"=="1" (
  echo One or more files are missing. Please ensure the layout DLLs are present.
  exit /b 2
)

echo All files referenced in layouts.json are present.
exit /b 0

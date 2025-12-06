@echo off
cls
REM Purpose:
REM   Quick verification helper — checks all files listed in install_filelist.txt exist in this folder.
echo Verifying install_filelist.txt files exist in the current folder

set "MISSING=0"

for /F "usebackq tokens=*" %%F in ("install_filelist.txt") do (
  if exist "%%~fF" (
    echo OK: %%~fF
  ) else (
    echo MISSING: %%~fF
    set "MISSING=1"
  )
)

if "%MISSING%"=="1" (
  echo One or more files are missing. Please ensure the layout DLLs are present.
  exit /b 2
)

echo All files listed in install_filelist.txt are present.
exit /b 0

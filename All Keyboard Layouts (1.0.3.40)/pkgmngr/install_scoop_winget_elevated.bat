@echo off
REM Purpose: Silent Scoop/Winget install wrapper (drivers + layouts).

setlocal ENABLEDELAYEDEXPANSION
set "PSARGS=-Action Install"

for %%A in (%*) do (
  if /I "%%~A"=="/S" set "PSARGS=!PSARGS! -Silent"
  if /I "%%~A"=="/SILENT" set "PSARGS=!PSARGS! -Silent"
  if /I "%%~A"=="/DRYRUN" set "PSARGS=!PSARGS! -DryRun"
  if /I "%%~A"=="/SKIP_ELEVATION" set "PSARGS=!PSARGS! -SkipElevation"
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0ScoopWingetInstaller.ps1" !PSARGS!
exit /b %ERRORLEVEL%

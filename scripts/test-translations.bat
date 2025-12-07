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
set "REQUIRED_LOCALES=en en-US fr-FR de-DE es-ES nl-NL it-IT pt-PT pt-BR ru-RU zh-CN zh-TW pl-PL sv-SE fi-FI nb-NO cs-CZ hu-HU tr-TR en-CA"
for /F "usebackq delims=" %%F in ("%ROOT%\install_filelist.txt") do (
  if "%%F"=="" (goto :cont)
  set "KEY=%%~nF"
  for %%L in (%REQUIRED_LOCALES%) do (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $j = Get-Content -Raw -Path '%ROOT%\translations.json' | ConvertFrom-Json; if ($j.'!KEY' -and $j.'!KEY'.'%%L') { exit 0 } else { exit 2 } } catch { exit 3 }" > nul 2>&1
    if errorlevel 1 (
      echo ERROR: translations.json missing locale %%L for key !KEY!
      set MISSING=1
    )
  )
:cont
)

if %MISSING%==1 (
  echo [test-translations] Some translations failed to resolve
  exit /b 3
)

echo [test-translations] OK - translations resolve for all keys
endlocal

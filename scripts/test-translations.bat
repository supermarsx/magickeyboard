@echo off
chcp 65001 >nul
echo.
echo [test-translations] Verifying translations.json and get_translation.ps1 behaviour (Windows)
echo Purpose: Ensure translations.json contains the REQUIRED_LOCALES for each layout
echo          and that translation values are non-empty and not placeholders.

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
set "MISSING_LOCALES=0"
set "EMPTY_VALUES=0"
set "PLACEHOLDERS=0"
set "REQUIRED_LOCALES=en en-US fr-FR de-DE es-ES nl-NL it-IT pt-PT pt-BR ru-RU zh-CN zh-TW pl-PL sv-SE fi-FI nb-NO cs-CZ hu-HU tr-TR en-CA"

for /F "usebackq delims=" %%K in (`powershell -NoProfile -Command "(Get-Content -Raw -Path '%ROOT%\layouts.json' | ConvertFrom-Json).PSObject.Properties.Name -join '`n'"`) do (
  if "%%K"=="" (goto :cont)
  set "KEY=%%K"
  for %%L in (%REQUIRED_LOCALES%) do (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $j = Get-Content -Raw -Path '%ROOT%\\translations.json' | ConvertFrom-Json; if ($j.'!KEY' -and $j.'!KEY'.'%%L') { $v = $j.'!KEY'.'%%L'; if ([string]::IsNullOrWhiteSpace($v)) { exit 4 } elseif ($v -eq '!KEY') { exit 5 } else { exit 0 } } else { exit 2 } } catch { exit 3 }" > nul 2>&1
    if errorlevel 5 (
      echo ERROR: translations.json has placeholder (key name) for locale %%L in key !KEY!
      set MISSING=1
      set /a PLACEHOLDERS+=1
    ) else if errorlevel 4 (
      echo ERROR: translations.json has empty translation for locale %%L in key !KEY!
      set MISSING=1
      set /a EMPTY_VALUES+=1
    ) else if errorlevel 1 (
      echo ERROR: translations.json missing locale %%L for key !KEY!
      set MISSING=1
      set /a MISSING_LOCALES+=1
    )
  )
:cont
)

if %MISSING%==1 (
  echo [test-translations] FAILED - %MISSING% issues found
  echo   Missing locales: %MISSING_LOCALES%
  echo   Empty values: %EMPTY_VALUES%
  echo   Placeholder values: %PLACEHOLDERS%
  exit /b 3
)

echo [test-translations] OK - translations resolve for all keys (no empty/placeholders)
endlocal

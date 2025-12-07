@echo off
chcp 65001 >nul
echo.
echo [test-matrix] Verifying layouts.json matrix matches install_filelist.txt and required properties (Windows)
echo Purpose: Ensure layouts.json is in sync with install_filelist.txt and that each
echo          matrix entry contains required properties (file and reg_key). This
echo          prevents mismatch between the registry mapping and the file list.

setlocal ENABLEDELAYEDEXPANSION
set "ROOT=%~dp0..\All Keyboard Layouts (1.0.3.40)"

if not exist "%ROOT%\layouts.json" (
  echo ERROR: layouts.json missing
  exit /b 2
)
if not exist "%ROOT%\install_filelist.txt" (
  echo ERROR: install_filelist.txt missing
  exit /b 2
)

set MISSING=0
set MISSING_KEYS=0
set MISSING_PROPS=0

powershell -NoProfile -Command "try { Get-Content -Raw -Path '%ROOT%\layouts.json' | ConvertFrom-Json | Out-Null; exit 0 } catch { exit 3 }" >nul 2>&1
if errorlevel 1 (
  echo ERROR: layouts.json invalid JSON
  exit /b 3
)

for /F "usebackq delims=" %%F in ("%ROOT%\install_filelist.txt") do (
  if "%%F"=="" (goto :cont)
  set "KEY=%%~nF"
  powershell -NoProfile -Command "try { $j = Get-Content -Raw -Path '%ROOT%\layouts.json' | ConvertFrom-Json; if ($j.'!KEY') { exit 0 } else { exit 2 } } catch { exit 3 }" > nul 2>&1
  if errorlevel 1 (
    echo ERROR: layouts.json is missing entry for %%F (key=!KEY!)
    set /a MISSING+=1
    set /a MISSING_KEYS+=1
  ) else (
    rem check for required properties (file, reg_key)
    for %%P in (file reg_key) do (
      powershell -NoProfile -Command "try { $j = Get-Content -Raw -Path '%ROOT%\layouts.json' | ConvertFrom-Json; if ($j.'!KEY'.'%%P') { exit 0 } else { exit 2 } } catch { exit 3 }" > nul 2>&1
      if errorlevel 1 (
        echo ERROR: layouts.json.!KEY! missing property %%P
        set /a MISSING+=1
        set /a MISSING_PROPS+=1
      )
    )
  )
:cont
)

if %MISSING% neq 0 (
  echo [test-matrix] FAILED - %MISSING% problems (missing keys: %MISSING_KEYS%, missing props: %MISSING_PROPS%)
  exit /b 4
)

echo [test-matrix] OK - layouts.json has entries for all files in install_filelist.txt
endlocal
exit /b 0

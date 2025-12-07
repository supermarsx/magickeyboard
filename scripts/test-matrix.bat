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
    rem check for required properties (file, reg_key, reg_path)
    for %%P in (file reg_key reg_path) do (
      powershell -NoProfile -Command "try { $j = Get-Content -Raw -Path '%ROOT%\layouts.json' | ConvertFrom-Json; if ($j.'!KEY'.'%%P') { exit 0 } else { exit 2 } } catch { exit 3 }" > nul 2>&1
      if errorlevel 1 (
        echo ERROR: layouts.json.!KEY! missing property %%P
        set /a MISSING+=1
        set /a MISSING_PROPS+=1
      ) else (
        if /I "%%P"=="reg_path" (
          powershell -NoProfile -Command "try { $j=Get-Content -Raw -Path '%ROOT%\layouts.json' | ConvertFrom-Json; $v=$j.'!KEY'.'reg_path'; if (-not $v) { exit 4 } elseif ($v -notmatch '^(HKLM:|HKLM\\\\|HKLM\\)') { exit 5 } else { exit 0 } } catch { exit 6 }" > nul 2>&1
          if errorlevel 6 (
            echo ERROR: layouts.json.!KEY! reg_path invalid JSON lookup
            set /a MISSING+=1
            set /a MISSING_PROPS+=1
          ) else if errorlevel 5 (
            echo ERROR: layouts.json.!KEY! reg_path does not look like a HKLM path
            set /a MISSING+=1
            set /a MISSING_PROPS+=1
          ) else if errorlevel 4 (
            echo ERROR: layouts.json.!KEY! reg_path is empty
            set /a MISSING+=1
            set /a MISSING_PROPS+=1
          )
        )
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

REM Verify the install/uninstall .bat files use the matrix-based powershell helpers
if exist "%ROOT%\install_keyboard_layouts.bat" (
  findstr /I /C:"install_registry_from_matrix.ps1" "%ROOT%\install_keyboard_layouts.bat" > nul
  if errorlevel 1 (
    echo ERROR: install_keyboard_layouts.bat does not call install_registry_from_matrix.ps1
    set /a MISSING+=1
  )
)
if exist "%ROOT%\uninstall_keyboard_layouts.bat" (
  findstr /I /C:"uninstall_registry_from_matrix.ps1" "%ROOT%\uninstall_keyboard_layouts.bat" > nul
  if errorlevel 1 (
    echo ERROR: uninstall_keyboard_layouts.bat does not call uninstall_registry_from_matrix.ps1
    set /a MISSING+=1
  )
)

if %MISSING% neq 0 (
  echo [test-matrix] FAILED due to missing installer hooks
  exit /b 4
)

echo [test-matrix] Verified installer wrappers call PowerShell matrix helpers
endlocal
exit /b 0

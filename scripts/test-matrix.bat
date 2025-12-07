@echo off & cls
chcp 65001 >nul
echo.
echo [test-matrix] Verifying layouts.json matrix and file coverage (Windows)
echo Purpose: Ensure layouts.json contains required metadata and referenced files exist.

setlocal ENABLEDELAYEDEXPANSION
set "ROOT=%~dp0..\All Keyboard Layouts (1.0.3.40)"

if not exist "%ROOT%\layouts.json" (
  echo ERROR: layouts.json missing
  exit /b 2
)

powershell -NoProfile -Command "try { $j=Get-Content -Raw -Path '%ROOT%\layouts.json' | ConvertFrom-Json; foreach ($k in $j.PSObject.Properties.Name) { $entry=$j.$k; if (-not $entry.file) { Write-Host 'MISSING-FILEPROP:' $k; exit 1 }; if (-not (Test-Path (Join-Path '%ROOT%' $entry.file))) { Write-Host 'MISSING-FILE:' $entry.file; exit 2 } }; exit 0 } catch { exit 3 }" >nul 2>&1
if errorlevel 1 (
  echo ERROR: layouts.json validation failed (missing file/property)
  exit /b 4
)

rem Verify the install/uninstall .bat files reference the matrix helpers
if exist "%ROOT%\install_keyboard_layouts.bat" (
  findstr /I /C:"install_registry_from_matrix.ps1" "%ROOT%\install_keyboard_layouts.bat" > nul
  if errorlevel 1 (
    echo ERROR: install_keyboard_layouts.bat does not reference install_registry_from_matrix.ps1
    exit /b 5
  )
)
if exist "%ROOT%\uninstall_keyboard_layouts.bat" (
  findstr /I /C:"uninstall_registry_from_matrix.ps1" "%ROOT%\uninstall_keyboard_layouts.bat" > nul
  if errorlevel 1 (
    echo ERROR: uninstall_keyboard_layouts.bat does not reference uninstall_registry_from_matrix.ps1
    exit /b 6
  )
)

rem Dry-run counts: ensure the matrix helpers report one create/delete per actionable entry
powershell -NoProfile -Command "try { $j=Get-Content -Raw -Path '%ROOT%\layouts.json' | ConvertFrom-Json; $actionable=0; foreach ($v in $j.PSObject.Properties.Value) { if (($v.PSObject.Properties.Name -contains 'reg_path' -and $v.reg_path) -or ($v.PSObject.Properties.Name -contains 'reg_key' -and $v.reg_key)) { $actionable++ } }; $out=& '%ROOT%\install_registry_from_matrix.ps1' -MatrixPath '%ROOT%\layouts.json' -TranslationsPath '%ROOT%\translations.json' -DryRun; if (($out | Select-String -Pattern 'DRYRUN: would create registry key').Count -ne $actionable) { Write-Host 'DRYRUN-CREATE-MISMATCH'; exit 7 }; $out2=& '%ROOT%\uninstall_registry_from_matrix.ps1' -MatrixPath '%ROOT%\layouts.json' -DryRun; if (($out2 | Select-String -Pattern 'DRYRUN: would delete registry key').Count -ne $actionable) { Write-Host 'DRYRUN-DELETE-MISMATCH'; exit 7 }; exit 0 } catch { exit 8 }" >nul 2>&1
if errorlevel 7 (
  echo ERROR: install/uninstall dry-run message count mismatch
  exit /b 7
) else if errorlevel 8 (
  echo ERROR: dry-run message check failed due to PowerShell/JSON error
  exit /b 8
)

echo [test-matrix] OK — layouts.json keys and file coverage validated
endlocal
exit /b 0

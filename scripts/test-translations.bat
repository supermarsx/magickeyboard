@echo off
setlocal
chcp 65001 >nul
echo.
echo [test-translations] Validating translations.json (PowerShell)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0test-translations.ps1"
exit /b %ERRORLEVEL%

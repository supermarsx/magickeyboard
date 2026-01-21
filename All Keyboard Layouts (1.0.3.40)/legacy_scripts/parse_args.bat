@echo off
rem parse_args.bat
rem Purpose: Shared argument parser for the Windows installer/uninstaller wrappers.
rem Usage: call "%~dp0parse_args.bat" %*

rem Clear any previously set flags to avoid leaking between calls
set "PASS_ARGS="
set "MAGIC_SILENT="
set "MAGIC_DRYRUN="
set "MAGIC_LOCALE="
set "MAGIC_LAYOUTS="
set "MAGIC_RESTOREPOINT="
set "MAGIC_REG_BACKUP="
set "MAGIC_REG_RESTORE="
set "MODE=INSTALL"
set "LOGFILE=%TEMP%\magickeyboard_install.log"
set "LOG_RETENTION_DAYS=7"

:arg_loop
if "%~1"=="" goto arg_done
  set "arg=%~1"
  rem preserve all args for passthrough to inner installer
  if defined PASS_ARGS ( set "PASS_ARGS=%PASS_ARGS% %arg%" ) else ( set "PASS_ARGS=%arg%" )

  if /I "%arg:~0,6%"=="/LOGR=" (
    set "LOG_RETENTION_DAYS=%arg:~6%"
    shift
    goto arg_loop
  )
  if /I "%arg:~0,5%"=="/LOG=" (
    set "LOGFILE=%arg:~5%"
    shift
    goto arg_loop
  )
  if /I "%arg%"=="/SILENT" (
    set "MAGIC_SILENT=1" & shift & goto arg_loop
  )
  if /I "%arg%"=="/S" (
    set "MAGIC_SILENT=1" & shift & goto arg_loop
  )
  if /I "%arg%"=="/DRYRUN" (
    set "MAGIC_DRYRUN=1" & shift & goto arg_loop
  )
  if /I "%arg%"=="/RESTOREPOINT" (
    set "MAGIC_RESTOREPOINT=1" & shift & goto arg_loop
  )
  if /I "%arg%"=="/RP" (
    set "MAGIC_RESTOREPOINT=1" & shift & goto arg_loop
  )
  if /I "%arg:~0,8%"=="/LOCALE=" (
    set "MAGIC_LOCALE=%arg:~8%" & shift & goto arg_loop
  )
  if /I "%arg:~0,9%"=="/LAYOUTS=" (
    set "MAGIC_LAYOUTS=%arg:~9%" & shift & goto arg_loop
  )
  if /I "%arg%"=="/REG_BACKUP" (
    rem Flag only; caller may choose a default path
    set "MAGIC_REG_BACKUP=1" & shift & goto arg_loop
  )
  if /I "%arg:~0,12%"=="/REG_BACKUP=" (
    set "MAGIC_REG_BACKUP=%arg:~12%" & shift & goto arg_loop
  )
  if /I "%arg%"=="/REG_RESTORE" (
    set "MAGIC_REG_RESTORE=1" & shift & goto arg_loop
  )
  if /I "%arg:~0,13%"=="/REG_RESTORE=" (
    set "MAGIC_REG_RESTORE=%arg:~13%" & shift & goto arg_loop
  )
  if /I "%arg%"=="/UNINSTALL" (
    set "MODE=UNINSTALL" & shift & goto arg_loop
  )
  if /I "%arg%"=="/U" (
    set "MODE=UNINSTALL" & shift & goto arg_loop
  )
  rem unknown arg preserved in PASS_ARGS
  shift & goto arg_loop
:arg_done

rem End of parser — variables set in the caller's environment when using CALL

rem --- rotate logs and enforce retention (centralized)
if exist "%LOGFILE%" (
  powershell -NoProfile -Command "try { Rename-Item -LiteralPath '%LOGFILE%' -NewName ('magickeyboard_install_' + (Get-Date -Format 'yyyyMMddHHmmss') + '.log') -ErrorAction Stop } catch { }"
  powershell -NoProfile -Command "Get-ChildItem -Path (Split-Path '%LOGFILE%') -Filter 'magickeyboard_install.log*' | Where-Object { ($_.LastWriteTime -lt (Get-Date).AddDays(-%LOG_RETENTION_DAYS%)) } | Remove-Item -Force -ErrorAction SilentlyContinue"
)

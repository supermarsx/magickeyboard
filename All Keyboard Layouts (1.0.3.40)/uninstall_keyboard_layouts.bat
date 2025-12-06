@echo OFF & cls & echo.

REM ---------------------------------------------------------------------------
REM uninstall_keyboard_layouts.bat
REM
REM Purpose:
REM   Remove registry entries for installed keyboard layouts and delete the
REM   corresponding DLL files from C:\Windows\System32 (based on install_filelist.txt).
REM
REM How it works:
REM   1) Requires Administrator privileges. Detects elevation via "net session".
REM   2) Deletes the HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts keys
REM      for the layouts installed by the installer script.
REM   3) Deletes DLL files listed in install_filelist.txt from C:\Windows\System32\
REM
REM Usage:
REM   Run as Administrator. To script this unattended use the self-elevating
REM   installer/uninstaller (install_keyboard_layouts_elevated.bat or add an
REM   unattended switch to call this file).
REM
REM Safety & Notes:
REM   - This removes registry keys and deletes files from System32. Only run
REM     if you want these layouts removed. There is no recovery from file deletion
REM     other than restoring from backups.
REM ---------------------------------------------------------------------------

net session >nul 2>&1
if %errorlevel% neq 0 (
  echo ERROR: Administrator privileges required. Right-click and choose "Run as Administrator".
  echo Exiting...
  echo.
  pause
  exit /b 1
)

echo "Uninstalling Keyboard Layouts"

echo "Removing Registry keys"
REM Removing Belgian Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000813" /f >nul 2>&1

REM Removing British Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000809" /f >nul 2>&1

REM Removing Canadian Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000c0c" /f >nul 2>&1

REM Removing Danish Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000406" /f >nul 2>&1

REM Removing Dutch Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000413" /f >nul 2>&1

REM Removing Finnish Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040b" /f >nul 2>&1

REM Removing French Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040c" /f >nul 2>&1

REM Removing German Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000407" /f >nul 2>&1

REM Removing Italian Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000410" /f >nul 2>&1

REM Removing Norwegian Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000414" /f >nul 2>&1

REM Removing Polish Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000415" /f >nul 2>&1

REM Removing Portuguese Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000416" /f >nul 2>&1

REM Removing Russian Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000419" /f >nul 2>&1

REM Removing Spanish Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040a" /f >nul 2>&1

REM Removing Swedish Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041d" /f >nul 2>&1

REM Removing Swiss Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000100c" /f >nul 2>&1

REM Removing International English Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0020409" /f >nul 2>&1

REM Removing USA Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000409" /f >nul 2>&1

REM Removing Chinese Traditional Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\00000404" /f >nul 2>&1

REM Removing Chinese Standard Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\00000804" /f >nul 2>&1

REM Removing Turkish Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a100041f" /f >nul 2>&1

REM Removing Turkish Q Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041f" /f >nul 2>&1

REM Removing Czech Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000405" /f >nul 2>&1

REM Removing Hungarian Layout
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040e" /f >nul 2>&1

echo "Deleting copied DLL layout files from system32"
for /F "usebackq tokens=*" %%f in ("install_filelist.txt") do del "C:\Windows\System32\%%f" >nul 2>&1

echo "Finished uninstalling layouts"
echo.

REM If MAGIC_SILENT is defined, skip interactive pause (used by automated uninstallers)
if not defined MAGIC_SILENT pause

@echo OFF & cls & echo.

REM ---------------------------------------------------------------------------
REM install_keyboard_layouts.bat
REM
REM Purpose:
REM   Add keyboard layout registry entries and copy layout DLLs to C:\Windows\System32.
REM
REM How it works:
REM   1) This script requires Administrator privileges. It detects elevation using
REM      "net session" and will abort if not elevated (you'll be prompted to run
REM      it as Administrator).
REM   2) Adds registry keys under HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts
REM      for a list of Apple-style keyboard layouts (Layout Text, File, Id, Component ID)
REM   3) Copies layout DLL files listed in install_filelist.txt into C:\Windows\System32\
REM
REM Usage:
REM   Right-click and choose "Run as Administrator" OR use the helper
REM   self-elevating installer (install_keyboard_layouts_elevated.bat).
REM
REM Safety & Notes:
REM   - This modifies HKLM and writes to System32 which requires admin rights.
REM   - Removing or overwriting system DLLs can break the system. Use the
REM     provided uninstall script to remove these entries and files.
REM   - The script silences output (redirects to nul). To debug run commands
REM     manually or remove ">nul 2>&1" redirects.
REM ---------------------------------------------------------------------------

net session >nul 2>&1
if %errorlevel% neq 0 (
  echo ERROR: Administrator privileges required. Right-click and choose "Run as Administrator".
  echo Exiting...
  echo.
  pause
  exit /b 1
)

echo Installing Keyboard Layouts

echo Creating Registry keys
REM Helper function: retrieve a translated layout text string
:get_layout_text
rem Usage: call :get_layout_text <jsonKey> <EnvVarName>
setlocal enabledelayedexpansion
set "JSONKEY=%~1"
set "ENVNAME=%~2"
for /F "usebackq delims=" %%L in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0get_translation.ps1" -Key "%JSONKEY%" -File "%~dp0translations.json" 2^>^&1`) do (
  endlocal & set "%ENVNAME%=%%L"
)
if not defined %ENVNAME% (
  echo ERROR: Failed to determine translation for %JSONKEY%
  exit /b 8
)
goto :eof
REM Belgian Layout
call :get_layout_text BelgiumA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000813" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000813" /v "Layout File" /t REG_SZ /d "BelgiumA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000813" /v "Layout Id" /t REG_SZ /d "00cd" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000813" /v "Layout Component ID" /t REG_SZ /d "D70C1682E8F24ED4B5B70AAD37B1BA42" /f >nul 2>&1

REM British Layout
call :get_layout_text BritishA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000809" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000809" /v "Layout File" /t REG_SZ /d "BritishA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000809" /v "Layout Id" /t REG_SZ /d "00c0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000809" /v "Layout Component ID" /t REG_SZ /d "1A4D378083AD454BB4FE02F208614EB6" /f >nul 2>&1

REM Canadian Layout
call :get_layout_text CanadaA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000c0c" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000c0c" /v "Layout File" /t REG_SZ /d "CanadaA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000c0c" /v "Layout Id" /t REG_SZ /d "00ca" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000c0c" /v "Layout Component ID" /t REG_SZ /d "517A729DDEC543E3A7F392E3F130C25F" /f >nul 2>&1

REM Danish Layout
call :get_layout_text DanishA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000406" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000406" /v "Layout File" /t REG_SZ /d "DanishA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000406" /v "Layout Id" /t REG_SZ /d "00cc" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000406" /v "Layout Component ID" /t REG_SZ /d "C3996498F423440FB9CE2732A821E7D9" /f >nul 2>&1

REM Dutch Layout
call :get_layout_text DutchA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000413" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000413" /v "Layout File" /t REG_SZ /d "DutchA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000413" /v "Layout Id" /t REG_SZ /d "00c1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000413" /v "Layout Component ID" /t REG_SZ /d "3844B95343FB43D68E9695D6E88F016E" /f >nul 2>&1

REM Finnish Layout
call :get_layout_text FinnishA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040b" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040b" /v "Layout File" /t REG_SZ /d "FinnishA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040b" /v "Layout Id" /t REG_SZ /d "00cb" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040b" /v "00cb" /t REG_SZ /d "DutchA.dll" /f >nul 2>&1

REM French Layout
call :get_layout_text FrenchA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040c" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040c" /v "Layout File" /t REG_SZ /d "FrenchA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040c" /v "Layout Id" /t REG_SZ /d "00c2" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040c" /v "Layout Component ID" /t REG_SZ /d "2ECD3C77364749B18E910F9196B420FA" /f >nul 2>&1

REM German Layout
call :get_layout_text GermanA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000407" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000407" /v "Layout File" /t REG_SZ /d "GermanA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000407" /v "Layout Id" /t REG_SZ /d "00c3" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000407" /v "Layout Component ID" /t REG_SZ /d "B616E2191BF048D4A554E5C6BE224AB4" /f >nul 2>&1

REM Italian Layout
call :get_layout_text ItalianA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000410" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000410" /v "Layout File" /t REG_SZ /d "ItalianA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000410" /v "Layout Id" /t REG_SZ /d "00c4" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000410" /v "Layout Component ID" /t REG_SZ /d "6401AAA6058F431181B445C26BEF22D9" /f >nul 2>&1

REM Norwegian Layout
call :get_layout_text NorwayA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000414" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000414" /v "Layout File" /t REG_SZ /d "NorwayA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000414" /v "Layout Id" /t REG_SZ /d "00c9" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000414" /v "Layout Component ID" /t REG_SZ /d "74BE397ABD8143E4960D38111394D1A3" /f >nul 2>&1

REM Polish Layout
call :get_layout_text PolishA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000415" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000415" /v "Layout File" /t REG_SZ /d "PolishA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000415" /v "Layout Id" /t REG_SZ /d "00cf" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000415" /v "Layout Component ID" /t REG_SZ /d "D3D2841618E34D09ABBCA0DA34A60FAE" /f >nul 2>&1

REM Portuguese Layout
call :get_layout_text PortuguA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000416" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000416" /v "Layout File" /t REG_SZ /d "PortuguA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000416" /v "Layout Id" /t REG_SZ /d "00ce" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000416" /v "Layout Component ID" /t REG_SZ /d "326773935C8C4597B0738FE2084D44AD" /f >nul 2>&1

REM Russian Layout
call :get_layout_text RussianA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000419" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000419" /v "Layout File" /t REG_SZ /d "RussianA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000419" /v "Layout Id" /t REG_SZ /d "00c8" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000419" /v "Layout Component ID" /t REG_SZ /d "B0F62A69BE9446488ED502E800DBC36C" /f >nul 2>&1

REM Spanish Layout
call :get_layout_text SpanishA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040a" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040a" /v "Layout File" /t REG_SZ /d "SpanishA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040a" /v "Layout Id" /t REG_SZ /d "00c5" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040a" /v "Layout Component ID" /t REG_SZ /d "C3364C7C44BC444A88A50459135D35B5" /f >nul 2>&1

REM Swedish Layout
call :get_layout_text SwedishA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041d" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041d" /v "Layout File" /t REG_SZ /d "SwedishA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041d" /v "Layout Id" /t REG_SZ /d "00c7" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041d" /v "Layout Component ID" /t REG_SZ /d "8CC8067A1BFF4A0FAD38708DE4CD4BF1" /f >nul 2>&1

REM Swiss Layout
call :get_layout_text SwissA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000100c" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000100c" /v "Layout File" /t REG_SZ /d "SwissA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000100c" /v "Layout Id" /t REG_SZ /d "00c6" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000100c" /v "Layout Component ID" /t REG_SZ /d "CE4C7E2419DE400B8A553E1A5C3DCD04" /f >nul 2>&1

REM International English Layout
call :get_layout_text IntlEngA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0020409" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0020409" /v "Layout File" /t REG_SZ /d "IntlEngA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0020409" /v "Layout Id" /t REG_SZ /d "00d0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0020409" /v "Layout Component ID" /t REG_SZ /d "241A34D0-06DB-405e-8B4E-8CA2FC34D1C7" /f >nul 2>&1

REM USA Layout
call :get_layout_text USA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000409" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000409" /v "Layout File" /t REG_SZ /d "USA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000409" /v "Layout Id" /t REG_SZ /d "00d1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000409" /v "Layout Component ID" /t REG_SZ /d "B422390FE3C04f3a917D15AD1ACD710F" /f >nul 2>&1

REM Chinese Traditional Layout?
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\00000404" /v "Layout File" /t REG_SZ /d "ChinaTA.dll" /f >nul 2>&1

REM Chinese Standard Layout?
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\00000804" /v "Layout File" /t REG_SZ /d "ChinaSA.dll" /f >nul 2>&1

REM Turkish Layout
call :get_layout_text TurkeyA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a100041f" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a100041f" /v "Layout File" /t REG_SZ /d "TurkeyA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a100041f" /v "Layout Id" /t REG_SZ /d "00d2" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a100041f" /v "Layout Component ID" /t REG_SZ /d "D1502D2EF02F4e4b8D313D3C0B0457D0" /f >nul 2>&1

REM Turkish Q (whatever that means) Layout
call :get_layout_text TurkeyQA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041f" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041f" /v "Layout File" /t REG_SZ /d "TurkeyQA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041f" /v "Layout Id" /t REG_SZ /d "00d3" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041f" /v "Layout Component ID" /t REG_SZ /d "2513D09A670B4d9bA8F1BDAAAA32176F" /f >nul 2>&1

REM Czech Layout
call :get_layout_text CzechA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000405" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000405" /v "Layout File" /t REG_SZ /d "CzechA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000405" /v "Layout Id" /t REG_SZ /d "00d4" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000405" /v "Layout Component ID" /t REG_SZ /d "0C8DA389245B4792B4960E336F62AC3E" /f >nul 2>&1

REM Hungarian Layout
call :get_layout_text HungaryA LAYOUT_TEXT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040e" /v "Layout Text" /t REG_SZ /d "%LAYOUT_TEXT%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040e" /v "Layout File" /t REG_SZ /d "HungaryA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040e" /v "Layout Id" /t REG_SZ /d "00d5" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040e" /v "Layout Component ID" /t REG_SZ /d "725BE97D2AD14042BA539D96030F93AA" /f >nul 2>&1

echo Copying DLL layouts to system32 folder

REM Ensure a checksum manifest exists
if not exist "%~dp0install_checksums.txt" (
  echo ERROR: checksum manifest install_checksums.txt not found in the same folder as this script.
  echo Install aborting — checksum verification is required before copying into System32.
  exit /b 2
)

setlocal enabledelayedexpansion
for /F "usebackq tokens=*" %%f in ("install_filelist.txt") do (
  echo Verifying "%%~f" ...
  if not exist "%%~f" (
    echo ERROR: file "%%~f" listed in install_filelist.txt is missing!
    exit /b 3
  )

  REM Lookup expected hash in install_checksums.txt (format: <sha256>  <filename>)
  set "EXPECTED="
  for /F "usebackq tokens=1* delims= " %%H in ('findstr /I /C:"%%~f" "%~dp0install_checksums.txt"') do (
    set "EXPECTED=%%H"
  )
  if not defined EXPECTED (
    echo ERROR: no checksum entry found for %%~f in install_checksums.txt
    exit /b 4
  )

  REM Compute actual SHA256 using certutil and extract the hex string line
  for /F "tokens=*" %%A in ('certutil -hashfile "%%~f" SHA256 ^| findstr /v "SHA256 CertUtil"') do (
    set "ACTUAL=%%A"
  )
  set "ACTUAL=!ACTUAL: =!"

  if /I NOT "!ACTUAL!"=="!EXPECTED!" (
    echo ERROR: checksum mismatch for %%~f
    echo Expected: !EXPECTED!
    echo Actual:   !ACTUAL!
    exit /b 5
  )

  REM Signature verification — require a valid Authenticode signature
  for /F "usebackq tokens=*" %%S in ('powershell -NoProfile -Command "(Get-AuthenticodeSignature '%~dp0%%~f').Status" 2^>^&1') do (
    set "SIGN_STATUS=%%S"
  )
  if /I NOT "!SIGN_STATUS!"=="Valid" (
    echo ERROR: signature verification failed for %%~f (Status=!SIGN_STATUS!)
    exit /b 6
  )

  copy "%%~f" "C:\Windows\System32\" >nul 2>&1
  if errorlevel 1 (
    echo ERROR: failed to copy %%~f to C:\Windows\System32\
    exit /b 7
  ) else (
    echo OK: copied %%~f
  )
)
endlocal

echo Finished installing layouts
echo.

REM If MAGIC_SILENT is defined, skip interactive pause (used by automated installers)
if not defined MAGIC_SILENT pause

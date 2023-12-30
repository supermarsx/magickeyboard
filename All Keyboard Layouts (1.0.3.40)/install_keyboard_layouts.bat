@echo OFF & cls & echo.
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo You must right-click and select
  echo "RUN AS ADMINISTRATOR" to run this script.
  echo Exiting...
  echo.
  pause
  exit
)

echo Installing Keyboard Layouts

echo Creating Registry keys
REM Belgian Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000813" /v "Layout Text" /t REG_SZ /d "Belgian (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000813" /v "Layout File" /t REG_SZ /d "BelgiumA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000813" /v "Layout Id" /t REG_SZ /d "00cd" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000813" /v "Layout Component ID" /t REG_SZ /d "D70C1682E8F24ED4B5B70AAD37B1BA42" /f >nul 2>&1

REM British Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000809" /v "Layout Text" /t REG_SZ /d "British (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000809" /v "Layout File" /t REG_SZ /d "BritishA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000809" /v "Layout Id" /t REG_SZ /d "00c0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000809" /v "Layout Component ID" /t REG_SZ /d "1A4D378083AD454BB4FE02F208614EB6" /f >nul 2>&1

REM Canadian Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000c0c" /v "Layout Text" /t REG_SZ /d "Canadian (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000c0c" /v "Layout File" /t REG_SZ /d "CanadaA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000c0c" /v "Layout Id" /t REG_SZ /d "00ca" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000c0c" /v "Layout Component ID" /t REG_SZ /d "517A729DDEC543E3A7F392E3F130C25F" /f >nul 2>&1

REM Danish Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000406" /v "Layout Text" /t REG_SZ /d "Danish (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000406" /v "Layout File" /t REG_SZ /d "DanishA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000406" /v "Layout Id" /t REG_SZ /d "00cc" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000406" /v "Layout Component ID" /t REG_SZ /d "C3996498F423440FB9CE2732A821E7D9" /f >nul 2>&1

REM Dutch Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000413" /v "Layout Text" /t REG_SZ /d "Dutch (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000413" /v "Layout File" /t REG_SZ /d "DutchA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000413" /v "Layout Id" /t REG_SZ /d "00c1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000413" /v "Layout Component ID" /t REG_SZ /d "3844B95343FB43D68E9695D6E88F016E" /f >nul 2>&1

REM Finnish Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040b" /v "Layout Text" /t REG_SZ /d "Finnish (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040b" /v "Layout File" /t REG_SZ /d "FinnishA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040b" /v "Layout Id" /t REG_SZ /d "00cb" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040b" /v "00cb" /t REG_SZ /d "DutchA.dll" /f >nul 2>&1

REM Dutch Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000413" /v "Layout Text" /t REG_SZ /d "Dutch (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000413" /v "Layout File" /t REG_SZ /d "DutchA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000413" /v "Layout Id" /t REG_SZ /d "00c1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000413" /v "Layout Component ID" /t REG_SZ /d "3844B95343FB43D68E9695D6E88F016E" /f >nul 2>&1

REM Finnish Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040b" /v "Layout Text" /t REG_SZ /d "Finnish (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040b" /v "Layout File" /t REG_SZ /d "FinnishA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040b" /v "Layout Id" /t REG_SZ /d "00cb" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040b" /v "Layout Component ID" /t REG_SZ /d "ECE9937799D242F5AE0CAA446EDEDC62" /f >nul 2>&1

REM French Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040c" /v "Layout Text" /t REG_SZ /d "French (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040c" /v "Layout File" /t REG_SZ /d "FrenchA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040c" /v "Layout Id" /t REG_SZ /d "00c2" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040c" /v "Layout Component ID" /t REG_SZ /d "2ECD3C77364749B18E910F9196B420FA" /f >nul 2>&1

REM German Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000407" /v "Layout Text" /t REG_SZ /d "German (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000407" /v "Layout File" /t REG_SZ /d "GermanA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000407" /v "Layout Id" /t REG_SZ /d "00c3" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000407" /v "Layout Component ID" /t REG_SZ /d "B616E2191BF048D4A554E5C6BE224AB4" /f >nul 2>&1

REM Italian Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000410" /v "Layout Text" /t REG_SZ /d "Italian (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000410" /v "Layout File" /t REG_SZ /d "ItalianA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000410" /v "Layout Id" /t REG_SZ /d "00c4" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000410" /v "Layout Component ID" /t REG_SZ /d "6401AAA6058F431181B445C26BEF22D9" /f >nul 2>&1

REM Norwegian Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000414" /v "Layout Text" /t REG_SZ /d "Norwegian (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000414" /v "Layout File" /t REG_SZ /d "NorwayA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000414" /v "Layout Id" /t REG_SZ /d "00c9" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000414" /v "Layout Component ID" /t REG_SZ /d "74BE397ABD8143E4960D38111394D1A3" /f >nul 2>&1

REM Polish Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000415" /v "Layout Text" /t REG_SZ /d "Polish (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000415" /v "Layout File" /t REG_SZ /d "PolishA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000415" /v "Layout Id" /t REG_SZ /d "00cf" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000415" /v "Layout Component ID" /t REG_SZ /d "D3D2841618E34D09ABBCA0DA34A60FAE" /f >nul 2>&1

REM Portuguese Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000416" /v "Layout Text" /t REG_SZ /d "Portuguese (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000416" /v "Layout File" /t REG_SZ /d "PortuguA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000416" /v "Layout Id" /t REG_SZ /d "00ce" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000416" /v "Layout Component ID" /t REG_SZ /d "326773935C8C4597B0738FE2084D44AD" /f >nul 2>&1

REM Russian Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000419" /v "Layout Text" /t REG_SZ /d "Russian (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000419" /v "Layout File" /t REG_SZ /d "RussianA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000419" /v "Layout Id" /t REG_SZ /d "00c8" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000419" /v "Layout Component ID" /t REG_SZ /d "B0F62A69BE9446488ED502E800DBC36C" /f >nul 2>&1

REM Swedish Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041d" /v "Layout Text" /t REG_SZ /d "Swedish (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041d" /v "Layout File" /t REG_SZ /d "SwedishA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041d" /v "Layout Id" /t REG_SZ /d "00c7" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041d" /v "Layout Component ID" /t REG_SZ /d "8CC8067A1BFF4A0FAD38708DE4CD4BF1" /f >nul 2>&1

REM Swiss Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000100c" /v "Layout Text" /t REG_SZ /d "Swiss (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000100c" /v "Layout File" /t REG_SZ /d "SwissA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000100c" /v "Layout Id" /t REG_SZ /d "00c6" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000100c" /v "Layout Component ID" /t REG_SZ /d "CE4C7E2419DE400B8A553E1A5C3DCD04" /f >nul 2>&1

REM International English Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0020409" /v "Layout Text" /t REG_SZ /d "International English (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0020409" /v "Layout File" /t REG_SZ /d "IntlEngA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0020409" /v "Layout Id" /t REG_SZ /d "00d0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0020409" /v "Layout Component ID" /t REG_SZ /d "241A34D0-06DB-405e-8B4E-8CA2FC34D1C7" /f >nul 2>&1

REM USA Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000409" /v "Layout Text" /t REG_SZ /d "USA (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000409" /v "Layout File" /t REG_SZ /d "USA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000409" /v "Layout Id" /t REG_SZ /d "00d1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000409" /v "Layout Component ID" /t REG_SZ /d "B422390FE3C04f3a917D15AD1ACD710F" /f >nul 2>&1

REM Chinese Traditional Layout?
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\00000404" /v "Layout File" /t REG_SZ /d "ChinaTA.dll" /f >nul 2>&1

REM Chinese Standard Layout?
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\00000804" /v "Layout File" /t REG_SZ /d "ChinaSA.dll" /f >nul 2>&1

REM Turkish Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a100041f" /v "Layout Text" /t REG_SZ /d "Turkish (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a100041f" /v "Layout File" /t REG_SZ /d "TurkeyA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a100041f" /v "Layout Id" /t REG_SZ /d "00d2" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a100041f" /v "Layout Component ID" /t REG_SZ /d "D1502D2EF02F4e4b8D313D3C0B0457D0" /f >nul 2>&1

REM Turkish Q (whatever that means) Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041f" /v "Layout Text" /t REG_SZ /d "Turkish Q (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041f" /v "Layout File" /t REG_SZ /d "TurkeyQA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041f" /v "Layout Id" /t REG_SZ /d "00d3" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000041f" /v "Layout Component ID" /t REG_SZ /d "2513D09A670B4d9bA8F1BDAAAA32176F" /f >nul 2>&1

REM Czech Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000405" /v "Layout Text" /t REG_SZ /d "Czech (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000405" /v "Layout File" /t REG_SZ /d "CzechA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000405" /v "Layout Id" /t REG_SZ /d "00d4" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000405" /v "Layout Component ID" /t REG_SZ /d "0C8DA389245B4792B4960E336F62AC3E" /f >nul 2>&1

REM Hungarian Layout
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040e" /v "Layout Text" /t REG_SZ /d "Hungarian (Apple)" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040e" /v "Layout File" /t REG_SZ /d "HungaryA.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040e" /v "Layout Id" /t REG_SZ /d "00d5" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a000040e" /v "Layout Component ID" /t REG_SZ /d "725BE97D2AD14042BA539D96030F93AA" /f >nul 2>&1

echo Copying DLL layouts to system32 folder
for /F "usebackq tokens=*" %%f in ("install_filelist.txt") do copy "%%~f" "C:\Windows\System32\" >nul 2>&1

echo Finished installing layouts
echo.

pause
# magickeyboard

This is a mirror repository for Apple Magic Keyboard 1 (removable batteries, rounded top) and 2 (slim, embedded battery) drivers, plus Apple Keyboard Layouts for all the languages available. Use your magic keyboard on any bluetooth enabled Windows machine.



[Download this repo](https://codeload.github.com/supermarsx/magickeyboard/zip/refs/heads/main)

[**Also download this repo but in bold**](https://codeload.github.com/supermarsx/magickeyboard/zip/refs/heads/main)



### Quick Start

- Download the packages you need
- Use the installers 
  - `magickeyboard1_AppleKeyboardInstaller64.exe` 
  - `magickeyboard2_AppleKeyboardInstaller64.exe`
  - `install_keyboard_layouts.bat` (is inside the "All Keyboard Layouts *" folder)
- ?
- Profit
- **Profit even more but in bold**



Also note, don't change files or installers, etc if you don't know what you're doing, check the "Screwed up?" section for more information. Just use the installers and you'll be fine, changes only need to be made in specific use case scenarios.



### Whats the purpose

These packages are not readily available to end users and sometimes you'll not be able to find anywhere without downloading bootcamp from MacOS. These packages fix issues such as not being able to use delete (fn + backspace) on the keyboard or not detecting the device properly. Usually changes are ready and functional right after install but you may need to restart in some circumstances.



### File table

Magic Keyboard Drivers from Apple

| Device           | Filename                                                                                                                                                   |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Magic Keyboard 1 | [magickeyboard1_AppleKeyboardInstaller64.exe](https://github.com/eduardomota/magickeyboard/blob/main/magickeyboard1_AppleKeyboardInstaller64.exe?raw=true) |
| Magic Keyboard 2 | [magickeyboard2_AppleKeyboardInstaller64.exe](https://github.com/eduardomota/magickeyboard/blob/main/magickeyboard2_AppleKeyboardInstaller64.exe?raw=true) |



 Magic Keyboard Layout files, inside All Keyboard Layouts folder

| Filename                         | Description                                                             |
| -------------------------------- | ----------------------------------------------------------------------- |
| `install_keyboard_layouts.bat`   | Install all Magic Keyboard Layouts (needs to be ran as administrator)   |
| `uninstall_keyboard_layouts.bat` | Uninstall all Magic Keyboard Layouts (needs to be ran as administrator) |
| `install_filelist.txt`           | A list of keyboard layout DLL  files to install and uninstall           |
| `*.dll`                          | Keyboard Layout DLL file from Apple, see list below                     |



### Keyboard Layout Languages

All the currently available keyboard layouts:

- Belgian (Belgian (Apple)) (`BelgiumA.dll`)

- British (British (Apple)) - (`BritishA.dll`)

- Dutch (Dutch (Apple)) - (`DutchA.dll`)

- Finnish (Finnish (Apple)) - (`FinnishA.dll`)

- French (French (Apple)) - (`FrenchA.dll`)

- German (German (Apple)) - (`GermanA.dll`)

- Italian (Italian (Apple)) - (`ItalianA.dll`)

- Norwegian (Norwegian (Apple)) - (`NorwayA.dll`)

- Polish (Polish (Apple)) - (`PolishA.dll`)

- Portuguese (Portuguese (Apple)) - (`PortuguA.dll`)

- Russian (Russian (Apple)) - (`RussianA.dll`)

- Spanish (Spanish (Apple)) - (`SpanishA.dll`)

- Swedish (Swedish (Apple)) - (`SwedishA.dll`)

- Swiss (Swiss (Apple)) - (`SwissA.dll`)

- International English (International English (Apple)) - (`IntlEngA.dll`)

- USA (USA (Apple)) - (`USA.dll`)

- Chinese Traditional (??) - (`ChinaTA.dll`)

- Chinese Simplified (Chinese Simplified (Apple)) - (`ChinaSA.dll`)

- Turkish (Turkish (Apple)) - (`TurkeyA.dll`)

- Turkish Q (Turkish Q (Apple)) - (`TurkeyQA.dll`)

- Czech (Czech (Apple)) - (`CzechA.dll`)

- Hungarian (Hungarian (Apple)) - (`HungaryA.dll`)



**Note:** List schema: `Layout name` (`Layout name shown in Settings`) (`Corresponding DLL file`)



#### If a layout doesn't show up in keyboard layouts

- Try to look for the english name of the layout that's how the installation is set (ex. "Belgian (Apple)");

- Change the "reg add" instructions for your keyboard layout to your preferred name  in the line where "/v" is "Layout Text", after "/d" should be the layout name (ex.: `reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000809" /v "Layout Text" /t REG_SZ /d "BRI'ISH (Apple)"`);

- Reinstall your keyboard layout manually as instructed below.



### Manually install Keyboard Layouts

To manually install a keyboard layout using a DLL you'll need:

- Keyboard layout DLL file (ex.: BritishA.dll);

- Regedit add key (`reg add`) instructions found in `install_keyboard_layouts.bat`.

Then you need to follow these steps:

- Copy DLL file to system32 folder;

- Add the corresponding layout keys to the registry through the "reg add" instructions using a an elevated command line (cmd) prompt.

Your layout will be ready for use.



### Screwed up?

Screwed up, deleted system32 or something? No warranty, you're on your own. Good luck.



### File hash table

| Filename                                                                                                                                                   | Hash                                                             | Signed         |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- | -------------- |
| [magickeyboard1_AppleKeyboardInstaller64.exe](https://github.com/eduardomota/magickeyboard/blob/main/magickeyboard1_AppleKeyboardInstaller64.exe?raw=true) | 2F9117ED2AE549F21530CECE1717505748B024543411B3DC0B3536326EA56BEC | Yes (by Apple) |
| [magickeyboard2_AppleKeyboardInstaller64.exe](https://github.com/eduardomota/magickeyboard/blob/main/magickeyboard2_AppleKeyboardInstaller64.exe?raw=true) | C7ACD788B0770316AD6A7C1C423ED730FE8B9F01E7E64702A94D7F3D3975CD96 | Yes (by Apple) |
| [ptptcustomlayout_AppleMagicKeyboard.zip](https://github.com/eduardomota/magickeyboard/blob/main/ptptcustomlayout_AppleMagicKeyboard.zip?raw=true)         | 2315337FCD42AF06EA847B2DDE9BD4C239B1736D6E599AC529316A08D2831E35 | No             |

# magickeyboard

This is an alternative/mirror repository for the **Apple Magic Keyboard** 1 (removable batteries, rounded top), 2 (slim, embedded battery) and 3 (slim, rounded corners and embedded battery) **drivers**, plus all the Apple **keyboard layouts** currently available. Use your magic keyboard on any bluetooth enabled Windows machine.

[**Download this repository**](https://codeload.github.com/supermarsx/magickeyboard/zip/refs/heads/main)

## Table of Contents

- [Quick Start](#quick-start)
  
  - [Driver only](#driver-only)
    
  - [Driver and layouts](#driver-and-layouts)
    
  - [Layouts only](#layouts-only)
    
  - [Other methods/options](#other-methodsoptions)
    
- [Whats the purpose?](#whats-the-purpose)
  
- [File table](#file-table)
  
- [Installation instructions](#installation-instructions)
  
  - [Automatically install driver](#automatically-install-driver)
    
  - [Manually install driver](#manually-install-driver)
    
  - [Automatically install layouts](#automatically-install-layouts)
    
  - [Manually install layouts](#manually-install-layouts)
    
  - [Uninstall layouts](#uninstall-layouts)
    
- [Layout topics](#layout-topics)
  
  - [Layout languages](#layout-languages)
    
  - [Translate layout names](#translate-layout-names)
    
- [Questions and problem resolution](#questions-and-problem-resolution)
  
  - [Layouts don't get installed if i run the batch file as an administrator](#layouts-dont-get-installed-if-i-run-the-batch-file-as-an-administrator)
    
  - [Layout doesn't show up in keyboard layouts](#layout-doesnt-show-up-in-keyboard-layouts)
    
  - [I'm unable to bind, remap or reregister certain keys using x method](#im-unable-to-bind-remap-reregister-certain-keys-using-x-method)
    
  - [Are these files legit?](#are-these-files-legit)
    
  - [Screwed up badly?](#screwed-up-badly)
    
- [Support, warranty, guarantees](#support-warranty-guarantees)
  

## Quick Start

Recommended installation methods are [**Driver only**](#driver-only) or [**Driver and layouts**](#driver-and-layouts).

### Driver only

**Note:** You'll need administrator privileges.

To install only the driver follow these steps:

1. **Download** one of the installers for your keyboard version/model:
  
  1. **Magic Keyboard 1**: [magickeyboard1_AppleKeyboardInstaller64.exe](https://github.com/supermarsx/magickeyboard/blob/main/magickeyboard1_AppleKeyboardInstaller64.exe?raw=true);
    
  2. **Magic Keyboard 2 and 3**: [magickeyboard2_AppleKeyboardInstaller64.exe](https://github.com/eduardomota/magickeyboard/blob/main/magickeyboard2_AppleKeyboardInstaller64.exe?raw=true).
    
2. **Execute** your chosen installer.
  

Your keyboard should be working as expected.

####

### Driver and layouts

**Note:** You'll need administrator privileges.

To install both driver and layouts follow these steps:

1. [Download drivers and layouts](https://codeload.github.com/supermarsx/magickeyboard/zip/refs/heads/main);
  
2. Execute the appropriate installer for your keyboard version/model:
  
  1. `magickeyboard1_AppleKeyboardInstaller64.exe` for the Magic Keyboard 1;
    
  2. `magickeyboard2_AppleKeyboardInstaller64.exe` for Magic Keyboard 2 and 3.
    
3. Translate keyboard layout names (optional):
  
  1. Read [Layout languages](#layout-languages);
    
  2. Refer to [Translate layout names](#translate-layout-names).
    
4. Enter `All Keyboard Layouts` folder and run `install_keyboard_layouts.bat` as an administrator.
  

Your keyboard and respective layouts should be working.

### Layouts only

**Note:** You'll need administrator privileges.

To install keyboard layouts follow these steps:

1. [Download all keyboard layouts folder](https://github.com/supermarsx/magickeyboard/releases/download/1/All.Keyboard.Layouts.1.0.3.40.zip);
  
2. Translate the keyboard layout name (optional):
  
  1. Read [Layout languages](#layout-languages);
    
  2. Refer to [Translate layout names](#translate-layout-names).
    
3. Run `install_keyboard_layouts.bat` as an administrator.
  

Your keyboard layouts should be working as intended.

### Other methods/options

To install a single keyboard layout, use unpacked driver files or other different methods, options or combinations you should refer to the [Table of Contents](#table-of-contents) to find your preferred method and alternative actions.

If can find more downloadables in the [latest release page](https://github.com/supermarsx/magickeyboard/releases/latest).

**Note:** Don't change files, installers, etc. specially if you don't know what you're doing, check the "[Screwed up?](#screwed-up)" topic for more information. For most use cases just use the installers and you'll be fine. Major changes are needed only in specific use case scenarios.

## Whats the purpose?

These packages are not readily available to end users and sometimes you'll not be able to find anywhere without downloading bootcamp from MacOS or `brigadier` for example.

These packages fix issues such as not being able to use delete key (fn + backspace) on the keyboard or not detecting the device properly.

Usually changes are ready and functional right after install but you may need to restart in some scenarios.

Also removes the need to fully install/download bootcamp if you're not actually using an apple machine ...and it's free, no need for paid apps if you just need the damn thing working.

## File table

**Drivers**

| Device | Filename |
| --- | --- |
| Magic Keyboard 1 | [magickeyboard1_AppleKeyboardInstaller64.exe](https://github.com/supermarsx/magickeyboard/blob/main/magickeyboard1_AppleKeyboardInstaller64.exe?raw=true) |
| Magic Keyboard 2/3 | [magickeyboard2_AppleKeyboardInstaller64.exe](https://github.com/eduardomota/magickeyboard/blob/main/magickeyboard2_AppleKeyboardInstaller64.exe?raw=true) |

**Layouts**

| Languages | Filename |
| --- | --- |
| All | [All.Keyboard.Layouts.1.0.3.40.zip](https://github.com/supermarsx/magickeyboard/releases/download/1/All.Keyboard.Layouts.1.0.3.40.zip) |

Magic Keyboard layout files, inside `All Keyboard Layouts` folder

| Filename | Description |
| --- | --- |
| `install_keyboard_layouts.bat` | Install all Magic Keyboard Layouts (needs to be ran as administrator) |
| `uninstall_keyboard_layouts.bat` | Uninstall all Magic Keyboard Layouts (needs to be ran as administrator) |
| `install_filelist.txt` | A list of keyboard layout DLL files to install or uninstall |
| `*.dll` | Keyboard Layout DLL file from Apple, see list below |

## Installation instructions

### Automatically install driver

1. Get your corresponding keyboard version installer;
  
2. Run it, you'll need administrator privileges.
  

### Manually install driver

**Note:** Unless you have a specific reason for why you need individual files you should opt for automatic installation.

If you still need to manually install the driver for some special reason you can:

1. Extract files from the corresponding keyboard version installer (with 7-zip for example);
  
2. Do one of three things:
  
  1. Execute `DPInst.exe` directly;
    
  2. Update the device driver through the device manager and target the extracted folder;
    
  3. Whatever you want.
    

### Automatically install layouts

To automatically install all keyboard layouts you'll need:

1. A copy of `All Keyboard Layouts` folder;
  
2. Translate any layout names inside `install_keyboard_layouts.bat` (optional);
  
3. Run `install_keyboard_layouts.bat` as an administrator.
  

Your keyboard layouts will be ready to use.

### Manually install layouts

To manually install a keyboard layout using a DLL you'll need:

- Keyboard layout DLL file (ex.: `BritishA.dll`);
  
- Regedit add (`reg add`) instructions found inside `install_keyboard_layouts.bat`.
  

Then you need to follow these steps:

1. Copy DLL file to `system32` folder;
  
2. Add the corresponding layout keys to the registry through the registry add (`reg add`) instructions using a an elevated command line (cmd) prompt.
  

Your layout will be ready for use.

### Uninstall layouts

1. Just run `uninstall_keyboard_layouts.bat` batch file with administrator privileges.

All keyboard layouts should be gone.

## Layout topics

### Layout languages

All keyboard layouts currently available:

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

### Translate layout names

**Note:** You should only translate layout names if you're comfortable with registry key instructions and batch files, meaning you know what they do and/or what you're supposed to edit fo them to work correctly.

To translate layout names do the following steps:

1. Go to `All Keyboard Layouts folder`;
  
2. Open `install_keyboard_layouts.bat` with your preferred editor;
  
3. Edit on each language section on the line containing `/v "Layout Text"` (usually is the first of the section) the part where you see the name of the layout in this format `LANGUAGE NAME (Apple)` (example: `Belgian (Apple)`);
  
4. Save.
  

When you install/reinstall layout names should be corrected.

## Questions and problem resolution

### Layouts don't get installed if i run the batch file as an administrator

You could try:

1. Launch the command line as an **administrator**;
  
2. Navigate to the layout folder using `cd` and the respective folder path
  
3. Execute the batch file `.bat` from the command line
  

####

### Layout doesn't show up in keyboard layouts

You could try:

- Try to look for the english name of the layout that's how the installation is set above like (ex. "Belgian (Apple)");
  
- Change the registry add (`reg add`) instructions for your keyboard layout to your preferred name in the line where `/v` is "Layout Text", after `/d` should be the layout name like (ex.: `reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000809" /v "Layout Text" /t REG_SZ /d "BRI'ISH (Apple)"`);
  
- Reinstall your keyboard layout manually as instructed below.
  

### I'm unable to bind, remap or reregister certain keys using x method

If you're trying to somehow change certain key functions from your keyboard, binding, rebindin, remapping, whatever and seem unable to, you might be running into the drivers limitations of the keyboard on Windows, that means i don't have a solution. As far as i've tried in the past i wasn't able to use PowerToys, AutoIt, C++, AutoHotKey, C#, etc to do it successfully. Some keys don't appear to register at all even if they work as originally intended, meaning to solve this you'll need to somehow reverse engineer and go through all the hoops of that kind of process to maybe find a solution that works. I can't help with this, sorry. Reference, [Issue #1](https://github.com/supermarsx/magickeyboard/issues/1).

### Are these files legit?

They're officially signed files from Apple that you can check through the properties of each file, both DLL and executables. The only things that are not official are the keyboard layout installer/uninstaller batch files as well as the file list and the old layout archive containing a custom mapped pt-pt layout using the microsoft keyboard mapping tool thing many years ago.

### Screwed up badly?

Screwed up, deleted `system32` or something?

No warranty, you're on your own.

Good luck.

## Support, warranty, guarantees

- Support only through issues if i feel like it with limitations:
  
  - These may be accepted:
    
    - Open-source and/or verifiable additions;
      
    - Issues with related functionality;
      
    - Important undocumented issues or caveats;
      
    - Other very high importance issues.
      
  - The won't be accepted:
    
    - Screw up issues and/or help.
- No warranties, explicit and/or implied;
  
- No guarantees, explicit and/or implied.

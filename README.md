# Aegisub Persian Toolkit
Collection of tools that might help Persian translators.

[AnimDL.ir](https://www.animdl.ir) | [@AnimeList_ir](https://t.me/animelist_ir)

# How to install
1. Copy autoload content to autoload directory of aegisub.
2. Copy include content to include directory of aegisub.

Mentioned directories are at the locations bellow:
- Windows:
```
%appdata%\Aegisub\automation\
```
- Linux:
```
~/.aegisub/automation/
```

(If folders doesn\'t exist you can create it yourself)

# Scripts
## PakNevis
Correct common mistakes in Persian text.
## Extend Move
Extend \move based on line's time (Created for linear signs that go outside of video boundries).
## Unretard
Converts non-RTL typed text to RTL compatible one.
## RTL / RTL
Fix RTL languages displaying issues.
## RTL / Un-RTL
Undo RTL function effects.
## RTL Editor (Edited version of MasafAutomation\'s RTL Editor)
An editor for easy editing of RTL language lines.
## Split / Split at Tags (Based on Lyger's Split at Tags automation)
A splitter (at tags) for RTL language lines.
## Split / Split at Spaces
A splitter (at spaces) for RTL language lines.
## Split / Reverse + Split (at Tags)
Split / Reverse at Tags + Split / Split at Tags.
## Split / Reverse at Tags
Reverse line at tags to use it with other LTR automations.

# Credits
- [utf8.lua](https://github.com/Stepets/utf8.lua)
- [MasafAutomation](https://github.com/Majid110/MasafAutomation)
- [Lyger's Automations](https://github.com/lyger/Aegisub_automation_scripts)

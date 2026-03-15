; Shortcuts-Custom Inno Setup Script
; Compiles into a Windows installer (.exe)
;
; Prerequisites:
;   1. Install Inno Setup from https://jrsoftware.org/isdl.php
;   2. Compile popup.ahk to popup.exe using Ahk2Exe (right-click .ahk > Compile Script)
;   3. Open this file in Inno Setup Compiler and click Build > Compile
;
; The installer will:
;   - Copy all app files to Program Files
;   - Create Start Menu shortcuts
;   - Optionally add to Windows Startup
;   - Create an uninstaller

#define MyAppName "Shortcuts-Custom"
#define MyAppVersion "1.1.0"
#define MyAppPublisher "PaulR"
#define MyAppURL "https://github.com/PaulERayburn/Shortcuts-Custom-Release"
#define MyAppExeName "popup.exe"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=LICENSE
OutputDir=dist
OutputBaseFilename=Shortcuts-Custom-Setup-{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"
Name: "startupicon"; Description: "Start automatically when I log in"; GroupDescription: "Startup:"

[Files]
; Main executable (compiled from popup.ahk)
Source: "popup.exe"; DestDir: "{app}"; Flags: ignoreversion

; HTML interfaces
Source: "popup.html"; DestDir: "{app}"; Flags: ignoreversion
Source: "collector.html"; DestDir: "{app}"; Flags: ignoreversion
Source: "speech-to-text.html"; DestDir: "{app}"; Flags: ignoreversion

; Data files
Source: "collector-data.js"; DestDir: "{app}"; Flags: ignoreversion
Source: "shortcuts.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "config.json"; DestDir: "{app}"; Flags: ignoreversion

; Scripts
Source: "scripts\*"; DestDir: "{app}\scripts"; Flags: ignoreversion recursesubdirs createallsubdirs


[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: startupicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Kill the process before uninstalling
Filename: "taskkill"; Parameters: "/F /IM {#MyAppExeName}"; Flags: runhidden; RunOnceId: "KillApp"

# Shortcuts-Custom

A lightweight keyboard shortcut manager for Windows. Press a hotkey to open a searchable popup where you can view, copy, organize, and run your shortcuts. Includes a **Clipboard Collector** for gathering text snippets and an **MLS Notes** tool for real estate workflows.

Built with AutoHotkey v2 and Microsoft Edge (app mode). No internet required — everything runs locally.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-0078d4.svg)
![AHK](https://img.shields.io/badge/AutoHotkey-v2.0-green.svg)

## Features

- **Shortcut Popup** (CapsLock + /) — searchable, categorized shortcut reference with copy-to-clipboard
- **Clipboard Collector** (CapsLock + ;) — collect text selections into named lists, paste them all at once
- **MLS Notes** (CapsLock + .) — structured note-taking tool with dictation support
- **Runnable Scripts** — launch .bat, .ps1, or .exe files directly from the popup
- **Categories & Favorites** — organize shortcuts with color-coded categories and star your most-used ones
- **Inline Notes** — attach notes to any shortcut for extra context
- **Dark Theme** — easy on the eyes, designed for daily use

## Quick Start

### Option A: Download a Release (recommended)

1. Go to the [Releases](../../releases) page
2. Download the latest `.zip` file
3. Extract to any folder (e.g. `C:\Shortcuts-Custom`)
4. Double-click `popup.exe` to start

### Option B: Run from Source

1. **Install AutoHotkey v2**
   ```
   winget install AutoHotkey.AutoHotkey
   ```
   Or download from [autohotkey.com](https://www.autohotkey.com/)

2. **Clone the repo**
   ```
   git clone https://github.com/PaulERayburn/Shortcuts-Custom.git
   ```

3. **Run the script**
   ```
   Double-click popup.ahk
   ```

You'll see a tooltip: "Shortcuts Popup ready!" and a green **H** icon in your system tray.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `CapsLock + /` | Toggle the shortcuts popup |
| `CapsLock + .` | Toggle MLS Notes |
| `CapsLock + ;` | Collect selected text into active list |
| `Shift + CapsLock + ;` | Create a new collector list from clipboard |
| `CapsLock + ]` | Paste collected items (space-separated) |
| `CapsLock + Backspace` | Toggle the Collector viewer |
| `Esc` | Close any open popup |

## How It Works

The app runs as a system tray application. Hotkeys open lightweight Edge windows in app mode (no browser chrome, no tabs). All data is stored in browser localStorage and local files — nothing is sent anywhere.

### Shortcuts Popup
Search, browse by category, copy key combos to clipboard, or run scripts. Add/edit/delete shortcuts through the UI.

### Clipboard Collector
Highlight text anywhere and press `CapsLock + ;` to collect it. Items are stored in named lists. Press `CapsLock + ]` to paste all items from the active list, space-separated. Great for gathering MLS numbers, addresses, or any repeated data entry.

### Collector Viewer
A visual interface to see your collected items, add/remove entries, switch between lists, rename or delete lists, and copy the full list to clipboard.

## Changing the Hotkey

Edit `popup.ahk` and change the `TRIGGER_KEY` variable near the top:

```ahk
TRIGGER_KEY := "CapsLock & /"   ; Default
TRIGGER_KEY := "^!s"            ; Ctrl + Alt + S
TRIGGER_KEY := "F12"            ; F12
TRIGGER_KEY := "#/"             ; Win + /
```

Save and reload the script (right-click tray icon > Reload Script).

## Start on Login

1. Press `Win + R`, type `shell:startup`, press Enter
2. Create a shortcut to `popup.ahk` (or `popup.exe` if using a release) in the Startup folder

## Building from Source

To compile `popup.ahk` into a standalone `.exe`:

1. Install AutoHotkey v2
2. Right-click `popup.ahk` > **Compile Script** (or run `Ahk2Exe`)
3. Place `popup.exe` in the same folder as the `.html` and `.js` files

## Project Structure

| File | Description |
|---|---|
| `popup.ahk` | Main script — hotkeys, window management, collector logic |
| `popup.html` | Shortcuts popup UI |
| `collector.html` | Collector viewer UI |
| `collector-data.js` | Collector data bridge (auto-generated, do not edit) |
| `mls-notes.html` | MLS Notes tool UI |
| `scripts/` | Helper scripts (PowerShell) |
| `shortcuts.json` | Default shortcuts data |
| `config.json` | Configuration file |

## Requirements

- **Windows 10 or 11**
- **Microsoft Edge** (pre-installed on Windows 10/11)
- **AutoHotkey v2** (only needed if running from source, not for compiled .exe)

## License

[MIT](LICENSE) — free to use, modify, and distribute.

## Credits

Created by PaulR & [Claude Code](https://claude.ai)

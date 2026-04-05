# Shortcuts-Custom — Dev Notes

Quick reference for AI-assisted development sessions.

---

## Project Overview

A Windows desktop utility built with **AutoHotkey v2** and **Microsoft Edge (app mode)**.
No server, no build step, no dependencies — everything is local.

## File Roles

| File | Purpose |
|---|---|
| `popup.ahk` | Main script — hotkeys, tray icon, window management, collector logic |
| `popup.html` | Shortcuts popup UI (runs in Edge app mode) |
| `collector.html` | Clipboard Collector viewer UI |
| `collector-data.js` | Auto-generated data bridge between AHK and the collector UI — do not edit manually |
| `ai-assist.html` | AI Assist UI — multi-provider text processing + web destinations |
| `shortcuts.json` | Shortcut data store |
| `config.json` | User configuration (hotkey, paths, etc.) |
| `installer.iss` | Inno Setup script for building the installer |

## Making and Testing Changes

- Edit `.ahk`, `.html`, or `.js` files in your editor
- To reload: **right-click the tray icon → Reload Script**
- To stop: **right-click the tray icon → Exit**
- No compilation needed for development — just reload
- To compile to `.exe`: right-click `popup.ahk` → Compile Script (requires Ahk2Exe)

## Key Constraints

- `collector-data.js` is written by the AHK script at runtime — never overwrite it with static content
- All UI data lives in browser `localStorage` — clearing browser data will wipe shortcuts
- Edge must be installed (it is on all Windows 10/11 machines by default)
- AHK v2 syntax — not compatible with AHK v1

## What NOT to Commit

- Personal shortcut data or notes (the `shortcuts.json` in the repo is a clean default)
- Any `.exe` build outputs
- `collector-data.js` runtime state (though the repo version is a safe blank default)

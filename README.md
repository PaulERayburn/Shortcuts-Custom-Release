# Shortcuts-Custom

A keyboard shortcut popup for Windows. Press **CapsLock + /** to open a searchable popup where you can view, copy, add, and edit your shortcuts.

Built with AutoHotkey v2 and Microsoft Edge (app mode).

## How to run it

1. **Install AutoHotkey v2** if you don't have it already.
   - Open PowerShell and run: `winget install AutoHotkey.AutoHotkey`
   - Or download it from https://www.autohotkey.com/

2. **Double-click `popup.ahk`** in this folder (`C:\GitRepos\Shortcuts-Custom\`).
   - You'll see a small tooltip saying "Shortcuts Popup ready!"
   - A green **H** icon appears in your system tray (bottom-right of your screen).

3. **Press CapsLock + /** to open the popup. Press **Esc** to close it.

That's it. For more details (changing the hotkey, starting on login, troubleshooting), see `SETUP.txt`.

## How to update it with Git

Your shortcuts and settings are tracked by Git so you have a history of changes.

**After you make changes** (edit shortcuts.json, tweak popup.ahk, etc.):

1. Open a terminal in this folder
2. Run these commands:
   ```
   git add -A
   git commit -m "Describe what you changed"
   ```

That saves a snapshot. You can always go back to a previous version if something breaks.

**To see what's changed** since your last save:
```
git status
```

**To see your history** of saves:
```
git log --oneline
```

## Files in this folder

| File | What it does |
|---|---|
| `popup.ahk` | The main script - launches the popup when you press the hotkey |
| `popup.html` | The popup interface (what you see on screen) |
| `shortcuts.json` | Your shortcuts data - edit this to add/remove shortcuts in bulk |
| `config.json` | Configuration file (reserved for future use) |
| `SETUP.txt` | Detailed setup instructions and troubleshooting |

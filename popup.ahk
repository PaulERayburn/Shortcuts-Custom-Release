; Shortcuts-Custom - AutoHotkey v2 Script
; Created by PaulR and Claude Code
; Toggle popup with configurable hotkey (default: CapsLock + /)

#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================
; CONFIGURATION
; ============================================
; Change this hotkey if needed. Common alternatives:
;   CapsLock & /     (CapsLock + /)
;   ^!s              (Ctrl + Alt + S)
;   ^+/              (Ctrl + Shift + /)
;   F12              (F12 key)
;   #/               (Win + /)

TRIGGER_KEY := "CapsLock & /"

; Popup settings
POPUP_WIDTH := 700
POPUP_HEIGHT := 600
HTML_FILE := A_ScriptDir "\popup.html"

; ============================================
; GLOBALS
; ============================================
global popupHwnd := 0
global previousWindow := 0

; ============================================
; HOTKEY REGISTRATION
; ============================================
; Register the hotkey
Hotkey TRIGGER_KEY, TogglePopup

; Keyboard fix hotkey: CapsLock + "
CapsLock & '::
{
    Run 'explorer.exe /select,"' A_MyDocuments '\Scripts_PR_Shortcuts\Keyboard EnableDisable\Temporary Enable keyboard.bat"'
    ToolTip "Right-click the bat file > Run as administrator"
    SetTimer () => ToolTip(), -4000
}

; Also allow Esc to close when popup is active
#HotIf WinActive("ahk_exe msedge.exe") and WinExist("Shortcuts-Custom")
Escape::ClosePopup()
#HotIf

; ============================================
; FUNCTIONS
; ============================================

TogglePopup(*) {
    global popupHwnd, previousWindow

    ; Check if popup exists and is visible
    if (popupHwnd != 0 && WinExist("ahk_id " popupHwnd)) {
        ClosePopup()
        return
    }

    ; Remember the current window before opening popup
    previousWindow := WinGetID("A")

    ; Calculate center position
    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight
    posX := (screenWidth - POPUP_WIDTH) // 2
    posY := (screenHeight - POPUP_HEIGHT) // 2

    ; Build the Edge command
    edgePath := "msedge.exe"
    edgeArgs := Format('--app="{1}" --window-size={2},{3} --window-position={4},{5}',
        HTML_FILE, POPUP_WIDTH, POPUP_HEIGHT, posX, posY)

    ; Launch Edge in app mode
    Run edgePath " " edgeArgs

    ; Wait for window to appear and get its handle
    if WinWait("Shortcuts-Custom", , 3) {
        popupHwnd := WinGetID("Shortcuts-Custom")
        WinActivate "ahk_id " popupHwnd
    }
}

ClosePopup(*) {
    global popupHwnd, previousWindow

    if (popupHwnd != 0 && WinExist("ahk_id " popupHwnd)) {
        WinClose "ahk_id " popupHwnd
        popupHwnd := 0

        ; Return focus to previous window
        if (previousWindow != 0 && WinExist("ahk_id " previousWindow)) {
            Sleep 50
            WinActivate "ahk_id " previousWindow
        }
    }
}

; ============================================
; TRAY MENU
; ============================================
A_TrayMenu.Delete()
A_TrayMenu.Add("Show Popup", TogglePopup)
A_TrayMenu.Add("Open Shortcuts Folder", OpenFolder)
A_TrayMenu.Add()
A_TrayMenu.Add("Edit Hotkey", EditHotkey)
A_TrayMenu.Add()
A_TrayMenu.Add("Reload Script", ReloadScript)
A_TrayMenu.Add("Exit", ExitScript)
A_TrayMenu.Default := "Show Popup"

OpenFolder(*) {
    Run "explorer.exe " A_ScriptDir
}

EditHotkey(*) {
    MsgBox "To change the hotkey:`n`n1. Open: " A_ScriptDir "\popup.ahk`n2. Find the line: TRIGGER_KEY := `"" TRIGGER_KEY "`"`n3. Change it to your preferred hotkey`n4. Save and reload the script`n`nCommon options:`n  CapsLock & /`n  ^!s (Ctrl+Alt+S)`n  ^+/ (Ctrl+Shift+/)`n  F12", "Edit Hotkey"
}

ReloadScript(*) {
    Reload
}

ExitScript(*) {
    ExitApp
}

; ============================================
; STARTUP
; ============================================
; Show a tooltip on startup
ToolTip "Shortcuts Popup ready!`nPress " TRIGGER_KEY " to toggle"
SetTimer () => ToolTip(), -2000

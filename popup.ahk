; Shortcuts-Custom - AutoHotkey v2 Script
; Created by PaulR and Claude Code
; Toggle popup with configurable hotkey (default: CapsLock + /)

#Requires AutoHotkey v2.0
#SingleInstance Force

; Make DPI-aware so pixel sizes are consistent across monitors
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")  ; Per-Monitor V2

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

; MLS Notes settings
MLS_WIDTH := 500
MLS_HEIGHT := 1050
MLS_HTML_FILE := A_ScriptDir "\mls-notes.html"
MLS_ACTIVE_FILE := A_ScriptDir "\data\mls-active.txt"

; ============================================
; GLOBALS
; ============================================
global popupHwnd := 0
global mlsHwnd := 0
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

; MLS Notes hotkey: CapsLock + .
CapsLock & .::ToggleMlsNotes()

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
        SetTimer CheckForScriptRun, 250
    }
}

ClosePopup(*) {
    global popupHwnd, previousWindow

    if (popupHwnd != 0 && WinExist("ahk_id " popupHwnd)) {
        SetTimer CheckForScriptRun, 0
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
; MLS NOTES FUNCTIONS
; ============================================

ToggleMlsNotes(*) {
    global mlsHwnd, previousWindow

    ; Check if MLS Notes exists and is visible
    if (mlsHwnd != 0 && WinExist("ahk_id " mlsHwnd)) {
        CloseMlsNotes()
        return
    }

    ; Remember the current window before opening
    previousWindow := WinGetID("A")

    ; Pre-load clipboard with disk JSON (uses active project marker)
    loadScript := A_ScriptDir "\scripts\load-mls-notes.ps1"
    if FileExist(MLS_ACTIVE_FILE) {
        Run 'powershell.exe -ExecutionPolicy Bypass -File "' loadScript '"', , "Hide"
        Sleep 500
    } else if FileExist(A_ScriptDir "\data\mls-notes.json") {
        Run 'powershell.exe -ExecutionPolicy Bypass -File "' loadScript '"', , "Hide"
        Sleep 500
    }

    ; Calculate center position
    posX := (A_ScreenWidth - MLS_WIDTH) // 2
    posY := (A_ScreenHeight - MLS_HEIGHT) // 2

    ; Launch Edge in app mode (auto-grant mic for dictation)
    edgePath := "msedge.exe"
    edgeArgs := Format('--app="{1}" --window-size={2},{3} --window-position={4},{5} --auto-accept-camera-and-microphone-capture',
        MLS_HTML_FILE, MLS_WIDTH, MLS_HEIGHT, posX, posY)

    Run edgePath " " edgeArgs

    if WinWait("MLS Notes", , 3) {
        mlsHwnd := WinGetID("MLS Notes")
        WinSetAlwaysOnTop true, "ahk_id " mlsHwnd
        WinActivate "ahk_id " mlsHwnd
        SetTimer CheckForScriptRun, 250
        ; Retry resize — clipboard dialog may delay readiness
        SetTimer ResizeMlsWindow, 500
    }
}

CloseMlsNotes(*) {
    global mlsHwnd, previousWindow

    if (mlsHwnd != 0 && WinExist("ahk_id " mlsHwnd)) {
        SetTimer CheckForScriptRun, 0
        WinClose "ahk_id " mlsHwnd
        mlsHwnd := 0

        if (previousWindow != 0 && WinExist("ahk_id " previousWindow)) {
            Sleep 50
            WinActivate "ahk_id " previousWindow
        }
    }
}

; ============================================
; MLS WINDOW RESIZE (retry until it sticks)
; ============================================
global mlsResizeAttempts := 0

ResizeMlsWindow() {
    global mlsHwnd, mlsResizeAttempts
    mlsResizeAttempts++

    if (mlsHwnd = 0 || !WinExist("ahk_id " mlsHwnd)) {
        SetTimer ResizeMlsWindow, 0
        mlsResizeAttempts := 0
        return
    }

    try {
        WinGetPos(&curX, &curY, &curW, &curH, "ahk_id " mlsHwnd)
        ; Check if already correct size
        if (Abs(curW - MLS_WIDTH) < 20 && Abs(curH - MLS_HEIGHT) < 20) {
            SetTimer ResizeMlsWindow, 0
            mlsResizeAttempts := 0
            return
        }
        posX := (A_ScreenWidth - MLS_WIDTH) // 2
        posY := (A_ScreenHeight - MLS_HEIGHT) // 2
        WinMove posX, posY, MLS_WIDTH, MLS_HEIGHT, "ahk_id " mlsHwnd
    }

    if (mlsResizeAttempts > 20) {
        SetTimer ResizeMlsWindow, 0
        mlsResizeAttempts := 0
    }
}

; ============================================
; SCRIPT RUNNER (title-watching timer)
; ============================================
; Remarks modal size
MLS_REMARKS_WIDTH := 1500
MLS_REMARKS_HEIGHT := 1200

CheckForScriptRun() {
    global mlsHwnd

    ; Handle SIZE:: signals from MLS Notes
    try {
        if WinExist("SIZE::") {
            title := WinGetTitle("SIZE::")
            hwnd := WinGetID("SIZE::")
            try WinSetTitle("MLS Notes", "ahk_id " hwnd)

            ; Get the monitor the window is currently on
            try {
                WinGetPos(&wx, &wy, , , "ahk_id " hwnd)
            } catch {
                wx := 0, wy := 0
            }
            monNum := 0
            Loop MonitorGetCount() {
                MonitorGetWorkArea(A_Index, &mL, &mT, &mR, &mB)
                if (wx >= mL && wx < mR && wy >= mT && wy < mB) {
                    monNum := A_Index
                    break
                }
            }
            if (monNum = 0) {
                monNum := MonitorGetPrimary()
                MonitorGetWorkArea(monNum, &mL, &mT, &mR, &mB)
            }
            monW := mR - mL
            monH := mB - mT

            if InStr(title, "SIZE::REMARKS") {
                rw := Min(MLS_REMARKS_WIDTH, monW - 20)
                rh := Min(MLS_REMARKS_HEIGHT, monH - 40)
                rx := mL + (monW - rw) // 2
                ry := mT + (monH - rh) // 2
                WinMove rx, ry, rw, rh, "ahk_id " hwnd
            } else if InStr(title, "SIZE::COMPACT") {
                pw := Min(MLS_WIDTH, monW - 20)
                ph := Min(MLS_HEIGHT, monH - 40)
                px := mL + (monW - pw) // 2
                py := mT + (monH - ph) // 2
                WinMove px, py, pw, ph, "ahk_id " hwnd
            }
        }
    }

    ; Find any window whose title contains RUN::
    try {
        if WinExist("RUN::") {
            title := WinGetTitle("RUN::")
            hwnd := WinGetID("RUN::")

            runPos := InStr(title, "RUN::")
            scriptPath := SubStr(title, runPos + 5)
            ; Reset title (detect which window it came from)
            if (hwnd = mlsHwnd) {
                try WinSetTitle("MLS Notes", "ahk_id " hwnd)
            } else {
                try WinSetTitle("Shortcuts-Custom", "ahk_id " hwnd)
            }

            ; Strip any surrounding quotes
            scriptPath := Trim(scriptPath, '" ')

            if (scriptPath = "")
                return

            ; Determine how to run based on extension
            SplitPath scriptPath, , , &ext
            ext := StrLower(ext)

            if (ext = "ps1") {
                Run 'powershell.exe -ExecutionPolicy Bypass -File "' scriptPath '"'
            } else if (ext = "bat" || ext = "cmd") {
                Run A_ComSpec ' /c "' scriptPath '"'
            } else {
                Run '"' scriptPath '"'
            }

            ToolTip "Launched: " scriptPath
            SetTimer () => ToolTip(), -2000
        }
    } catch {
        return
    }
}

; ============================================
; TRAY MENU
; ============================================
A_TrayMenu.Delete()
A_TrayMenu.Add("Show Popup", TogglePopup)
A_TrayMenu.Add("MLS Notes", ToggleMlsNotes)
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

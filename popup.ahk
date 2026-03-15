; Shortcuts-Custom - AutoHotkey v2 Script
; Created by PaulR and Claude Code
; Toggle popup with configurable hotkey (default: CapsLock + /)

#Requires AutoHotkey v2.0
#SingleInstance Force

; Make DPI-aware so pixel sizes are consistent across monitors
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")  ; Per-Monitor V2

; ============================================
; HOTKEY CONFIGURATION
; ============================================
; Change any hotkey below to avoid conflicts or match your preferences.
; AutoHotkey syntax reference:
;   CapsLock & /     CapsLock + /          ^   = Ctrl
;   ^!s              Ctrl + Alt + S        !   = Alt
;   ^+/              Ctrl + Shift + /      +   = Shift
;   F12              F12 key               #   = Win
;   #/               Win + /               & = combines two keys
;   Note: the backtick (`) before ; is required — it tells AHK
;   the semicolon is a key, not a comment. Don't remove it.

KEY_POPUP       := "CapsLock & /"    ; Open/close the shortcuts popup
KEY_COLLECT     := "CapsLock & `;"    ; Collect selected text (CapsLock + ;)
KEY_NEW_LIST    := "CapsLock & `;"    ; (with Shift held) New list from clipboard
KEY_PASTE       := "CapsLock & ]"    ; Paste all collected items
KEY_VIEWER      := "CapsLock & BS"   ; Open/close the Collector viewer
KEY_KB_FIX      := "CapsLock & '"    ; Keyboard fix utility (optional — delete if not needed)
KEY_STT         := "CapsLock & ,"    ; Open/close Speech to Text
KEY_QUICK_DICT  := "CapsLock & m"    ; (with Shift held) Quick dictate (toggle record)
KEY_QUICK_PASTE := "CapsLock & n"    ; (with Shift held) Grab STT text and paste

; POPUP WINDOW
POPUP_WIDTH := 700
POPUP_HEIGHT := 600
HTML_FILE := A_ScriptDir "\popup.html"

; SPEECH TO TEXT WINDOW
STT_WIDTH := 600
STT_HEIGHT := 700
STT_HTML_FILE := A_ScriptDir "\speech-to-text.html"

; COLLECTOR WINDOW
COLLECTOR_WIDTH := 450
COLLECTOR_HEIGHT := 520
COLLECTOR_HTML_FILE := A_ScriptDir "\collector.html"
COLLECTOR_DATA_FILE := A_ScriptDir "\collector-data.js"

; ============================================
; GLOBALS
; ============================================
global popupHwnd := 0
global sttHwnd := 0
global collectorHwnd := 0
global previousWindow := 0
global collectorLists := Map()
global activeListName := ""
global quickDictateReturnWin := 0

; ============================================
; HOTKEY REGISTRATION
; ============================================
Hotkey KEY_POPUP, TogglePopup
Hotkey KEY_KB_FIX, KeyboardFixHotkey
; Shift variant of collect key = new list from clipboard (must register before plain version)
HotIf (*) => GetKeyState("Shift", "P")
Hotkey KEY_NEW_LIST, NewListFromClipboardHotkey
HotIf
Hotkey KEY_COLLECT, CollectSelection
Hotkey KEY_PASTE, PasteCollected
Hotkey KEY_VIEWER, ToggleCollector
Hotkey KEY_STT, ToggleSpeechToText
; Shift variants of quick-dictate keys
HotIf (*) => GetKeyState("Shift", "P")
Hotkey KEY_QUICK_DICT, QuickDictateHotkey
Hotkey KEY_QUICK_PASTE, QuickPasteHotkey
HotIf

; Keyboard fix function
KeyboardFixHotkey(*) {
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

    ; Remember the current window before opening popup (may not exist)
    try {
        previousWindow := WinGetID("A")
    } catch {
        previousWindow := 0
    }

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
        WinClose "ahk_id " popupHwnd
        popupHwnd := 0
        StopTimerIfNoWindows()

        ; Return focus to previous window
        if (previousWindow != 0 && WinExist("ahk_id " previousWindow)) {
            Sleep 50
            WinActivate "ahk_id " previousWindow
        }
    }
}

; ============================================
; SCRIPT RUNNER (title-watching timer)
; ============================================

CheckForScriptRun() {
    global collectorHwnd, collectorLists, activeListName, quickDictateReturnWin, sttHwnd

    ; Handle COLLECTOR:: signals from viewer
    try {
        if WinExist("COLLECTOR::") {
            title := WinGetTitle("COLLECTOR::")
            hwnd := WinGetID("COLLECTOR::")
            try WinSetTitle("Collector", "ahk_id " hwnd)

            rest := SubStr(title, 12)  ; after "COLLECTOR::"
            parts := StrSplit(rest, "::",, 3)
            action := parts.Length >= 1 ? parts[1] : ""
            param1 := parts.Length >= 2 ? parts[2] : ""
            param2 := parts.Length >= 3 ? parts[3] : ""

            if (action = "REMOVE" && param1 != "" && param2 != "") {
                idx := Integer(param2)
                if (collectorLists.Has(param1) && idx >= 1 && idx <= collectorLists[param1].Length)
                    collectorLists[param1].RemoveAt(idx)
            }
            else if (action = "CLEAR_LIST" && param1 != "") {
                if collectorLists.Has(param1)
                    collectorLists[param1] := []
            }
            else if (action = "DELETE_LIST" && param1 != "") {
                if collectorLists.Has(param1) {
                    collectorLists.Delete(param1)
                    if (activeListName = param1) {
                        activeListName := ""
                        for name, _ in collectorLists {
                            activeListName := name
                            break
                        }
                    }
                }
            }
            else if (action = "NEW_LIST" && param1 != "") {
                if !collectorLists.Has(param1)
                    collectorLists[param1] := []
                activeListName := param1
            }
            else if (action = "RENAME_LIST" && param1 != "" && param2 != "") {
                if (collectorLists.Has(param1) && !collectorLists.Has(param2)) {
                    collectorLists[param2] := collectorLists[param1]
                    collectorLists.Delete(param1)
                    if (activeListName = param1)
                        activeListName := param2
                }
            }
            else if (action = "SWITCH" && param1 != "") {
                if collectorLists.Has(param1)
                    activeListName := param1
            }
            else if (action = "ADD" && param1 != "" && param2 != "") {
                if !collectorLists.Has(param1)
                    collectorLists[param1] := []
                collectorLists[param1].Push(param2)
            }
            WriteCollectorFile()
        }
    }

    ; Handle STT:: signals from Speech to Text
    try {
        if WinExist("STT::") {
            title := WinGetTitle("STT::")
            hwnd := WinGetID("STT::")
            try WinSetTitle("Speech to Text", "ahk_id " hwnd)

            if InStr(title, "STT::PASTE") {
                ; Auto Paste: JS already copied text to clipboard, just switch back and paste
                targetWin := quickDictateReturnWin
                ; Fallback: if no return window saved, find the previously active non-STT window
                if (targetWin = 0 || !WinExist("ahk_id " targetWin)) {
                    try {
                        for hwnd in WinGetList() {
                            winTitle := WinGetTitle("ahk_id " hwnd)
                            if (hwnd != sttHwnd && winTitle != "" && !InStr(winTitle, "Speech to Text")) {
                                targetWin := hwnd
                                break
                            }
                        }
                    }
                }
                if (targetWin != 0 && WinExist("ahk_id " targetWin)) {
                    Sleep 200
                    WinActivate "ahk_id " targetWin
                    Sleep 150
                    Send "^v"
                    ToolTip "Dictation pasted"
                    SetTimer () => ToolTip(), -2000
                }
            }
        }
    }

    ; Handle OPEN:: signals from popup
    try {
        if WinExist("OPEN::") {
            title := WinGetTitle("OPEN::")
            hwnd := WinGetID("OPEN::")
            try WinSetTitle("Shortcuts-Custom", "ahk_id " hwnd)
            if InStr(title, "OPEN::COLLECTOR")
                ToggleCollector()
        }
    }

    ; Find any window whose title contains RUN::
    try {
        if WinExist("RUN::") {
            title := WinGetTitle("RUN::")
            hwnd := WinGetID("RUN::")

            runPos := InStr(title, "RUN::")
            scriptPath := SubStr(title, runPos + 5)
            ; Reset title
            try WinSetTitle("Shortcuts-Custom", "ahk_id " hwnd)

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
; SPEECH TO TEXT FUNCTIONS
; ============================================

ToggleSpeechToText(*) {
    global sttHwnd, previousWindow

    if (sttHwnd != 0 && WinExist("ahk_id " sttHwnd)) {
        CloseSpeechToText()
        return
    }

    try {
        previousWindow := WinGetID("A")
    } catch {
        previousWindow := 0
    }

    posX := (A_ScreenWidth - STT_WIDTH) // 2
    posY := (A_ScreenHeight - STT_HEIGHT) // 2

    edgePath := "msedge.exe"
    edgeArgs := Format('--app="{1}" --window-size={2},{3} --window-position={4},{5} --auto-accept-camera-and-microphone-capture',
        STT_HTML_FILE, STT_WIDTH, STT_HEIGHT, posX, posY)

    Run edgePath " " edgeArgs

    if WinWait("Speech to Text", , 3) {
        sttHwnd := WinGetID("Speech to Text")
        WinSetAlwaysOnTop true, "ahk_id " sttHwnd
        WinActivate "ahk_id " sttHwnd
        SetTimer CheckForScriptRun, 250
    }
}

CloseSpeechToText(*) {
    global sttHwnd, previousWindow

    if (sttHwnd != 0 && WinExist("ahk_id " sttHwnd)) {
        WinClose "ahk_id " sttHwnd
        sttHwnd := 0
        StopTimerIfNoWindows()

        if (previousWindow != 0 && WinExist("ahk_id " previousWindow)) {
            Sleep 50
            WinActivate "ahk_id " previousWindow
        }
    }
}

; Quick dictate: Shift+CapsLock+M from any app
; First press → open STT + start recording
; Second press → grab text, switch back, paste
; Shift+CapsLock+M — toggle recording (open STT if needed)
QuickDictateHotkey(*) {
    global sttHwnd, quickDictateReturnWin

    KeyWait "CapsLock"
    KeyWait "Shift"
    KeyWait "m"
    Sleep 50

    ; Remember the window to return to (only when starting, not stopping)
    if (sttHwnd = 0 || !WinExist("ahk_id " sttHwnd)) {
        try quickDictateReturnWin := WinGetID("A")
        catch
            quickDictateReturnWin := 0

        ToggleSpeechToText()
        ; Wait for Edge to fully load
        waited := 0
        while (waited < 5000) {
            Sleep 200
            waited += 200
            if (sttHwnd != 0 && WinExist("ahk_id " sttHwnd)) {
                try {
                    title := WinGetTitle("ahk_id " sttHwnd)
                    if (title = "Speech to Text")
                        break
                }
            }
        }
        ; Start recording
        if (sttHwnd != 0 && WinExist("ahk_id " sttHwnd)) {
            WinActivate "ahk_id " sttHwnd
            Sleep 100
            Send "{F8}"
        }
        ToolTip "Recording... Shift+CapsLock+M to stop, Shift+CapsLock+N to paste"
        SetTimer () => ToolTip(), -5000
    } else {
        ; STT is already open — save return window and toggle mic
        ; Only save if current window is NOT the STT window
        try {
            activeWin := WinGetID("A")
            if (activeWin != sttHwnd)
                quickDictateReturnWin := activeWin
        }
        WinActivate "ahk_id " sttHwnd
        Sleep 100
        Send "{F8}"
        ToolTip "Mic toggled — Shift+CapsLock+N to paste"
        SetTimer () => ToolTip(), -3000
    }
}

; Shift+CapsLock+N — grab text from STT and paste into original app
QuickPasteHotkey(*) {
    global sttHwnd, quickDictateReturnWin

    KeyWait "CapsLock"
    KeyWait "Shift"
    KeyWait "n"
    Sleep 50

    if (sttHwnd = 0 || !WinExist("ahk_id " sttHwnd)) {
        ToolTip "STT not open — nothing to paste"
        SetTimer () => ToolTip(), -2000
        return
    }

    oldClip := A_Clipboard

    ; Activate STT, brief pause, send F9 to grab
    WinActivate "ahk_id " sttHwnd
    Sleep 300
    Send "{F9}"

    ; Wait for clipboard to change
    waited := 0
    while (A_Clipboard == oldClip && waited < 3000) {
        Sleep 50
        waited += 50
    }

    ; Switch back and paste
    if (quickDictateReturnWin != 0 && WinExist("ahk_id " quickDictateReturnWin)) {
        WinActivate "ahk_id " quickDictateReturnWin
        Sleep 150
        Send "^v"
        ToolTip "Dictation pasted"
        SetTimer () => ToolTip(), -2000
    }
}

; ============================================
; CLIPBOARD COLLECTOR
; ============================================

CollectSelection(*) {
    global collectorLists, activeListName
    prevClip := A_Clipboard
    A_Clipboard := ""
    KeyWait "CapsLock"
    Send "^c"
    if !ClipWait(1) {
        A_Clipboard := prevClip
        ToolTip "Nothing selected to collect"
        SetTimer () => ToolTip(), -1500
        return
    }
    item := Trim(A_Clipboard, " `t`r`n")
    A_Clipboard := prevClip

    if (item = "") {
        ToolTip "Empty selection"
        SetTimer () => ToolTip(), -1500
        return
    }

    ; Create default list if none exists
    if (activeListName = "" || !collectorLists.Has(activeListName)) {
        if (activeListName = "")
            activeListName := "List 1"
        if !collectorLists.Has(activeListName)
            collectorLists[activeListName] := []
    }

    collectorLists[activeListName].Push(item)
    WriteCollectorFile()

    items := collectorLists[activeListName]
    count := items.Length
    preview := ""
    startIdx := Max(1, count - 4)
    Loop count - startIdx + 1 {
        idx := startIdx + A_Index - 1
        if (preview != "")
            preview .= "  "
        preview .= items[idx]
    }
    if (startIdx > 1)
        preview := "... " preview

    ToolTip "[" activeListName "] (" count "): " preview
    SetTimer () => ToolTip(), -3000
}

NewListFromClipboardHotkey(*) {
    KeyWait "CapsLock"
    NewListFromClipboard()
}

NewListFromClipboard() {
    global collectorLists, activeListName
    listName := Trim(A_Clipboard, " `t`r`n")
    if (listName = "") {
        ToolTip "Clipboard is empty — copy an address first"
        SetTimer () => ToolTip(), -2000
        return
    }
    ; Truncate very long names
    if (StrLen(listName) > 60)
        listName := SubStr(listName, 1, 60)
    if !collectorLists.Has(listName)
        collectorLists[listName] := []
    activeListName := listName
    WriteCollectorFile()
    ToolTip "New list: [" listName "]`nCapsLock+; to collect items"
    SetTimer () => ToolTip(), -3000
}

PasteCollected(*) {
    global collectorLists, activeListName
    if (activeListName = "" || !collectorLists.Has(activeListName) || collectorLists[activeListName].Length = 0) {
        ToolTip "Collector is empty"
        SetTimer () => ToolTip(), -1500
        return
    }

    items := collectorLists[activeListName]
    result := ""
    for idx, item in items {
        if (idx > 1)
            result .= " "
        result .= item
    }

    A_Clipboard := result
    KeyWait "CapsLock"
    Send "^v"

    ToolTip "Pasted " items.Length " items from [" activeListName "]"
    SetTimer () => ToolTip(), -2500
}

; ============================================
; COLLECTOR VIEWER POPUP
; ============================================

ToggleCollector(*) {
    global collectorHwnd, previousWindow

    if (collectorHwnd != 0 && WinExist("ahk_id " collectorHwnd)) {
        CloseCollector()
        return
    }

    try {
        previousWindow := WinGetID("A")
    } catch {
        previousWindow := 0
    }

    WriteCollectorFile()

    posX := (A_ScreenWidth - COLLECTOR_WIDTH) // 2
    posY := (A_ScreenHeight - COLLECTOR_HEIGHT) // 2

    edgePath := "msedge.exe"
    edgeArgs := Format('--app="{1}" --window-size={2},{3} --window-position={4},{5}',
        COLLECTOR_HTML_FILE, COLLECTOR_WIDTH, COLLECTOR_HEIGHT, posX, posY)

    Run edgePath " " edgeArgs

    if WinWait("Collector", , 3) {
        collectorHwnd := WinGetID("Collector")
        WinActivate "ahk_id " collectorHwnd
        SetTimer CheckForScriptRun, 250
    }
}

CloseCollector(*) {
    global collectorHwnd, previousWindow

    if (collectorHwnd != 0 && WinExist("ahk_id " collectorHwnd)) {
        WinClose "ahk_id " collectorHwnd
        collectorHwnd := 0
        StopTimerIfNoWindows()

        if (previousWindow != 0 && WinExist("ahk_id " previousWindow)) {
            Sleep 50
            WinActivate "ahk_id " previousWindow
        }
    }
}

WriteCollectorFile() {
    global collectorLists, activeListName
    js := "window._collectorData = {"
    js .= '"activeList":"' EscapeJsonString(activeListName) '",'
    js .= '"lists":{'
    first := true
    for name, items in collectorLists {
        if (!first)
            js .= ","
        first := false
        js .= '"' EscapeJsonString(name) '":['
        for idx, item in items {
            if (idx > 1)
                js .= ","
            js .= '"' EscapeJsonString(item) '"'
        }
        js .= "]"
    }
    js .= "}};`n"
    try FileDelete(COLLECTOR_DATA_FILE)
    try FileAppend(js, COLLECTOR_DATA_FILE)
}

StopTimerIfNoWindows() {
    global popupHwnd, sttHwnd, collectorHwnd
    popupAlive := (popupHwnd != 0 && WinExist("ahk_id " popupHwnd))
    sttAlive := (sttHwnd != 0 && WinExist("ahk_id " sttHwnd))
    collectorAlive := (collectorHwnd != 0 && WinExist("ahk_id " collectorHwnd))
    if (!popupAlive && !sttAlive && !collectorAlive)
        SetTimer CheckForScriptRun, 0
}

EscapeJsonString(str) {
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, '"', '\"')
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`r", "\r")
    str := StrReplace(str, "`t", "\t")
    return str
}

; ============================================
; TRAY MENU
; ============================================
A_TrayMenu.Delete()
A_TrayMenu.Add("Show Popup", TogglePopup)
A_TrayMenu.Add("Speech to Text", ToggleSpeechToText)
A_TrayMenu.Add("Collector", ToggleCollector)
A_TrayMenu.Add()
A_TrayMenu.Add("Edit Hotkey", EditHotkey)
A_TrayMenu.Add()
A_TrayMenu.Add("Reload Script", ReloadScript)
A_TrayMenu.Add("Exit", ExitScript)
A_TrayMenu.Default := "Show Popup"

EditHotkey(*) {
    MsgBox "To change hotkeys:`n`n1. Open: " A_ScriptDir "\popup.ahk`n2. Edit the KEY_* variables near the top`n3. Save and reload the script`n`nCurrent keys:`n  Popup: " KEY_POPUP "`n  Collect: " KEY_COLLECT "`n  Paste: " KEY_PASTE "`n  Viewer: " KEY_VIEWER, "Edit Hotkeys"
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
ToolTip "Shortcuts Popup ready!`nPress " KEY_POPUP " to toggle`n" KEY_COLLECT " collect | Shift+" KEY_NEW_LIST " new list | " KEY_PASTE " paste | " KEY_VIEWER " viewer"
SetTimer () => ToolTip(), -3000

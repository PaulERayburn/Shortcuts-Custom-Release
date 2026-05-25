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
KEY_READ_ALOUD  := "CapsLock & r"    ; Read selected text aloud (press again to stop)
KEY_EXPLAIN_PERM := "CapsLock & p"   ; Explain a permission / tool request in plain English (double-tap = full breakdown)
KEY_HARD_STOP   := "CapsLock & Escape" ; Hard stop — kills ALL speech (SAPI + pending AI calls)
KEY_REREAD      := "CapsLock & h"    ; Re-read last AI output (Shift+ variant = open History viewer)
KEY_AI_ASSIST   := "CapsLock & ["    ; Open/close AI Assist
KEY_AI_QUICK    := "CapsLock & l"    ; DISABLED 2026-05 — was Shift+CapsLock+L → STT Quick Clean (use STT window's Ctrl+Shift+L directly)
KEY_AI_DEEP     := "CapsLock & p"    ; DISABLED 2026-05 — was Shift+CapsLock+P → STT Deep Edit. Note: plain CapsLock+P is now Explain Permission.

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

; AI ASSIST WINDOW
AI_WIDTH := 650
AI_HEIGHT := 750
AI_HTML_FILE := A_ScriptDir "\ai-assist.html"

; AI HISTORY WINDOW (last AI Read / Explain output)
AI_HISTORY_WIDTH := 640
AI_HISTORY_HEIGHT := 640
AI_HISTORY_HTML_FILE := A_ScriptDir "\ai-history.html"
AI_HISTORY_DATA_FILE := A_ScriptDir "\ai-history-data.js"
AI_LAST_FILE := A_ScriptDir "\ai-last.json"

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
global ttsVoice := 0
global ttsPrimaryVoice := 0
global ttsNoteVoice := 0
global ttsChunks := []
global ttsChunkIdx := 1
global ttsActive := false
global aiReadPendingText := ""
global aiReadTimerCallback := 0
global aiPermPendingText := ""
global aiPermTimerCallback := 0
global lastSelectionWasTerminal := false
global aiHistoryHwnd := 0
global lastAIOutput := ""
global lastAIMode := ""
global lastAIModel := ""
global lastAIInput := ""
global lastAITimestamp := ""
global aiAssistHwnd := 0

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
Hotkey KEY_AI_ASSIST, ToggleAIAssist
; Shift variants of quick-dictate keys
HotIf (*) => GetKeyState("Shift", "P")
Hotkey KEY_QUICK_DICT, QuickDictateHotkey
Hotkey KEY_QUICK_PASTE, QuickPasteHotkey
; --- Legacy STT-agent shortcuts intentionally DISABLED (2026-05) ---
; Shift+CapsLock+L (AIQuickCleanHotkey) and Shift+CapsLock+P
; (AIDeepEditHotkey) used to forward keystrokes into the STT window's
; cleanup agents. They required STT open and produced a misleading
; "open Speech to Text first (CapsLock+,)" tooltip when fired by accident
; while users actually wanted the new AI read / explain features.
; Use Shift+CapsLock+R (AI read) and CapsLock+P (explain) instead. The
; old agents are still accessible by clicking their buttons inside the
; STT window itself.
; Hotkey KEY_AI_QUICK, AIQuickCleanHotkey
; Hotkey KEY_AI_DEEP, AIDeepEditHotkey
Hotkey KEY_READ_ALOUD, AIReadAloudHotkey   ; Shift+CapsLock+r — AI-prep + read
HotIf
Hotkey KEY_READ_ALOUD, ReadAloudHotkey      ; CapsLock+r — raw read
Hotkey KEY_EXPLAIN_PERM, ExplainPermissionHotkey  ; CapsLock+p — explain permission (double-tap = full)
Hotkey KEY_HARD_STOP, HardStopHotkey              ; CapsLock+Esc — hard stop all speech
Hotkey KEY_REREAD, ReReadLastHotkey               ; CapsLock+h — re-read last AI output
HotIf (*) => GetKeyState("Shift", "P")
Hotkey KEY_REREAD, ToggleAIHistory                 ; Shift+CapsLock+h — open History viewer
HotIf


; Keyboard fix function
KeyboardFixHotkey(*) {
    Run 'explorer.exe /select,"' A_MyDocuments '\Scripts\enable-keyboard.bat"'
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

    ; Calculate center position (with cascade offset if other popups are open)
    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight
    cascade := CascadeOffset()
    posX := (screenWidth - POPUP_WIDTH) // 2 + cascade
    posY := (screenHeight - POPUP_HEIGHT) // 2 + cascade

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
    global collectorHwnd, collectorLists, activeListName, quickDictateReturnWin, sttHwnd, aiAssistHwnd

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

    ; Handle AI_ASSIST:: signals from AI Assist
    try {
        if WinExist("AI_ASSIST::") {
            title := WinGetTitle("AI_ASSIST::")
            hwnd := WinGetID("AI_ASSIST::")
            try WinSetTitle("AI Assist", "ahk_id " hwnd)

            if InStr(title, "AI_ASSIST::PASTE") {
                targetWin := previousWindow
                if (targetWin = 0 || !WinExist("ahk_id " targetWin)) {
                    try {
                        for hwnd in WinGetList() {
                            winTitle := WinGetTitle("ahk_id " hwnd)
                            if (hwnd != aiAssistHwnd && winTitle != "" && !InStr(winTitle, "AI Assist")) {
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
                    ToolTip "AI text pasted"
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
            ; Reset title (detect which window it came from)
            if (hwnd = aiAssistHwnd) {
                try WinSetTitle("AI Assist", "ahk_id " hwnd)
            } else if (hwnd = sttHwnd) {
                try WinSetTitle("Speech to Text", "ahk_id " hwnd)
            } else {
                try WinSetTitle("Shortcuts-Custom", "ahk_id " hwnd)
            }

            ; Strip any surrounding quotes
            scriptPath := Trim(scriptPath, '" ')

            if (scriptPath = "")
                return

            ; Resolve relative paths against script directory
            if (!InStr(scriptPath, "\") && !InStr(scriptPath, "/"))
                scriptPath := A_ScriptDir "\" scriptPath

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

    cascade := CascadeOffset()
    posX := (A_ScreenWidth - STT_WIDTH) // 2 + cascade
    posY := (A_ScreenHeight - STT_HEIGHT) // 2 + cascade

    edgePath := "msedge.exe"
    ; STT runs in a DEDICATED Edge profile/process — fixes two long-standing issues:
    ;   1. --auto-accept-camera-and-microphone-capture was being silently ignored
    ;      because Edge was always already running; new STT windows joined the
    ;      existing process tree. A dedicated --user-data-dir forces a fresh
    ;      process, where the auto-accept flag is honored.
    ;   2. file:// URLs are "unique security origins" in modern Edge, so mic
    ;      permission can't persist between launches and same-origin operations
    ;      fail. --allow-file-access-from-files relaxes this restriction.
    ; The dedicated profile dir ALSO means STT's localStorage (API key,
    ; appraiser agents, learned terms, usage stats) is independent of every
    ; other Edge window. Migrate via STT → Help tab → Export/Import Settings.
    sttProfileDir := A_ScriptDir "\stt-edge-profile"
    ; Background-priority flags so STT keeps recording at full speed even
    ; when another window is focused. Without these, Edge throttles the
    ; renderer once STT is backgrounded, which can stall the mic capture.
    edgeArgs := Format('--app="{1}" --window-size={2},{3} --window-position={4},{5} --user-data-dir="{6}" --allow-file-access-from-files --auto-accept-camera-and-microphone-capture --no-first-run --no-default-browser-check --disable-background-timer-throttling --disable-renderer-backgrounding --disable-backgrounding-occluded-windows',
        STT_HTML_FILE, STT_WIDTH, STT_HEIGHT, posX, posY, sttProfileDir)

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
    global sttHwnd, quickDictateReturnWin, previousWindow

    KeyWait "CapsLock"
    KeyWait "Shift"
    KeyWait "n"
    Sleep 50

    if (sttHwnd = 0 || !WinExist("ahk_id " sttHwnd)) {
        ToolTip "STT not open — nothing to paste"
        SetTimer () => ToolTip(), -2000
        return
    }

    ; Priority: wherever the cursor IS right now > saved return window > previousWindow
    pasteTarget := 0
    try {
        activeWin := WinGetID("A")
        if (activeWin != sttHwnd)
            pasteTarget := activeWin
    }

    ; Only fall back to saved windows if user is currently IN the STT window
    if (pasteTarget = 0 || !WinExist("ahk_id " pasteTarget)) {
        if (quickDictateReturnWin != 0 && WinExist("ahk_id " quickDictateReturnWin))
            pasteTarget := quickDictateReturnWin
        else if (previousWindow != 0 && WinExist("ahk_id " previousWindow) && previousWindow != sttHwnd)
            pasteTarget := previousWindow
    }

    oldClip := A_Clipboard

    ; Activate STT, brief pause, send F9 to grab
    WinActivate "ahk_id " sttHwnd
    Sleep 300
    Send "{F9}"
    ToolTip "Waiting for transcription..."

    ; Wait for clipboard to change (up to 35s for Whisper API)
    waited := 0
    while (A_Clipboard == oldClip && waited < 35000) {
        Sleep 50
        waited += 50
    }

    ; Minimize STT window, switch back and paste
    WinMinimize "ahk_id " sttHwnd
    if (pasteTarget != 0 && WinExist("ahk_id " pasteTarget)) {
        WinActivate "ahk_id " pasteTarget
        Sleep 150
        Send "^v"
        ToolTip "Dictation pasted"
        SetTimer () => ToolTip(), -2000
    } else {
        ToolTip "Text copied to clipboard (no target window found)"
        SetTimer () => ToolTip(), -3000
    }
}

; ============================================
; LEGACY STT AGENT HOTKEYS — DISABLED 2026-05
; ============================================
; These functions used to back Shift+CapsLock+L / Shift+CapsLock+P,
; forwarding ^+l / ^+p into the STT window's cleanup agents. They are
; no longer bound to any hotkey (see HOTKEY REGISTRATION section). The
; STT cleanup agents are still reachable from inside the STT window
; (Ctrl+Shift+L / Ctrl+Shift+P when the window is focused). Functions
; retained so re-enabling is a one-line uncomment if ever needed.

AIQuickCleanHotkey(*) {
    SendAgentKeystroke("^+l")
}

AIDeepEditHotkey(*) {
    SendAgentKeystroke("^+p")
}

SendAgentKeystroke(keys) {
    global sttHwnd

    KeyWait "CapsLock"
    KeyWait "Shift"
    Sleep 50

    if (sttHwnd = 0 || !WinExist("ahk_id " sttHwnd)) {
        ToolTip "STT not open. (For the AI reader use Shift+CapsLock+R; for Explain use CapsLock+P.)"
        SetTimer () => ToolTip(), -3500
        return
    }

    WinActivate "ahk_id " sttHwnd
    Sleep 150
    Send keys
}

; ============================================
; AI ASSIST FUNCTIONS
; ============================================

ToggleAIAssist(*) {
    global aiAssistHwnd, previousWindow

    if (aiAssistHwnd != 0 && WinExist("ahk_id " aiAssistHwnd)) {
        CloseAIAssist()
        return
    }

    try {
        previousWindow := WinGetID("A")
    } catch {
        previousWindow := 0
    }

    cascade := CascadeOffset()
    posX := (A_ScreenWidth - AI_WIDTH) // 2 + cascade
    posY := (A_ScreenHeight - AI_HEIGHT) // 2 + cascade

    edgePath := "msedge.exe"
    edgeArgs := Format('--app="{1}" --window-size={2},{3} --window-position={4},{5}',
        AI_HTML_FILE, AI_WIDTH, AI_HEIGHT, posX, posY)

    Run edgePath " " edgeArgs

    if WinWait("AI Assist", , 3) {
        aiAssistHwnd := WinGetID("AI Assist")
        WinActivate "ahk_id " aiAssistHwnd
        SetTimer CheckForScriptRun, 250
    }
}

CloseAIAssist(*) {
    global aiAssistHwnd, previousWindow

    if (aiAssistHwnd != 0 && WinExist("ahk_id " aiAssistHwnd)) {
        WinClose "ahk_id " aiAssistHwnd
        aiAssistHwnd := 0
        StopTimerIfNoWindows()

        if (previousWindow != 0 && WinExist("ahk_id " previousWindow)) {
            Sleep 50
            WinActivate "ahk_id " previousWindow
        }
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

    cascade := CascadeOffset()
    posX := (A_ScreenWidth - COLLECTOR_WIDTH) // 2 + cascade
    posY := (A_ScreenHeight - COLLECTOR_HEIGHT) // 2 + cascade

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

; Returns a cascade offset (px) for the next popup so windows don't all stack
; on the same screen-center point. Wraps after 5 popups so a 6th lands back
; at center instead of drifting off-screen.
CascadeOffset() {
    global popupHwnd, sttHwnd, collectorHwnd, aiAssistHwnd, aiHistoryHwnd
    c := 0
    if (popupHwnd      != 0 && WinExist("ahk_id " popupHwnd))
        c += 1
    if (sttHwnd        != 0 && WinExist("ahk_id " sttHwnd))
        c += 1
    if (collectorHwnd  != 0 && WinExist("ahk_id " collectorHwnd))
        c += 1
    if (aiAssistHwnd   != 0 && WinExist("ahk_id " aiAssistHwnd))
        c += 1
    if (aiHistoryHwnd  != 0 && WinExist("ahk_id " aiHistoryHwnd))
        c += 1
    return Mod(c, 5) * 36
}

StopTimerIfNoWindows() {
    global popupHwnd, sttHwnd, collectorHwnd, aiAssistHwnd, aiHistoryHwnd
    popupAlive := (popupHwnd != 0 && WinExist("ahk_id " popupHwnd))
    sttAlive := (sttHwnd != 0 && WinExist("ahk_id " sttHwnd))
    collectorAlive := (collectorHwnd != 0 && WinExist("ahk_id " collectorHwnd))
    aiAlive := (aiAssistHwnd != 0 && WinExist("ahk_id " aiAssistHwnd))
    histAlive := (aiHistoryHwnd != 0 && WinExist("ahk_id " aiHistoryHwnd))
    if (!popupAlive && !sttAlive && !collectorAlive && !aiAlive && !histAlive)
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
A_TrayMenu.Add("AI Assist", ToggleAIAssist)
A_TrayMenu.Add("Collector", ToggleCollector)
A_TrayMenu.Add("AI History", ToggleAIHistory)
A_TrayMenu.Add()
A_TrayMenu.Add("Edit Hotkey", EditHotkey)
A_TrayMenu.Add("Set AI Keys...", SetAIKeysMenu)
A_TrayMenu.Add("AI Read Provider...", SetAIProviderMenu)
A_TrayMenu.Add()
A_TrayMenu.Add("Reload Script", ReloadScript)
A_TrayMenu.Add("Exit", ExitScript)
A_TrayMenu.Default := "Show Popup"

EditHotkey(*) {
    MsgBox "To change hotkeys:`n`n1. Open: " A_ScriptDir "\popup.ahk`n2. Edit the KEY_* variables near the top`n3. Save and reload the script`n`nCurrent keys:`n  Popup: " KEY_POPUP "`n  Collect: " KEY_COLLECT "`n  Paste: " KEY_PASTE "`n  Viewer: " KEY_VIEWER "`n  AI Assist: " KEY_AI_ASSIST, "Edit Hotkeys"
}

ReloadScript(*) {
    Reload
}

ExitScript(*) {
    ExitApp
}

; ============================================
; READ ALOUD (Text-to-Speech via Windows SAPI)
; ============================================
; Two entry points:
;   ReadAloudHotkey     — CapsLock+r        — raw read of selection
;   AIReadAloudHotkey   — Shift+CapsLock+r  — AI-prep then read (single tap
;                                              = "clean", double-tap within
;                                              500ms = "summarize")
;
; Both pipe through SpeakChunks(), which handles a queue of {type, body}
; chunks asynchronously and switches SAPI voice for [[NOTE: ...]] callouts
; emitted by the AI.

InitTtsVoices() {
    global ttsVoice, ttsPrimaryVoice, ttsNoteVoice
    if IsObject(ttsVoice)
        return true
    try ttsVoice := ComObject("SAPI.SpVoice")
    catch {
        return false
    }
    voices := ttsVoice.GetVoices()
    if (voices.Count >= 1)
        ttsPrimaryVoice := voices.Item(0)
    ; Use a different voice for inline AI insights when one is available
    if (voices.Count >= 2)
        ttsNoteVoice := voices.Item(1)
    else
        ttsNoteVoice := ttsPrimaryVoice
    return true
}

IsTerminalWindow() {
    try {
        cls := WinGetClass("A")
        if (cls = "CASCADIA_HOSTING_WINDOW_CLASS"   ; Windows Terminal / Claude Code embedded
         || cls = "ConsoleWindowClass"               ; classic cmd / conhost
         || cls = "VirtualConsoleClass"              ; ConEmu / Cmder
         || cls = "PuTTY"
         || cls = "mintty"
         || cls = "Vim"
         || InStr(cls, "Terminal"))
            return true
    }
    return false
}

GrabSelection() {
    global lastSelectionWasTerminal
    KeyWait "CapsLock"
    KeyWait "Shift"
    lastSelectionWasTerminal := IsTerminalWindow()

    ; In terminals, the CapsLock prefix keypress deselects the text before
    ; we can copy. Read whatever is already in the clipboard instead — the
    ; user is expected to pre-copy with the terminal's native gesture
    ; (Ctrl+Shift+C in Windows Terminal / Claude Code CLI).
    if (lastSelectionWasTerminal)
        return Trim(A_Clipboard, " `t`r`n")

    ; Non-terminal: auto-copy via Ctrl+C, restore clipboard after.
    prevClip := A_Clipboard
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(1) {
        A_Clipboard := prevClip
        return ""
    }
    text := Trim(A_Clipboard, " `t`r`n")
    A_Clipboard := prevClip
    return text
}

ReadAloudHotkey(*) {
    global ttsActive
    if !InitTtsVoices() {
        ToolTip "Read Aloud: Windows SAPI not available"
        SetTimer () => ToolTip(), -2000
        return
    }
    if (ttsActive) {
        StopAllSpeech()
        ToolTip "Read Aloud: stopped"
        SetTimer () => ToolTip(), -1200
        return
    }
    text := GrabSelection()
    if (text = "") {
        if (lastSelectionWasTerminal)
            ToolTip "Terminal: copy text first (Ctrl+Shift+C), then press " KEY_READ_ALOUD
        else
            ToolTip "Read Aloud: nothing selected"
        SetTimer () => ToolTip(), -3000
        return
    }
    SpeakChunks([Map("type", "text", "body", text)])
    ToolTip "Read Aloud: speaking (press " KEY_READ_ALOUD " to stop)"
    SetTimer () => ToolTip(), -1800
}

; --- AI-prep variant -----------------------------------------------------

AIReadAloudHotkey(*) {
    global aiReadTimerCallback, aiReadPendingText, ttsActive
    if !InitTtsVoices() {
        ToolTip "AI Read: Windows SAPI not available"
        SetTimer () => ToolTip(), -2000
        return
    }
    ; If currently speaking, treat hotkey as stop
    if (ttsActive) {
        StopAllSpeech()
        ToolTip "AI Read: stopped"
        SetTimer () => ToolTip(), -1200
        return
    }
    ; Double-tap detection: second press within the 500ms window switches
    ; to "summarize" using the text already grabbed on the first tap.
    if IsObject(aiReadTimerCallback) {
        SetTimer aiReadTimerCallback, 0
        aiReadTimerCallback := 0
        text := aiReadPendingText
        aiReadPendingText := ""
        if (text != "")
            RunAIReadFlow(text, "summarize")
        return
    }
    text := GrabSelection()
    if (text = "") {
        if (lastSelectionWasTerminal)
            ToolTip "Terminal: copy text first (Ctrl+Shift+C), then press the hotkey"
        else
            ToolTip "AI Read: nothing selected"
        SetTimer () => ToolTip(), -3000
        return
    }
    aiReadPendingText := text
    aiReadTimerCallback := AIReadDefaultFire
    SetTimer aiReadTimerCallback, -500
    ToolTip "AI Read: tap again for summary…"
}

AIReadDefaultFire() {
    global aiReadTimerCallback, aiReadPendingText
    aiReadTimerCallback := 0
    text := aiReadPendingText
    aiReadPendingText := ""
    if (text != "")
        RunAIReadFlow(text, "clean")
}

; --- Explain Permission (CapsLock+p) -------------------------------------

ExplainPermissionHotkey(*) {
    global aiPermTimerCallback, aiPermPendingText, ttsActive
    if !InitTtsVoices() {
        ToolTip "Explain: Windows SAPI not available"
        SetTimer () => ToolTip(), -2000
        return
    }
    if (ttsActive) {
        StopAllSpeech()
        ToolTip "Explain: stopped"
        SetTimer () => ToolTip(), -1200
        return
    }
    ; Double-tap → full breakdown using already-grabbed text
    if IsObject(aiPermTimerCallback) {
        SetTimer aiPermTimerCallback, 0
        aiPermTimerCallback := 0
        text := aiPermPendingText
        aiPermPendingText := ""
        if (text != "")
            RunAIReadFlow(text, "permission_full")
        return
    }
    text := GrabSelection()
    if (text = "") {
        if (lastSelectionWasTerminal)
            ToolTip "Terminal: copy text first (Ctrl+Shift+C), then press " KEY_EXPLAIN_PERM
        else
            ToolTip "Explain: nothing selected"
        SetTimer () => ToolTip(), -3000
        return
    }
    aiPermPendingText := text
    aiPermTimerCallback := ExplainPermDefaultFire
    SetTimer aiPermTimerCallback, -500
    ToolTip "Explain permission: tap again for full breakdown…"
}

ExplainPermDefaultFire() {
    global aiPermTimerCallback, aiPermPendingText
    aiPermTimerCallback := 0
    text := aiPermPendingText
    aiPermPendingText := ""
    if (text != "")
        RunAIReadFlow(text, "permission_triage")
}

FriendlyModeLabel(mode) {
    labels := Map(
        "clean",             "clean read",
        "summarize",         "summary",
        "permission_triage", "quick triage",
        "permission_full",   "full breakdown"
    )
    return labels.Has(mode) ? labels[mode] : mode
}

RunAIReadFlow(text, mode) {
    label    := FriendlyModeLabel(mode)
    keys     := LoadAIKeys()
    model    := ResolveModelForMode(mode, keys)
    provider := ProviderForModel(model)
    apiKey   := (provider = "anthropic") ? keys["anthropic_key"] : keys["openai_key"]
    if (apiKey = "") {
        ToolTip "AI: no " provider " API key — Tray > Set AI Keys..."
        SetTimer () => ToolTip(), -3500
        return
    }
    ToolTip "AI: preparing " label " [" model "]…"
    try {
        sys := SystemPromptForMode(mode)
        if (provider = "anthropic")
            prepped := CallAnthropic(sys, text, model, apiKey)
        else
            prepped := CallOpenAI(sys, text, model, apiKey)
    } catch as e {
        ToolTip "AI failed: " e.Message
        SetTimer () => ToolTip(), -3500
        return
    }
    prepped := NormalizeForTTS(prepped)
    chunks := ParseReadAloudChunks(prepped)
    if (chunks.Length = 0) {
        ToolTip "AI: empty response"
        SetTimer () => ToolTip(), -1800
        return
    }
    SaveLastAIOutput(mode, model, text, prepped)
    ToolTip "AI: speaking " label " [" model "]"
    SetTimer () => ToolTip(), -2000
    SpeakChunks(chunks)
}

; --- AI API call ---------------------------------------------------------

SystemPromptForMode(mode) {
    ; Shared TTS-prep rules used by clean and summarize modes
    ttsRules := "Spoken-text rewrite rules:`n"
    ttsRules .= "- Convert file paths like PROJECT_DIR/foo/bar.rds to 'project directory, the foo folder, bar dot R-D-S file'.`n"
    ttsRules .= "- Strip code-style parentheses from function names: 'OIFTable()' becomes 'the OIFTable function'.`n"
    ttsRules .= "- Expand domain abbreviations on first use: 'DOM' becomes 'DOM, meaning days on market'.`n"
    ttsRules .= "- Replace slash-heavy lists ('mdy, ymd, dmy') with natural conjunctions ('m-d-y, y-m-d, and d-m-y').`n"
    ttsRules .= "- Soften dashes and slashes; preserve all proper nouns, numbers, and names.`n`n"

    notesRules := "Inline insight markers (use sparingly):`n"
    notesRules .= "- Where a listener might want to pause and look at the screen, insert exactly: [[NOTE: <one short callout>]]`n"
    notesRules .= "- 0-2 notes for short text, 2-4 for long. Examples:`n"
    notesRules .= "  [[NOTE: about halfway through — you may want to review the columns being parsed]]`n"
    notesRules .= "  [[NOTE: the list above has five rules — pause here to take them in]]`n`n"

    if (mode = "clean") {
        p := "You are a text-to-speech preprocessor. The user's text will be read aloud by a Windows SAPI voice. Rewrite it so it sounds natural when spoken, faithfully preserving every fact and detail.`n`n"
        p .= ttsRules
        p .= notesRules
        p .= "MODE: CLEAN. Faithful rewrite — keep every fact and detail. Do not summarize, condense, or skip information.`n`n"
        p .= "Output ONLY the prepared spoken text (with optional [[NOTE: ...]] markers). No preamble, no headings, no markdown."
        return p
    }

    if (mode = "summarize") {
        p := "You are a synthesizer for spoken summaries. The user has just heard (or will hear) the source text; your job is to give them a fresh, structured summary they can quickly absorb — NOT a paraphrase of the source.`n`n"
        p .= "REQUIRED OPENING — read this carefully. Your output MUST begin with these SIX words in this exact order, followed by a period:`n"
        p .= "  Word 1: Let`n"
        p .= "  Word 2: me`n"
        p .= "  Word 3: highlight`n"
        p .= "  Word 4: the`n"
        p .= "  Word 5: key`n"
        p .= "  Word 6: points`n"
        p .= "So the literal first characters of your output are: Let me highlight the key points.`n"
        p .= "Do NOT drop, contract, or substitute any of the six words. Do NOT use em-dashes or parentheses in that sentence. Do NOT add anything before it. After the period, continue with your content.`n`n"
        p .= "Hard rules:`n"
        p .= "- DO NOT paraphrase or rewrite individual source sentences. If a sentence from the source could be inserted into your output and fit, you are doing it wrong.`n"
        p .= "- Identify the UNDERLYING IDEAS and re-express them in fresh language and structure.`n"
        p .= "- Deliver 2 to 4 key points, each a single short complete sentence. Number them naturally in speech ('First, …  Second, …').`n"
        p .= '- End with one wrap-up sentence starting with the literal words: And in summary, ... — a single concrete takeaway.' "`n"
        p .= "- Target length: about 30% of the source or less. Brevity over completeness.`n`n"
        p .= ttsRules
        p .= "Do NOT emit [[NOTE: ...]] markers in summary mode.`n`n"
        p .= "Output ONLY the spoken summary, starting with the required opening phrase. No preamble before it, no headings, no markdown."
        return p
    }

    if (mode = "permission_triage") {
        p := "You explain developer-tool permission requests (Claude Code, AI assistants, IDE plugins, install prompts) in plain English so a non-technical user can decide whether to allow them.`n`n"
        p .= "REQUIRED OPENING — read this carefully. Your output MUST begin with these THREE words in this exact order, followed by a period:`n"
        p .= "  Word 1: Here" . "'" . "s`n"
        p .= "  Word 2: the`n"
        p .= "  Word 3: gist`n"
        p .= "So the literal first characters of your output are: Here" . "'" . "s the gist.`n"
        p .= 'Do NOT drop, contract, or substitute any of the three words (especially do not drop "the"). Do NOT use em-dashes or parentheses in that sentence. Do NOT add anything before it. After the period, continue with your explanation.' "`n`n"
        p .= "Then deliver 2 to 3 short sentences answering, in order:`n"
        p .= "1. What it wants to do (the file, command, URL, or capability — in plain words, no jargon).`n"
        p .= "2. What it could affect (which folder, app, account, or system area).`n"
        p .= '3. A single rule of thumb: "Allow this if you …" OR "Skip this if you …".' "`n`n"
        p .= "Be concrete. Avoid the words 'tool', 'API', or 'function' unless the user clearly knows them — translate to 'command', 'website', 'file', etc.`n`n"
        p .= "Do NOT emit [[NOTE: ...]] markers. Output ONLY the spoken explanation. No preamble, no headings."
        return p
    }

    if (mode = "permission_full") {
        p := "You explain developer-tool permission requests (Claude Code, AI assistants, IDE plugins, install prompts) in plain English in DETAIL, for a non-technical user who wants to fully understand the request before allowing it.`n`n"
        p .= "REQUIRED OPENING — read this carefully. Your output MUST begin with these SIX words in this exact order, followed by a period:`n"
        p .= "  Word 1: Let`n"
        p .= "  Word 2: me`n"
        p .= "  Word 3: walk`n"
        p .= "  Word 4: you`n"
        p .= "  Word 5: through`n"
        p .= "  Word 6: this`n"
        p .= "So the literal first characters of your output are: Let me walk you through this.`n"
        p .= "Do NOT drop, contract, or substitute any word. Do NOT use em-dashes or parentheses in that sentence. Do NOT add anything before it. After the period, continue with your explanation.`n`n"
        p .= "Cover, in order, as flowing spoken paragraphs (NO bullet points or asterisks):`n"
        p .= "1. What the request is asking permission to do, in concrete plain English.`n"
        p .= "2. Each specific resource involved (file, folder, command, website, account) and what could happen to it.`n"
        p .= "3. Side effects to be aware of (network calls, files written, processes started, anything irreversible).`n"
        p .= "4. When this kind of request normally appears — does it match the workflow you'd expect from what you're doing right now?`n"
        p .= '5. A closing pair of rules: a full "Allow this if …" sentence AND a full "Skip this if …" sentence.' "`n`n"
        p .= "Aim for 4 to 7 sentences total. Translate every piece of jargon. Do NOT emit [[NOTE: ...]] markers.`n`n"
        p .= "Output ONLY the spoken explanation, starting with the required opening phrase."
        return p
    }

    ; Fallback
    return SystemPromptForMode("clean")
}

CallAnthropic(systemPrompt, userText, model, apiKey) {
    body := '{'
        . '"model":"' EscapeJsonString(model) '",'
        . '"max_tokens":4096,'
        . '"temperature":0.3,'
        . '"system":"' EscapeJsonString(systemPrompt) '",'
        . '"messages":[{"role":"user","content":"' EscapeJsonString(userText) '"}]'
        . '}'
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("POST", "https://api.anthropic.com/v1/messages", false)
    http.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
    http.SetRequestHeader("x-api-key", apiKey)
    http.SetRequestHeader("anthropic-version", "2023-06-01")
    http.Send(body)
    if (http.Status != 200)
        throw Error("Anthropic " http.Status)
    resp := GetResponseTextUtf8(http)
    ; Extract content[0].text — first "text" field that follows "content"
    if !RegExMatch(resp, 's)"content"\s*:\s*\[\s*\{[^}]*?"text"\s*:\s*"((?:[^"\\]|\\.)*)"', &m)
        throw Error("No content in response")
    return UnescapeJsonString(m[1])
}

CallOpenAI(systemPrompt, userText, model, apiKey) {
    body := '{'
        . '"model":"' EscapeJsonString(model) '",'
        . '"temperature":0.3,'
        . '"messages":['
        . '{"role":"system","content":"' EscapeJsonString(systemPrompt) '"},'
        . '{"role":"user","content":"' EscapeJsonString(userText) '"}'
        . ']'
        . '}'
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("POST", "https://api.openai.com/v1/chat/completions", false)
    http.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
    http.SetRequestHeader("Authorization", "Bearer " apiKey)
    http.Send(body)
    if (http.Status != 200)
        throw Error("OpenAI " http.Status)
    resp := GetResponseTextUtf8(http)
    if !RegExMatch(resp, 's)"message"\s*:\s*\{[^}]*?"content"\s*:\s*"((?:[^"\\]|\\.)*)"', &m)
        throw Error("No content in response")
    return UnescapeJsonString(m[1])
}

; WinHttp.ResponseText decodes as Latin-1 when the server doesn't send an
; explicit charset, which mangles UTF-8 (em-dashes → "â", smart quotes →
; "â€"", etc.). Pull the raw bytes through ADODB.Stream so they're decoded
; as UTF-8 regardless of the response header.
GetResponseTextUtf8(http) {
    stream := ComObject("ADODB.Stream")
    stream.Type    := 1  ; adTypeBinary
    stream.Open()
    stream.Write(http.ResponseBody)
    stream.Position := 0
    stream.Type    := 2  ; adTypeText
    stream.Charset := "UTF-8"
    text := stream.ReadText()
    stream.Close()
    return text
}

; Post-process AI output so SAPI doesn't mispronounce typographic punctuation
; (em-dashes get spoken as "ah", smart quotes get garbled, etc.).
NormalizeForTTS(text) {
    text := StrReplace(text, Chr(0x2014), ", ")  ; em-dash → comma+pause
    text := StrReplace(text, Chr(0x2013), ", ")  ; en-dash → comma+pause
    text := StrReplace(text, Chr(0x2018), "'")    ; left single quote
    text := StrReplace(text, Chr(0x2019), "'")    ; right single quote / apostrophe
    text := StrReplace(text, Chr(0x201C), '"')   ; left double quote
    text := StrReplace(text, Chr(0x201D), '"')   ; right double quote
    text := StrReplace(text, Chr(0x00A0), " ")   ; non-breaking space
    return text
}

UnescapeJsonString(s) {
    ; Stash literal "\\" so the other unescapes don't see its trailing slash
    bs := Chr(1)
    s := StrReplace(s, "\\", bs)
    s := StrReplace(s, "\n", "`n")
    s := StrReplace(s, "\r", "`r")
    s := StrReplace(s, "\t", "`t")
    s := StrReplace(s, '\"', '"')
    s := StrReplace(s, bs, "\")
    return s
}

LoadAIKeys() {
    keys := Map(
        "openai_key", "",
        "anthropic_key", "",
        "provider", "anthropic",
        "model", "claude-haiku-4-5-20251001",
        "summary_model", "",
        "permission_full_model", ""
    )
    path := A_ScriptDir "\ai-keys.json"
    if !FileExist(path)
        return keys
    raw := FileRead(path, "UTF-8")
    fields := ["openai_key", "anthropic_key", "provider", "model", "summary_model", "permission_full_model"]
    Loop fields.Length {
        field := fields[A_Index]
        if RegExMatch(raw, '"' field '"\s*:\s*"([^"]*)"', &m)
            keys[field] := m[1]
    }
    return keys
}

; Provider is auto-detected from the model id prefix so the user can mix
; providers across modes (e.g., Haiku for cleanup, GPT-5 for summary).
ProviderForModel(model) {
    if (SubStr(model, 1, 6) = "claude")
        return "anthropic"
    return "openai"
}

ResolveModelForMode(mode, keys) {
    if (mode = "summarize" && keys.Has("summary_model") && keys["summary_model"] != "")
        return keys["summary_model"]
    if (mode = "permission_full" && keys.Has("permission_full_model") && keys["permission_full_model"] != "")
        return keys["permission_full_model"]
    return keys["model"]
}

SaveAIKeys(keys) {
    sumModel  := keys.Has("summary_model")         ? keys["summary_model"]         : ""
    permModel := keys.Has("permission_full_model") ? keys["permission_full_model"] : ""
    path := A_ScriptDir "\ai-keys.json"
    body := "{`n"
    body .= '  "openai_key": "'            EscapeJsonString(keys["openai_key"])    '",' "`n"
    body .= '  "anthropic_key": "'         EscapeJsonString(keys["anthropic_key"]) '",' "`n"
    body .= '  "provider": "'              EscapeJsonString(keys["provider"])      '",' "`n"
    body .= '  "model": "'                 EscapeJsonString(keys["model"])         '",' "`n"
    body .= '  "summary_model": "'         EscapeJsonString(sumModel)              '",' "`n"
    body .= '  "permission_full_model": "' EscapeJsonString(permModel)             '"'  "`n"
    body .= "}`n"
    try FileDelete path
    FileAppend body, path, "UTF-8"
}

; --- Playback engine -----------------------------------------------------

ParseReadAloudChunks(text) {
    chunks := []
    pos := 1
    while (pos <= StrLen(text)) {
        ; Find next [[NOTE: ...]] marker
        if RegExMatch(text, "\[\[NOTE:\s*(.*?)\]\]", &m, pos) {
            startMatch := m.Pos[0]
            endMatch   := m.Pos[0] + m.Len[0]
            before := Trim(SubStr(text, pos, startMatch - pos), " `t`r`n")
            if (before != "")
                chunks.Push(Map("type", "text", "body", before))
            note := Trim(m[1], " `t`r`n")
            if (note != "")
                chunks.Push(Map("type", "note", "body", note))
            pos := endMatch
        } else {
            tail := Trim(SubStr(text, pos), " `t`r`n")
            if (tail != "")
                chunks.Push(Map("type", "text", "body", tail))
            break
        }
    }
    return chunks
}

SpeakChunks(chunks) {
    global ttsChunks, ttsChunkIdx, ttsActive
    StopAllSpeech()  ; clear anything pending
    ttsChunks := chunks
    ttsChunkIdx := 1
    ttsActive := true
    SpeakNextChunk()
}

SpeakNextChunk() {
    global ttsVoice, ttsChunks, ttsChunkIdx, ttsActive, ttsPrimaryVoice, ttsNoteVoice
    if (!ttsActive || ttsChunkIdx > ttsChunks.Length) {
        ttsActive := false
        return
    }
    chunk := ttsChunks[ttsChunkIdx]
    ttsChunkIdx += 1
    try {
        if (chunk["type"] = "note" && IsObject(ttsNoteVoice))
            ttsVoice.Voice := ttsNoteVoice
        else if IsObject(ttsPrimaryVoice)
            ttsVoice.Voice := ttsPrimaryVoice
    }
    ttsVoice.Speak(chunk["body"], 1)  ; SVSFlagsAsync
    SetTimer CheckChunkDone, 150
}

CheckChunkDone() {
    global ttsVoice, ttsActive
    if (!ttsActive) {
        SetTimer CheckChunkDone, 0
        return
    }
    if (ttsVoice.Status.RunningState != 2) {
        SetTimer CheckChunkDone, 0
        SpeakNextChunk()
    }
}

StopAllSpeech() {
    global ttsVoice, ttsActive, ttsChunks, ttsChunkIdx
    global aiReadTimerCallback, aiReadPendingText
    global aiPermTimerCallback, aiPermPendingText

    ; Cancel any queued double-tap timers so a pending AI call won't fire
    ; later and start new speech after we've stopped.
    if IsObject(aiReadTimerCallback) {
        SetTimer aiReadTimerCallback, 0
        aiReadTimerCallback := 0
    }
    if IsObject(aiPermTimerCallback) {
        SetTimer aiPermTimerCallback, 0
        aiPermTimerCallback := 0
    }
    aiReadPendingText := ""
    aiPermPendingText := ""

    ; Clear playback state and stop the chunk-poll timer.
    ttsActive := false
    ttsChunks := []
    ttsChunkIdx := 1
    SetTimer CheckChunkDone, 0

    ; Aggressively kill SAPI. Pause halts the audio buffer immediately;
    ; sync-purge (flag 2) drains the queue; Resume releases the paused
    ; state so future Speak() calls work normally. Async purge alone
    ; (flag 3) sometimes lets the current sentence finish.
    if IsObject(ttsVoice) {
        try ttsVoice.Pause()
        try ttsVoice.Speak("", 2)
        try ttsVoice.Resume()
    }
}

HardStopHotkey(*) {
    StopAllSpeech()
    ToolTip "Speech: HARD STOP"
    SetTimer () => ToolTip(), -1500
}

; --- Tray menu helpers (called from tray menu setup) ---------------------

SetAIKeysMenu(*) {
    keys := LoadAIKeys()
    ib := InputBox("Anthropic API key (sk-ant-...). Leave blank to keep existing.", "Set Anthropic Key", "w420 h120", keys["anthropic_key"])
    if (ib.Result = "OK" && ib.Value != "")
        keys["anthropic_key"] := ib.Value
    ib := InputBox("OpenAI API key (sk-...). Leave blank to keep existing.", "Set OpenAI Key", "w420 h120", keys["openai_key"])
    if (ib.Result = "OK" && ib.Value != "")
        keys["openai_key"] := ib.Value
    SaveAIKeys(keys)
    TrayTip "AI keys saved to ai-keys.json", "Read Aloud", 1
}

SetAIProviderMenu(*) {
    keys := LoadAIKeys()

    ; 1. Base provider (used as fallback only — per-mode model auto-detects provider)
    ib := InputBox("Default provider: 'anthropic' or 'openai'.`nUsed as a fallback. Per-mode models below auto-pick provider from the model id.", "AI Provider (base)", "w420 h160", keys["provider"])
    if (ib.Result != "OK")
        return
    if (ib.Value != "")
        keys["provider"] := Trim(ib.Value)

    ; 2. Base model — used for clean read and permission triage
    defModel := (keys["provider"] = "openai") ? "gpt-4o-mini" : "claude-haiku-4-5-20251001"
    curr := keys["model"] != "" ? keys["model"] : defModel
    ib := InputBox("Base model — used for CLEAN read and PERMISSION TRIAGE.`nCheap/fast is fine here (Haiku 4.5 / gpt-4o-mini).", "Base Model", "w480 h180", curr)
    if (ib.Result != "OK")
        return
    if (ib.Value != "")
        keys["model"] := Trim(ib.Value)

    ; 3. Summary model override
    currSum := keys.Has("summary_model") ? keys["summary_model"] : ""
    ib := InputBox("SUMMARY model (Shift+CapsLock+r double-tap).`nLeave blank to use the base model.`nSuggested: claude-sonnet-4-6, claude-opus-4-7, or your latest OpenAI model id.", "Summary Model", "w520 h200", currSum)
    if (ib.Result != "OK")
        return
    keys["summary_model"] := Trim(ib.Value)

    ; 4. Permission-full model override
    currPerm := keys.Has("permission_full_model") ? keys["permission_full_model"] : ""
    ib := InputBox("PERMISSION-FULL model (CapsLock+p double-tap).`nLeave blank to use the base model.`nSuggested: claude-sonnet-4-6 or claude-opus-4-7.", "Permission-Full Model", "w520 h200", currPerm)
    if (ib.Result != "OK")
        return
    keys["permission_full_model"] := Trim(ib.Value)

    SaveAIKeys(keys)

    sumLbl  := keys["summary_model"]         != "" ? keys["summary_model"]         : "(base) " keys["model"]
    permLbl := keys["permission_full_model"] != "" ? keys["permission_full_model"] : "(base) " keys["model"]
    TrayTip "AI Read Models saved:`nBase: " keys["model"] "`nSummary: " sumLbl "`nPermission-full: " permLbl, "Read Aloud", 1
}

; ============================================
; AI HISTORY (last AI Read / Explain output)
; ============================================

SaveLastAIOutput(mode, model, input, output) {
    global lastAIOutput, lastAIMode, lastAIModel, lastAIInput, lastAITimestamp
    lastAIOutput := output
    lastAIMode := mode
    lastAIModel := model
    lastAIInput := input
    lastAITimestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")

    ; Persist to ai-last.json so re-read survives a script reload
    json := "{`n"
    json .= '  "timestamp": "' EscapeJsonString(lastAITimestamp) '",' "`n"
    json .= '  "mode": "'      EscapeJsonString(lastAIMode)      '",' "`n"
    json .= '  "model": "'     EscapeJsonString(lastAIModel)     '",' "`n"
    json .= '  "input": "'     EscapeJsonString(lastAIInput)     '",' "`n"
    json .= '  "output": "'    EscapeJsonString(lastAIOutput)    '"'  "`n"
    json .= "}`n"
    try FileDelete AI_LAST_FILE
    try FileAppend json, AI_LAST_FILE, "UTF-8"

    WriteAIHistoryFile()
}

LoadLastAIOutput() {
    global lastAIOutput, lastAIMode, lastAIModel, lastAIInput, lastAITimestamp
    if !FileExist(AI_LAST_FILE)
        return
    raw := FileRead(AI_LAST_FILE, "UTF-8")
    fields := ["timestamp", "mode", "model", "input", "output"]
    Loop fields.Length {
        field := fields[A_Index]
        if !RegExMatch(raw, '"' field '"\s*:\s*"((?:[^"\\]|\\.)*)"', &m)
            continue
        val := UnescapeJsonString(m[1])
        if (field = "timestamp")
            lastAITimestamp := val
        else if (field = "mode")
            lastAIMode := val
        else if (field = "model")
            lastAIModel := val
        else if (field = "input")
            lastAIInput := val
        else if (field = "output")
            lastAIOutput := val
    }
}

WriteAIHistoryFile() {
    global lastAIOutput, lastAIMode, lastAIModel, lastAIInput, lastAITimestamp
    js := "window._aiHistoryData = "
    if (lastAIOutput = "") {
        js .= "null;`n"
    } else {
        js .= "{"
        js .= '"timestamp":"' EscapeJsonString(lastAITimestamp) '",'
        js .= '"mode":"'      EscapeJsonString(lastAIMode)      '",'
        js .= '"model":"'     EscapeJsonString(lastAIModel)     '",'
        js .= '"input":"'     EscapeJsonString(lastAIInput)     '",'
        js .= '"output":"'    EscapeJsonString(lastAIOutput)    '"'
        js .= "};`n"
    }
    try FileDelete AI_HISTORY_DATA_FILE
    try FileAppend js, AI_HISTORY_DATA_FILE, "UTF-8"
}

ReReadLastHotkey(*) {
    global ttsActive, lastAIOutput, lastAIMode
    if !InitTtsVoices() {
        ToolTip "Re-read: Windows SAPI not available"
        SetTimer () => ToolTip(), -2000
        return
    }
    if (ttsActive) {
        StopAllSpeech()
        ToolTip "Speech: stopped"
        SetTimer () => ToolTip(), -1200
        return
    }
    if (lastAIOutput = "") {
        ToolTip "Re-read: no AI output recorded yet"
        SetTimer () => ToolTip(), -2000
        return
    }
    chunks := ParseReadAloudChunks(lastAIOutput)
    if (chunks.Length = 0) {
        ToolTip "Re-read: empty"
        SetTimer () => ToolTip(), -1800
        return
    }
    ToolTip "Re-reading last " FriendlyModeLabel(lastAIMode) "…"
    SetTimer () => ToolTip(), -1500
    SpeakChunks(chunks)
}

ToggleAIHistory(*) {
    global aiHistoryHwnd, previousWindow
    if (aiHistoryHwnd != 0 && WinExist("ahk_id " aiHistoryHwnd)) {
        CloseAIHistory()
        return
    }
    try {
        previousWindow := WinGetID("A")
    } catch {
        previousWindow := 0
    }

    WriteAIHistoryFile()

    cascade := CascadeOffset()
    posX := (A_ScreenWidth  - AI_HISTORY_WIDTH)  // 2 + cascade
    posY := (A_ScreenHeight - AI_HISTORY_HEIGHT) // 2 + cascade
    edgePath := "msedge.exe"
    ; Build a file:// URL with a cache-busting query so Edge's app-mode
    ; cache doesn't serve stale HTML between AI calls.
    historyUrl := "file:///" StrReplace(AI_HISTORY_HTML_FILE, "\", "/") "?_=" A_TickCount
    edgeArgs := Format('--app="{1}" --window-size={2},{3} --window-position={4},{5}',
        historyUrl, AI_HISTORY_WIDTH, AI_HISTORY_HEIGHT, posX, posY)
    Run edgePath " " edgeArgs

    if WinWait("AI History", , 3) {
        aiHistoryHwnd := WinGetID("AI History")
        WinActivate "ahk_id " aiHistoryHwnd
        SetTimer CheckForScriptRun, 250
    }
}

CloseAIHistory(*) {
    global aiHistoryHwnd, previousWindow
    if (aiHistoryHwnd != 0 && WinExist("ahk_id " aiHistoryHwnd)) {
        WinClose "ahk_id " aiHistoryHwnd
        aiHistoryHwnd := 0
        StopTimerIfNoWindows()
        if (previousWindow != 0 && WinExist("ahk_id " previousWindow)) {
            Sleep 50
            WinActivate "ahk_id " previousWindow
        }
    }
}

; ============================================
; STARTUP
; ============================================
LoadLastAIOutput()  ; restore last AI output from disk so re-read survives reload
; Show a tooltip on startup
ToolTip "Shortcuts Popup ready!`nPress " KEY_POPUP " to toggle`n" KEY_COLLECT " collect | Shift+" KEY_NEW_LIST " new list | " KEY_PASTE " paste | " KEY_VIEWER " viewer`n" KEY_AI_ASSIST " AI Assist"
SetTimer () => ToolTip(), -3000

# Changelog

All notable changes to Shortcuts-Custom will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.1.0] - 2026-03-15

### Added
- Speech to Text (CapsLock + ,) — live browser-based dictation with real-time transcript
- Whisper mode — OpenAI Whisper API for higher-accuracy transcription
- AI Cleanup — GPT-powered grammar, punctuation, and terminology correction
- Teachable Terminology — teach the AI your domain-specific words and phrases
- Quick Dictate (Shift+CapsLock+M) — start/stop recording from any app
- Quick Paste (Shift+CapsLock+N) — paste dictation into the app you were using
- Auto Paste button — one-click copy + paste back to source app
- Whisper Redo — re-transcribe last recording through Whisper API
- Recall Last Audio — recover previous recording after closing STT (IndexedDB)
- API Usage tracking — monitor AI cleanup and Whisper call counts, tokens, and estimated cost
- Session history — view and restore previous transcriptions within a session

## [1.0.0] - 2026-03-07

### Added
- Shortcut Popup (`CapsLock + /`) — searchable, categorized shortcut reference with copy-to-clipboard
- Clipboard Collector (`CapsLock + ;`) — collect text selections into named lists
- Collector Viewer (`CapsLock + Backspace`) — visual interface to manage collected items
- Paste collected items (`CapsLock + ]`) — space-separated paste of active list
- Runnable Scripts — launch `.bat`, `.ps1`, or `.exe` files from the popup
- Categories & Favorites — color-coded categories and star favorites
- Inline Notes — attach notes to any shortcut
- Dark theme UI
- Configurable trigger hotkey via `TRIGGER_KEY` in `popup.ahk`
- Startup-on-login support via Windows Startup folder
- MIT License, SECURITY, CONTRIBUTING, CODE_OF_CONDUCT, and issue templates

; ================================
; CS2 + CapFrameX Benchmark Runner (AutoHotkey v2)
; Launch CS2, run: map_workshop 3240880604
; Close console after 3s, wait 5s, start CapFrameX (F5) with double-beep,
; then quit CS2 after ~125s
; ================================

; --- SETTINGS ---
capframexExe := "C:\Users\YourName\Desktop\CapFrameX\CapFrameX.exe"
steamExe     := "C:\Program Files (x86)\Steam\steam.exe"
workshopId   := "3240880604"

cs2WindowWaitSeconds := 120    ; wait up to 2 min for CS2 window
postWindowSettleMs   := 15000  ; wait after CS2 window appears before console

consoleKey        := "{F10}"   ; your CS2 console key
startHotkeyToSend := "{F5}"    ; CapFrameX Start Capture

closeConsoleDelayMs := 3000    ; wait after Enter before pressing Escape
mapStartDelayMs     := 6000    ; wait after closing console before capture
benchmarkDurationMs := 125000  ; ~125 seconds after capture before quitting CS2

; --- Helpers ---
ErrBox(txt) {
    MsgBox txt, "Error", "Iconx"
    ExitApp
}

SendConsoleCommand(cmd) {
    global consoleKey
    WinActivate "Counter-Strike 2"
    WinWaitActive("Counter-Strike 2",, 2)
    Sleep 120
    Send "{Blind}{Escape}" ; exit menus
    Sleep 120
    Send "{Blind}" consoleKey ; open console
    Sleep 200
    Send "{Text}" cmd
    Sleep 80
    Send "{Enter}"
}

; --- 1) Start CapFrameX ---
if !FileExist(capframexExe)
    ErrBox("CapFrameX not found at:`n" capframexExe)
Run('"' capframexExe '"')
Sleep 1200

; --- 2) Launch CS2 ---
if !FileExist(steamExe)
    ErrBox("Steam not found at:`n" steamExe)
Run('"' steamExe '" -applaunch 730')

; --- 3) Wait for CS2 window & settle ---
if !WinWait("Counter-Strike 2", , cs2WindowWaitSeconds)
    MsgBox "Couldn’t detect the CS2 window within ~" cs2WindowWaitSeconds " seconds.", "Notice"
Sleep postWindowSettleMs

; --- 4) Run the workshop map command ---
SendConsoleCommand("map_workshop " workshopId)
Sleep closeConsoleDelayMs
Send "{Escape}" ; close console

; --- 5) Wait for map to start, then start CapFrameX capture with double-beep cue ---
Sleep mapStartDelayMs
SoundBeep 1500, 150
Sleep 100
SoundBeep 2000, 150
Send startHotkeyToSend

; --- 6) Wait 125s, then quit CS2 ---
Sleep benchmarkDurationMs
SendConsoleCommand("quit")

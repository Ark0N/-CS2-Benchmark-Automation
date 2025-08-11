; ================================
; CS2 + CapFrameX Benchmark Runner (AutoHotkey v2)
; Copies cs2_video.txt to CS2 cfg (needs admin), closes any running CapFrameX,
; relaunches CapFrameX, starts CS2, runs workshop map, starts capture, exits.
; ================================

; ---------- Small Logger ----------
Log(msg) {
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " | " msg "`n", A_Temp "\cs2_bench.log", "UTF-8")
}

; ---------- Elevation Helper ----------
EnsureAdminAndRerun() {
    if !A_IsAdmin {
        Log("Not admin; relaunching elevated…")
        try {
            ; Use ahk interpreter explicitly to avoid handler issues
            Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
        } catch as e {
            MsgBox "Failed to request elevation:`n" e.Message, "Error", "Iconx"
        }
        ExitApp
    }
}

; ---------- Settings ----------
capframexExe := "\CapFrameX_beta1.7.6.portable\CapFrameX.exe"
steamExe     := "C:\Program Files (x86)\Steam\steam.exe"
workshopId   := "3240880604"
steamUserId  := "XXXXX"

cs2WindowWaitSeconds := 120
postWindowSettleMs   := 15000
consoleKey := "{F10}"
startHotkeyToSend := "{F5}"

closeConsoleDelayMs := 3000
mapStartDelayMs     := 6000
benchmarkDurationMs := 125000

; ---------- Helpers ----------
ErrBox(txt) {
    MsgBox txt, "Error", "Iconx"
    ExitApp
}

SendConsoleCommand(cmd) {
    global consoleKey
    WinActivate "Counter-Strike 2"
    WinWaitActive("Counter-Strike 2",, 2)
    Sleep 120
    Send "{Blind}{Escape}"       ; exit menus
    Sleep 120
    Send("{Blind}" . consoleKey) ; open console (AHK v2 concat)
    Sleep 200
    Send "{Text}" cmd
    Sleep 80
    Send "{Enter}"
}

; ---------- Start ----------
Log("Script start")

; --- 1b) Prepare cs2_video config BEFORE launching Steam/CS2 ---
sourceVideo := A_ScriptDir "\cs2_video\cs2_video.txt"
cfgFolder   := "C:\Program Files (x86)\Steam2\userdata\" steamUserId "\730\local\cfg"
targetVideo := cfgFolder "\cs2_video.txt"

; Log the effective paths (optional)
Log("cs2_video copy: source=" sourceVideo)
Log("cs2_video copy: cfgFolder=" cfgFolder)
Log("cs2_video copy: target=" targetVideo)

; 1) Must have source file
if !FileExist(sourceVideo) {
    ErrBox("Source cs2_video.txt not found at:`n" sourceVideo "`n`n" 
         . "Make sure the file exists next to the script in:\n" A_ScriptDir "\cs2_video\cs2_video.txt")
}

; 2) Ensure destination exists AND we have write permission (write-test)
try {
    DirCreate cfgFolder
    f := FileOpen(cfgFolder "\.__writetest.tmp", "w")  ; throws if no permission
    f.Write("ok")
    f.Close()
    FileDelete cfgFolder "\.__writetest.tmp"
    Log("Write test OK in cfgFolder")
} catch as e {
    Log("Write test FAILED: " e.Message " | Extra=" e.Extra)
    ; If this fires, we likely need admin — elevate and rerun
    EnsureAdminAndRerun()
}

; 3) Backup existing file (timestamped) if present
if FileExist(targetVideo) {
    ts := FormatTime(, "yyyyMMdd-HHmmss")
    backup := cfgFolder "\cs2_video.backup." ts ".txt"
    try {
        FileCopy(targetVideo, backup, 1)
        Log("Backed up existing to: " backup)
    } catch as e {
        ErrBox("Failed to back up existing cs2_video.txt:`n" e.Message "`n`nFrom: " targetVideo "`nTo: " backup)
    }
}

; 4) Copy new file (overwrite)
try {
    FileCopy(sourceVideo, targetVideo, 1)
    Log("Copied cs2_video.txt to target")
} catch as e {
    ErrBox("Failed to copy cs2_video.txt into cfg folder:`n" e.Message "`n`nFrom: " sourceVideo "`nTo: " targetVideo)
}

Run('"' capframexExe '"')
Log("Launched CapFrameX")
Sleep 1200

; 3) Launch CS2
if !FileExist(steamExe)
    ErrBox("Steam not found at:`n" steamExe)
Run('"' steamExe '" -applaunch 730')
Log("Launched Steam/CS2")

; 4) Wait for CS2 window & settle
if !WinWait("Counter-Strike 2", , cs2WindowWaitSeconds) {
    Log("CS2 window not detected within timeout")
    MsgBox "Couldn’t detect the CS2 window within ~" cs2WindowWaitSeconds " seconds.", "Notice"
}
Sleep postWindowSettleMs
Log("Window settled")

; 5) Run workshop map
SendConsoleCommand("map_workshop " workshopId)
Sleep closeConsoleDelayMs
Send "{Escape}"
Log("Sent map_workshop + closed console")

; 6) Start capture after map loads
Sleep mapStartDelayMs
SoundBeep 1500, 150
Sleep 100
SoundBeep 2000, 150
Send startHotkeyToSend
Log("Sent capture hotkey")

; 7) Wait then quit CS2
Sleep benchmarkDurationMs
SendConsoleCommand("quit")
Log("Sent quit; script end")

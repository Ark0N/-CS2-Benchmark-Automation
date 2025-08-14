; ================================
; CS2 + CapFrameX Benchmark Runner (AutoHotkey v2) v2.0
; Closes any running CapFrameX -> relaunches CapFrameX from the bundle with the settings for CS2 Benchmarking
; Starts CS2 -> runs workshop map over console -> closes Console -> 6 Seconds later -> starts CapFrameX Capture -> Let the run finish and then quits CS2
; Notes: disable "Ask which account to use each time Steam start"
; If there is a "cs2_video.txt" CS2 Video Configuration file in the "cs2_video" folder it will copy that to your Steam Account and backup the existing cs2_video.txt
; ================================

; ---------- Settings ----------
; Make CapFrameX path relative to this script folder
capframexExe := A_ScriptDir "\CapFrameX_beta1.7.6.portable\Start_CapFrameX.bat"
steamExe := ResolveSteamExe()
workshopId   := "3240880604"
steamUserId := "312103617"
; only needed to copy files there like cs2 video settings

cs2WindowWaitSeconds := 120
postWindowSettleMs   := 15000
startHotkeyToSend := "{F5}"

closeConsoleDelayMs := 3000
mapStartDelayMs     := 6000
benchmarkDurationMs := 125000

; ---------- Elevation Helper ----------
EnsureAdminAndRerun() {
    if !A_IsAdmin {
        Log("Not admin; relaunching elevated…")
        try {
            Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
        } catch as e {
            MsgBox "Failed to request elevation:`n" e.Message, "Error", "Iconx"
        }
        ExitApp
    }
}

; ---------- Helpers ----------
ErrBox(txt) {
    MsgBox txt, "Error", "Iconx"
    ExitApp
}

; resolve Steam installation folder
steamExe := ResolveSteamExe()

ResolveSteamExe() {
    exe := SteamExeFromRegistry()
    if exe
        return exe

    ; Fallback: default folder
    defaultExe := A_Is64bitOS
        ? "C:\Program Files (x86)\Steam\steam.exe"
        : "C:\Program Files\Steam\steam.exe"
    return FileExist(defaultExe) ? defaultExe : ""
}

SteamExeFromRegistry() {
    ; Prefer HKCU, then HKLM (WOW6432Node first on 64-bit)
    regCandidates := [
        ["HKCU\Software\Valve\Steam", "SteamExe"],    ; full path
        ["HKCU\Software\Valve\Steam", "SteamPath"],   ; folder
        ["HKLM\SOFTWARE\WOW6432Node\Valve\Steam", "InstallPath"],
        ["HKLM\SOFTWARE\Valve\Steam", "InstallPath"]
    ]

    for pair in regCandidates {
        try {
            val := RegRead(pair[1], pair[2])
            exe := NormalizeSteamPathToExe(val)
            if exe && FileExist(exe)
                return exe
        }
    }
    return ""
}

NormalizeSteamPathToExe(val) {
    if !val
        return ""
    ; strip quotes and normalize
    val := Trim(val, ' "' . "`t`r`n")
    val := StrReplace(val, "/", "\")
    val := RTrim(val, "\")

    ; If the value is already the exe, keep it; otherwise append \steam.exe
    if InStr(StrLower(val), "steam.exe")
        return val
    return val "\steam.exe"
}

; Type directly into an already-open console and press Enter
TypeInConsole(cmd) {
    WinActivate "Counter-Strike 2"
    WinWaitActive("Counter-Strike 2",, 2)
    Sleep 120
    ; Console is already open because of: +con_enable 1 -console +toggleconsole
    Send "{Text}" cmd
    Sleep 80
    Send "{Enter}"
}


; --- 1b) Prepare cs2_video config BEFORE launching Steam/CS2 ---
; This step is OPTIONAL. Set doPrepareVideoConfig := true if you want to run it.
doPrepareVideoConfig := false

if (doPrepareVideoConfig) {
sourceVideo := A_ScriptDir "\cs2_video\cs2_video.txt"
cfgFolder   := "C:\Program Files (x86)\Steam2\userdata\" steamUserId "\730\local\cfg"
targetVideo := cfgFolder "\cs2_video.txt"

Log("cs2_video copy: source=" sourceVideo)
Log("cs2_video copy: cfgFolder=" cfgFolder)
Log("cs2_video copy: target=" targetVideo)

; If source file does not exist, skip this step (no exit)
if !FileExist(sourceVideo) {
    Log("Source cs2_video.txt not found — skipping copy/backup step")
} else {
    ; Ensure destination exists AND we have write permission (write-test)
    try {
        DirCreate(cfgFolder)
        f := FileOpen(cfgFolder "\.__writetest.tmp", "w")
        f.Write("ok")
        f.Close()
        FileDelete cfgFolder "\.__writetest.tmp"
        Log("Write test OK in cfgFolder")
    } catch as e {
        Log("Write test FAILED: " e.Message " | Extra=" e.Extra)
        EnsureAdminAndRerun()
    }

    ; Backup existing file (timestamped) if present
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

    ; Copy new file (overwrite)
    try {
        FileCopy(sourceVideo, targetVideo, 1)
        Log("Copied cs2_video.txt to target")
    } catch as e {
        ErrBox("Failed to copy cs2_video.txt into cfg folder:`n" e.Message "`n`nFrom: " sourceVideo "`nTo: " targetVideo)
    }
}

}



; --- CapFrameX: close if already running, then launch fresh ---
if !FileExist(capframexExe)
    ErrBox("CapFrameX not found at:`n" capframexExe)

capframexExeName := RegExReplace(capframexExe, ".*\\") ; e.g. "CapFrameX.exe"
if (hwnd := WinExist("ahk_exe " capframexExeName)) {
    Log("CapFrameX already running; closing")
    WinClose hwnd
    if !ProcessWaitClose(capframexExeName, 5) {
        Log("CapFrameX didn't close in 5s (optional force-kill disabled)")
        ; Optional hard kill if you want it truly bulletproof:
        ; ProcessClose capframexExeName
        ; if !ProcessWaitClose(capframexExeName, 3)
        ;     ErrBox("Could not close CapFrameX process.")
    }
}

Run('"' capframexExe '"')
Sleep 1200

; 3) Launch CS2
if !FileExist(steamExe)
    ErrBox("Steam not found at:`n" steamExe)
Run('"' steamExe '" -applaunch 730 +con_enable 1 -console +toggleconsole')

; 4) Wait for CS2 window & settle
if !WinWait("Counter-Strike 2", , cs2WindowWaitSeconds) {
    Log("CS2 window not detected within timeout")
    MsgBox "Couldn't detect the CS2 window within ~" cs2WindowWaitSeconds " seconds.", "Notice"
}
Sleep postWindowSettleMs

; 5) Run workshop map

TypeInConsole("map_workshop " workshopId)
Sleep closeConsoleDelayMs
Send "{Escape}" ; close console so the benchmark view is clean

; 6) Start capture after map loads
Sleep mapStartDelayMs
SoundBeep 1500, 150
Sleep 100
SoundBeep 2000, 150
Send startHotkeyToSend

; 7) Wait then quit CS2
; --- 6) Wait N seconds, then quit CS2 ---
Sleep benchmarkDurationMs
; The console will re-appear at the end; type quit to exit.
TypeInConsole("quit")

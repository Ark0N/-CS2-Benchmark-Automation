; =================================================================
; CS2 Benchmark Launcher — Professional Edition (AutoHotkey v2)
; Watches for the final window "CS2 Benchmark Automation", then re-detects.
; CPU/GPU (VRAM only), polished UI, NVIDIA green GPU lines.
; =================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode 2   ; 2 = substring match (robust for window title changes)

; ---------- App Config ----------
AppName        := "CS2 Benchmark Launcher"
Version        := "1.9"
IniPath        := A_ScriptDir "\launcher_settings.ini"
SetupPath      := A_ScriptDir "\Setup_first.bat"      ; your setup launcher (.bat/.cmd/.exe/.ahk)
BenchPath      := A_ScriptDir "\Run_Benchmark.bat"
RunnerAhk      := A_ScriptDir "\AutoHotkey64.ahk"

; Preferred userdata root for cfg preview
UserdataRootPreferred := "C:\Program Files (x86)\Steam\userdata\"
AppId := "730"

; ---------- Theming ----------
Theme := Map(
    "bg",     "FFFFFF",
    "fg",     "222222",
    "muted",  "666666",
    "accent", "4C8BF5",
    "ok",     "28A745",  ; NVIDIA highlight
    "warn",   "F05A28",
    "card",   "F7F8FA"
)

; ---------- Utilities ----------
Quote(s) {
    return '"' s '"'
}

IniReadStr(section, key, default:="") {
    try {
        return IniRead(IniPath, section, key, default)
    } catch {
        return default
    }
}

IniWriteStr(section, key, value) {
    try {
        IniWrite(value, IniPath, section, key)
    } catch {
        ; ignore write errors
    }
}

ReadVarFromAhk(filePath, varName) {
    if !FileExist(filePath)
        return ""
    txt := FileRead(filePath, "UTF-8")
    q := Chr(34)
    pat := "m)^\s*" varName "\s*:=\s*" q "([^" q "]*)" q
    if RegExMatch(txt, pat, &m)
        return m[1]
    return ""
}

BuildCfgPath(steamUserId) {
    if (steamUserId = "")
        return ""
    return UserdataRootPreferred steamUserId "\" AppId "\local\cfg"
}

TrimSpaces(s) {
    return Trim(RegExReplace(s, "\s+", " "))
}

; ---------- Hardware Detection ----------
GetCPUName() {
    try {
        for p in ComObjGet("winmgmts:").ExecQuery("SELECT Name FROM Win32_Processor") {
            return TrimSpaces(p.Name)
        }
    } catch {
    }
    return ""
}

FormatVRAM(bytes) {
    if (bytes = "" || bytes <= 0)
        return ""
    return Round(bytes / (1024**3), 1) " GB"
}

; Return array of objects: [{rawName,isNvidia,display}]
GetGPUInfos() {
    infos := []
    seen := Map()
    try {
        for vc in ComObjGet("winmgmts:").ExecQuery("SELECT Name, AdapterRAM FROM Win32_VideoController") {
            name := TrimSpaces(vc.Name)
            if (name = "") || RegExMatch(name, "(?i)microsoft basic display")
                continue
            if seen.Has(name)
                continue
            seen[name] := true
            vram := FormatVRAM(vc.AdapterRAM)
            isNv := RegExMatch(name, "(?i)\bnvidia\b")
            disp := name
            if (vram != "")
                disp .= " (" vram ")"
            infos.Push({ rawName: name, isNvidia: !!isNv, display: disp })
        }
    } catch {
    }
    return infos
}

; ---------- Logger ----------
AddLog(msg) {
    global tbLog
    t := FormatTime(, "HH:mm:ss")
    tbLog.Value .= t "  " msg "`r`n"
    end := StrLen(tbLog.Value)
    ; EM_SETSEL / EM_SCROLLCARET
    DllCall("user32\SendMessage", "ptr", tbLog.Hwnd, "uint", 0x00B1, "ptr", end, "ptr", end)
    DllCall("user32\SendMessage", "ptr", tbLog.Hwnd, "uint", 0x00B7, "ptr", 0,   "ptr", 0)
}

; ---------- Window watcher ----------
; Wait for a window to APPEAR (even briefly). Robust for fast-open/close flows.
WaitForWindowAppear(title, timeoutMs := 120000) {
    start := A_TickCount
    while (A_TickCount - start < timeoutMs) {
        if WinExist(title)
            return true
        if WinWait(title, , 0.2)  ; 0.2s slices to catch blink-fast windows
            return true
        Sleep 100
    }
    return false
}

; Start setup (non-blocking), then watch for the final window to appear.
StartSetupAndWatchFinalWindow(launcherPath, finalWindowTitle := "CS2 Benchmark Automation") {
    if !FileExist(launcherPath) {
        MsgBox "File not found:`n" launcherPath, "Error", "Iconx"
        AddLog("❌ Missing: " launcherPath)
        return false
    }
    SplitPath launcherPath, &name, , &ext
    ext := StrLower(ext)
    try {
        AddLog("▶ Launching " name " …")
        if (ext = "ahk") {
            Run(Quote(A_AhkPath) " " Quote(launcherPath))                 ; non-blocking
        } else if (ext = "bat" || ext = "cmd") {
            Run(Quote(A_ComSpec) " /c " . Quote(launcherPath))            ; non-blocking
        } else if (ext = "exe") {
            Run(Quote(launcherPath))                                      ; non-blocking
        } else {
            Run(Quote(A_ComSpec) " /c " . Quote(launcherPath))            ; non-blocking
        }
        AddLog("… watching for final window: " finalWindowTitle)
        if WaitForWindowAppear(finalWindowTitle, 120000) {
            AddLog("✅ Detected: " finalWindowTitle)
        } else {
            AddLog("⚠️  Did not see '" finalWindowTitle "' within 120s (continuing).")
        }
        return true
    } catch as e {
        MsgBox "Failed to run:`n" launcherPath "`n`n" e.Message, "Error", "Iconx"
        AddLog("❌ Failed: " name " — " e.Message)
        return false
    }
}

; ---------- Persistent State ----------
SetupDone := (IniReadStr("state", "setup_done", "0") = "1")
SetupTime :=  IniReadStr("state", "setup_time", "")

; ---------- Initial Detected Settings ----------
DetectedSteamId := ReadVarFromAhk(RunnerAhk, "steamUserId")
DetectedConsole := ReadVarFromAhk(RunnerAhk, "consoleKey")
DetectedCfgPath := BuildCfgPath(DetectedSteamId)

ShownSteamId := (DetectedSteamId != "" ? DetectedSteamId : "<not set>")
ShownConsole := (DetectedConsole != "" ? DetectedConsole : "<not set>")
ShownCfgPath := (DetectedCfgPath != "" ? DetectedCfgPath : "<cannot compute – steamUserId missing>")

; ---------- Hardware Info ----------
CPUText   := (GetCPUName() != "" ? GetCPUName() : "<not detected>")

; ---------- GUI ----------
global g, ribbon, statusLbl, tbLog
global lblSteam, lblCfg, lblConsole, lblCPU
global gpuLineCtrls := []  ; dynamic GPU lines

g := Gui("+AlwaysOnTop +MinSize900x700", AppName)
g.BackColor := Theme["bg"]
g.MarginX := 16, g.MarginY := 12
g.SetFont("s10", "Segoe UI")
g.OnEvent("Close", (*) => g.Destroy())

; Header
g.SetFont("s14 Bold")
g.AddText("xm ym w860", "CS2 Benchmark Launcher")
g.SetFont("s9", "Segoe UI")
g.AddText("x+8 yp+4 c" Theme["muted"], "v" Version)

; Status Ribbon
g.AddText("xm y+6 w860 h4 Background" Theme["accent"])
ribbon := g.AddText("xm y+8 w860 cFFFFFF Background" Theme["warn"] " +Border Center", "Please run 'Setup First' before running the benchmark.")

; Status line
statusLbl := g.AddText("xm y+6 w860 c" Theme["fg"], "")

; Settings Card
card := g.AddGroupBox("xm y+10 w860 h360", "Detected Settings")
bgCard := g.AddText("xp+8 yp+18 w844 h328 Background" Theme["card"])
bgCard.Enabled := false

g.SetFont("s9", "Segoe UI")
g.AddText("xm+20 yp+8  w180 c" Theme["muted"], "Steam User ID:")
lblSteam := g.AddText("x+0 w650 +Wrap", ShownSteamId)

g.AddText("xm+20 y+10 w180 c" Theme["muted"], "CS2 cfg folder:")
lblCfg := g.AddText("x+0 w650 +Wrap", ShownCfgPath)

g.AddText("xm+20 y+10 w180 c" Theme["muted"], "Console Key:")
lblConsole := g.AddText("x+0 w650 +Wrap", ShownConsole)

g.AddText("xm+20 y+10 w180 c" Theme["muted"], "CPU:")
lblCPU := g.AddText("x+0 w650 +Wrap", CPUText)

capGPU := g.AddText("xm+20 y+10 w180 c" Theme["muted"], "GPU(s):")

; -------- SINGLE definition: RenderGPUList (safe) --------
RenderGPUList() {
    global g, gpuLineCtrls, capGPU, Theme
    arr := GetGPUInfos()
    if !IsObject(arr)
        arr := []

    for c in gpuLineCtrls {
        try c.Destroy()
    }
    gpuLineCtrls := []

    capGPU.GetPos(&cx, &cy, &cw, &ch)
    x := cx + cw
    y := cy
    w := 650
    lineH := 18

    if (arr.Length = 0) {
        gpuLineCtrls.Push(g.AddText(Format("x{1} y{2} w{3} +Wrap c{4}", x, y, w, Theme["fg"]), "<not detected>"))
        return
    }
    for i, info in arr {
        color := info.isNvidia ? Theme["ok"] : Theme["fg"]
        text  := "• " info.display
        ctrl  := g.AddText(Format("x{1} y{2} w{3} +Wrap c{4}", x, y + (i-1)*lineH, w, color), text)
        gpuLineCtrls.Push(ctrl)
    }
}

g.SetFont("s10", "Segoe UI")

; Actions Card
act := g.AddGroupBox("xm y+12 w860 h86", "Actions")
bgAct := g.AddText("xp+8 yp+18 w844 h54 Background" Theme["card"])
bgAct.Enabled := false

btnSetup := g.AddButton("xm+28 yp+10 w300 h40", "🛠  &Run Setup First")
btnBench := g.AddButton("x+20 w300 h40 Default", "▶  Run CS2 Benchmark")
btnSetup.ToolTip := "Run preparation steps (recommended first)."
btnBench.ToolTip := "Start the benchmark."

; Log
g.SetFont("s9", "Segoe UI")
g.AddText("xm y+14 c" Theme["muted"], "Activity:")
tbLog := g.AddEdit("xm w860 r12 ReadOnly -Wrap +VScroll")
AddLog("Launcher ready")

; Footer
g.SetFont("s10", "Segoe UI")
btnExit := g.AddButton("xm y+10 w100", "Close")
btnExit.OnEvent("Click", (*) => g.Destroy())

; ---------- Behavior ----------
UpdateStatus() {
    global SetupDone, SetupTime, ribbon, statusLbl, Theme
    if SetupDone {
        statusLbl.Text := (SetupTime != "" ? "Setup status: DONE (" SetupTime ")" : "Setup status: DONE")
        ribbon.Text := "Setup completed — you can run the benchmark."
        ribbon.Opt("Background" Theme["ok"])
    } else {
        statusLbl.Text := "Setup status: NOT DONE"
        ribbon.Text := "Please run 'Setup First' before running the benchmark."
        ribbon.Opt("Background" Theme["warn"])
    }
}

RefreshDetected() {
    global RunnerAhk, lblSteam, lblConsole, lblCfg
    DetectedSteamId := ReadVarFromAhk(RunnerAhk, "steamUserId")
    DetectedConsole := ReadVarFromAhk(RunnerAhk, "consoleKey")
    DetectedCfgPath := BuildCfgPath(DetectedSteamId)
    lblSteam.Text   := (DetectedSteamId != "" ? DetectedSteamId : "<not set>")
    lblConsole.Text := (DetectedConsole != "" ? DetectedConsole : "<not set>")
    lblCfg.Text     := (DetectedCfgPath != "" ? DetectedCfgPath : "<cannot compute – steamUserId missing>")
}

RunSetup() {
    AddLog("▶ Running Setup First…")
    if StartSetupAndWatchFinalWindow(SetupPath, "CS2 Benchmark Automation") {
        global SetupDone, SetupTime
        SetupDone := true
        SetupTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        IniWriteStr("state", "setup_done", "1")
        IniWriteStr("state", "setup_time", SetupTime)

        ; Re-detect as soon as the final window is seen (it may close fast)
        AddLog("🔎 Re-detecting settings after final window appeared…")
        RefreshDetected()
        sid := ReadVarFromAhk(RunnerAhk, "steamUserId")
        cky := ReadVarFromAhk(RunnerAhk, "consoleKey")
        cfg := BuildCfgPath(sid)
        AddLog("• steamUserId: " . (sid != "" ? sid : "<not set>"))
        AddLog("• consoleKey: " . (cky != "" ? cky : "<not set>"))
        AddLog("• cfg folder: " . (cfg != "" ? cfg : "<cannot compute – steamUserId missing>"))

        UpdateStatus()
        RenderGPUList()  ; optional refresh
    }
}
SmoothClose(gui, durationMs := 200) {
    ; fade from opaque (255) to 0
    steps := 12
    stepMs := Max(10, Round(durationMs / steps))
    loop steps + 1 {
        alpha := 255 - Round(255 * (A_Index - 1) / steps)
        WinSetTransparent alpha, "ahk_id " gui.Hwnd
        Sleep stepMs
    }
    try gui.Destroy()
}
RunBenchmark() {
    if !SetupDone
        AddLog("ℹ️  Tip: run 'Setup First' at least once.")
    AddLog("▶ Running Benchmark…")

    if !FileExist(BenchPath) {
        MsgBox "File not found:`n" BenchPath, "Error", "Iconx"
        AddLog("❌ Missing: " BenchPath)
        return
    }

    ; prevent double clicks while we launch
    btnSetup.Enabled := false
    btnBench.Enabled := false

    SplitPath BenchPath, &name, , &ext
    try {
        ext := StrLower(ext)
        if (ext = "ahk")
            Run('"' A_AhkPath '" "' BenchPath '"')
        else if (ext = "bat" || ext = "cmd")
            Run('"' A_ComSpec '" /c "' BenchPath '"')
        else if (ext = "exe")
            Run('"' BenchPath '"')
        else
            Run('"' A_ComSpec '" /c "' BenchPath '"')

        AddLog("✅ Launched: " name)
        SmoothClose(g, 220)   ; <- nice fade-out then close
    } catch as e {
        MsgBox "Failed to run:`n" BenchPath "`n`n" e.Message, "Error", "Iconx"
        AddLog("❌ Failed: " name " — " e.Message)
        ; re-enable on failure
        btnSetup.Enabled := true
        btnBench.Enabled := true
    }
}

btnSetup.OnEvent("Click", (*) => RunSetup())
btnBench.OnEvent("Click", (*) => RunBenchmark())

; ---------- Init ----------
UpdateStatus()
RenderGPUList()
g.Show("w900 h720")
return
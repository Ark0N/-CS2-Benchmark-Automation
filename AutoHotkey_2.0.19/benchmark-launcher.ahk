; =================================================================
; CS2 Benchmark Launcher — Professional Edition (AutoHotkey v2)
; No setup required. Optional helper to copy cs2_video settings.
; CPU/GPU (VRAM only), polished UI, NVIDIA green GPU lines.
; (consoleKey logic removed)
; =================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode 2   ; substring match

; ---------- App Config ----------
AppName        := "CS2 Benchmark Launcher"
Version        := "2.1.1"
IniPath        := A_ScriptDir "\launcher_settings.ini"   ; kept for future use if needed
CopyVideoPath  := A_ScriptDir "\Setup_first.bat"         ; optional helper (copies cs2_video etc.)
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

ReadVarFromAhk(filePath, varName) {
    if !FileExist(filePath)
        return ""
    txt := FileRead(filePath, "UTF-8")
    ; Accept " or ' and flexible whitespace
    pat := "m)^\s*" varName "\s*:=\s*(['" Chr(34) "])(.+?)\1"
    if RegExMatch(txt, pat, &m)
        return m[2]
    return ""
}

BuildCfgPath(steamUserId) {
    if (steamUserId = "")
        return ""
    return UserdataRootPreferred steamUserId "\" AppId "\local\cfg"
}

TrimSpaces(s) => Trim(RegExReplace(s, "\s+", " "))

; ---------- Hardware Detection ----------
GetCPUName() {
    static wmi := ComObjGet("winmgmts:")
    try {
        for p in wmi.ExecQuery("SELECT Name FROM Win32_Processor") {
            return TrimSpaces(p.Name)
        }
    } catch {
        ; ignore
    }
    return ""
}

FormatVRAM(bytes) {
    if (bytes = "" || bytes <= 0)
        return ""
    v := ""
    try {
        v := Round(bytes / (1024**3), 1)
    } catch as e {
        v := ""
    }
    return (v != "" ? v " GB" : "")
}

; Return array of objects: [{rawName,isNvidia,display}]
GetGPUInfos() {
    static wmi := ComObjGet("winmgmts:")
    infos := []
    seen := Map()
    try {
        for vc in wmi.ExecQuery("SELECT Name, AdapterRAM FROM Win32_VideoController") {
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
        ; ignore
    }
    return infos
}

; ---------- Logger ----------
AddLog(msg) {
    global tbLog
    t := FormatTime(, "HH:mm:ss")
    tbLog.Value .= t "  " msg "`r`n"
    ; keep tail to avoid huge control
    if StrLen(tbLog.Value) > 200000
        tbLog.Value := SubStr(tbLog.Value, -150000)
    end := StrLen(tbLog.Value)
    DllCall("user32\SendMessage", "ptr", tbLog.Hwnd, "uint", 0x00B1, "ptr", end, "ptr", end)
    DllCall("user32\SendMessage", "ptr", tbLog.Hwnd, "uint", 0x00B7, "ptr", 0,   "ptr", 0)
}

; ---------- Optional: quick runner ----------
RunNonBlocking(launcherPath) {
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
            Run(Quote(A_AhkPath) " " Quote(launcherPath))
        } else if (ext = "bat" || ext = "cmd") {
            Run(Quote(A_ComSpec) " /c " . Quote(launcherPath))
        } else if (ext = "exe") {
            Run(Quote(launcherPath))
        } else {
            Run(Quote(A_ComSpec) " /c " . Quote(launcherPath))
        }
        AddLog("✅ Launched: " name)
        return true
    } catch as e {
        MsgBox "Failed to run:`n" launcherPath "`n`n" e.Message, "Error", "Iconx"
        AddLog("❌ Failed: " name " — " e.Message)
        return false
    }
}

SmoothClose(gui, durationMs := 200) {
    steps := 12
    stepMs := Max(10, Round(durationMs / steps))
    loop steps + 1 {
        alpha := 255 - Round(255 * (A_Index - 1) / steps)
        WinSetTransparent alpha, "ahk_id " gui.Hwnd
        Sleep stepMs
    }
    try {
        gui.Destroy()
    } catch {
        ; ignore
    }
}

; ---------- Initial Detected Settings ----------
DetectedSteamId := ReadVarFromAhk(RunnerAhk, "steamUserId")
DetectedCfgPath := BuildCfgPath(DetectedSteamId)

ShownSteamId := (DetectedSteamId != "" ? DetectedSteamId : "<not set>")
ShownCfgPath := (DetectedCfgPath != "" ? DetectedCfgPath : "<cannot compute – steamUserId missing>")

; ---------- Hardware Info ----------
CPUText := (GetCPUName() != "" ? GetCPUName() : "<not detected>")

; ---------- GUI ----------
global g, ribbon, statusLbl, tbLog
global lblSteam, lblCfg, lblCPU
global gpuLineCtrls := []
global btnCopyVideo, btnBench  ; buttons used across funcs

g := Gui("+AlwaysOnTop +MinSize900x700 +OwnDialogs", AppName)
g.BackColor := Theme["bg"]
g.MarginX := 16, g.MarginY := 12
g.SetFont("s10", "Segoe UI")
g.OnEvent("Close", (*) => g.Destroy())

; Header
g.SetFont("s14 Bold")
g.AddText("xm ym w860", "CS2 Benchmark Launcher")
g.SetFont("s9", "Segoe UI")
g.AddText("x+8 yp+4 c" Theme["muted"], "v" Version)

; Status Ribbon (informational)
g.AddText("xm y+6 w860 h4 Background" Theme["accent"])
ribbon := g.AddText("xm y+8 w860 cFFFFFF Background" Theme["ok"] " +Border Center"
    , "No setup required — you can run the benchmark anytime.")

; Status line (simple reminder about the optional helper)
statusLbl := g.AddText("xm y+6 w860 c" Theme["fg"]
    , "Optional: use 'cs2_video Setup' if you want the launcher to copy video settings automatically.")

; Settings Card
card := g.AddGroupBox("xm y+10 w860 h330", "Detected Settings")
bgCard := g.AddText("xp+8 yp+18 w844 h298 Background" Theme["card"])
bgCard.Enabled := false

g.SetFont("s9", "Segoe UI")
g.AddText("xm+20 yp+8  w180 c" Theme["muted"], "Steam User ID:")
lblSteam := g.AddText("x+0 w650 +Wrap", ShownSteamId)

g.AddText("xm+20 y+10 w180 c" Theme["muted"], "CS2 cfg folder:")
lblCfg := g.AddText("x+0 w650 +Wrap", ShownCfgPath)

g.AddText("xm+20 y+10 w180 c" Theme["muted"], "CPU:")
lblCPU := g.AddText("x+0 w650 +Wrap", CPUText)

capGPU := g.AddText("xm+20 y+10 w180 c" Theme["muted"], "GPU(s):")

RenderGPUList() {
    global g, gpuLineCtrls, capGPU, Theme
    arr := GetGPUInfos()
    if !IsObject(arr)
        arr := []

    for c in gpuLineCtrls {
        try {
            c.Destroy()
        } catch {
        }
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

; Actions Card — benchmark is prominent & default
act := g.AddGroupBox("xm y+12 w860 h120", "Actions")
bgAct := g.AddText("xp+8 yp+18 w844 h88 Background" Theme["card"])
bgAct.Enabled := false

; Make the benchmark button prominent: wider, default, and first
btnBench := g.AddButton("xm+20 yp+10 w520 h48 Default", "▶  RUN CS2 BENCHMARK")
btnCopyVideo := g.AddButton("x+20 w280 h48", "🛠 cs2_video folder Setup (optional)")

btnBench.ToolTip := "Start the benchmark immediately (no setup needed)."
btnCopyVideo.ToolTip := "Optional helper to copy cs2_video settings automatically."

; Log
g.SetFont("s9", "Segoe UI")
g.AddText("xm y+14 c" Theme["muted"], "Activity:")
tbLog := g.AddEdit("xm w860 r12 ReadOnly -Wrap +VScroll")
AddLog("Launcher ready (no setup required).")

; Footer
g.SetFont("s10", "Segoe UI")
btnExit := g.AddButton("xm y+10 w100", "Close")
btnExit.OnEvent("Click", (*) => g.Destroy())

; ---------- Behavior ----------
RefreshDetected() {
    global RunnerAhk, lblSteam, lblCfg
    DetectedSteamId := ReadVarFromAhk(RunnerAhk, "steamUserId")
    DetectedCfgPath := BuildCfgPath(DetectedSteamId)
    lblSteam.Text   := (DetectedSteamId != "" ? DetectedSteamId : "<not set>")
    lblCfg.Text     := (DetectedCfgPath != "" ? DetectedCfgPath : "<cannot compute – steamUserId missing>")
}

RunCopyVideo() {
    global btnCopyVideo, btnBench
    btnCopyVideo.Enabled := false, btnBench.Enabled := false
    try {
        AddLog("▶ Optional: copying cs2 settings…")
        if RunNonBlocking(CopyVideoPath) {
            AddLog("ℹ️  The helper runs in the background. You can run the benchmark anytime.")
            RefreshDetected()
        }
    } finally {
        btnCopyVideo.Enabled := true, btnBench.Enabled := true
    }
}

RunBenchmark() {
    global btnCopyVideo, btnBench, BenchPath
    AddLog("▶ Running Benchmark…")

    if !FileExist(BenchPath) {
        MsgBox "File not found:`n" BenchPath, "Error", "Iconx"
        AddLog("❌ Missing: " BenchPath)
        return
    }

    ; prevent double clicks while we launch
    btnCopyVideo.Enabled := false
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
        SmoothClose(g, 220)   ; nice fade-out then close
    } catch as e {
        MsgBox "Failed to run:`n" BenchPath "`n`n" e.Message, "Error", "Iconx"
        AddLog("❌ Failed: " name " — " e.Message)
        btnCopyVideo.Enabled := true
        btnBench.Enabled := true
    }
}

btnCopyVideo.OnEvent("Click", (*) => RunCopyVideo())
btnBench.OnEvent("Click", (*) => RunBenchmark())

; ---------- Init ----------
RenderGPUList()
g.Show("w900 h720")
return

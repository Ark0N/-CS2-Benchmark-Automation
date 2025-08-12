; setup_consolekey_from_cs2.ahk — AutoHotkey v2
#Requires AutoHotkey v2.0

; --- Target AHK file to update ---
ahkFile := A_ScriptDir "\AutoHotkey64.ahk"
if !FileExist(ahkFile) {
    MsgBox "Error: Could not find:`n" ahkFile, "Error", "Iconx"
    ExitApp
}

; ---------- Helpers ----------
GetCurrentValue(content, var) {
    q := Chr(34)  ; "
    ; m)^\s*var\s*:=\s*"([^"]*)"
    pattern := "m)^\s*" . var . "\s*:=\s*" . q . "([^" . q . "]*)" . q
    if RegExMatch(content, pattern, &m)
        return m[1]
    return ""
}

UpdateVarInFile(filePath, varName, newValue) {
    if (newValue = "")
        return
    content := FileRead(filePath, "UTF-8")
    q := Chr(34)
    pattern := "m)^\s*" . varName . "\s*:=\s*" . q . "[^" . q . "]*" . q
    replacement := varName . " := " . q . newValue . q
    newContent := RegExReplace(content, pattern, replacement)
    if (newContent = content) {
        ; If the var wasn't present, append it at the end (failsafe)
        newContent := content "`r`n" replacement "`r`n"
    }
    FileDelete(filePath)
    FileAppend(newContent, filePath, "UTF-8")
}

; Prefer Steam2 if present, then registry, then default Steam path
GetSteamUserdataRoot() {
    root2 := "C:\Program Files (x86)\Steam\userdata\"
    if DirExist(root2)
        return root2
    try {
        installPath := RegRead("HKLM\SOFTWARE\WOW6432Node\Valve\Steam", "InstallPath")
        if (installPath != "")
            return installPath "\userdata\"
    }
    return "C:\Program Files (x86)\Steam\userdata\"
}

ReadAccountName(remoteDir) {
    files := [remoteDir "\cs2_user_convars.vcfg", remoteDir "\cs2_user_convars.vcf"]
    for f in files {
        if FileExist(f) {
            txt := FileRead(f, "UTF-8")
            if RegExMatch(txt, '(?i)"name"\s*"([^"]+)"', &m)
                return m[1]
        }
    }
    return "<unknown>"
}

; Pick CS2 account (outputs byref selectedUserId, selectedUserPath)
PickCs2Account(&selectedUserId, &selectedUserPath) {
    userdataRoot := GetSteamUserdataRoot()
    if !DirExist(userdataRoot) {
        MsgBox "Steam userdata folder not found:`n" userdataRoot, "Error", "Iconx"
        return false
    }
    accounts := []  ; [{id, name, remote}]
    Loop Files, userdataRoot "*", "D" {
        accId := A_LoopFileName
        if !RegExMatch(accId, "^\d+$")
            continue
        remoteDir := A_LoopFileFullPath "\730\remote"
        name := ReadAccountName(remoteDir)
        accounts.Push(Map("id", accId, "name", name, "remote", remoteDir))
    }
    if (accounts.Length = 0) {
        MsgBox "No CS2 account data found under:`n" userdataRoot "`n`nLaunch CS2 once, then retry.", "Notice", "Iconi"
        return false
    }
    if (accounts.Length = 1) {
        selectedUserId   := accounts[1]["id"]
        selectedUserPath := accounts[1]["remote"]
        return true
    }
    ; Multiple -> choose
    display := []
    for acc in accounts
        display.Push(acc["name"] "  [" acc["id"] "]")

    myGui := Gui("+AlwaysOnTop", "Select CS2 Account")
    myGui.SetFont("s10", "Segoe UI")
    myGui.AddText(, "Multiple accounts detected in:`n" userdataRoot "`nChoose which one to use:")
    lb := myGui.AddListBox("w640 r10", display)
    lb.Choose(1)
    selIdx := 0
    okBtn := myGui.AddButton("Default", "Select")
    caBtn := myGui.AddButton("x+10", "Cancel")
    okBtn.OnEvent("Click", (*) => (selIdx := lb.Value, myGui.Destroy()))
    caBtn.OnEvent("Click", (*) => (selIdx := 0,        myGui.Destroy()))
    myGui.Show()
    WinWaitClose(myGui)
    if (selIdx = 0)
        return false
    selectedUserId   := accounts[selIdx]["id"]
    selectedUserPath := accounts[selIdx]["remote"]
    return true
}

; Read the key bound to toggleconsole from cs2_user_keys.(vcfg|vcf)
; Handles both: "toggleconsole" "F10"  and  "F10" "toggleconsole"
ReadToggleConsoleKey(remoteDir) {
    files := [remoteDir "\cs2_user_keys.vcfg", remoteDir "\cs2_user_keys.vcf"]
    for f in files {
        if !FileExist(f)
            continue
        txt := FileRead(f, "UTF-8")
        pattern := '(?i)"([^"]+)"\s*"([^"]+)"'
        pos := 1
        while pos := RegExMatch(txt, pattern, &m, pos) {
            left  := m[1], right := m[2]
            if (right ~= "^(?i)toggleconsole$")  ; e.g. "F10" "toggleconsole"
                return left
            if (left  ~= "^(?i)toggleconsole$")  ; e.g. "toggleconsole" "F10"
                return right
            pos := m.Pos + m.Len
        }
    }
    return ""
}

; Map a CS2 key name/descriptor to an AHK Send token
MapToAhkKeyToken(desc) {
    d := desc
    if (d = "")
        return ""
    ; F-keys
    if RegExMatch(d, '^(?i)F([1-9]|1[0-2])$', &k)
        return "{F" k[1] "}"
    ; Backquote / tilde / VK_OEM_3 (common console key)
    if RegExMatch(d, '(?i)VK_OEM_3|GRAVE|BACKQUOTE|BACKTICK|TILDE|OEM_3|^`$|^~$')
        return "{vkC0}"   ; sc029 also works: {sc029}
    ; Single letters
    if RegExMatch(d, '^(?i)[A-Z]$', &m1)
        return "{" m1[0] "}"
    ; Single digits
    if RegExMatch(d, '^\d$', &m2)
        return "{" m2[0] "}"
    ; Fallback: wrap as-is
    return "{" d "}"
}

; ---------- Main ----------
if !PickCs2Account(&selectedUserId, &selectedUserPath)
    ExitApp

desc := ReadToggleConsoleKey(selectedUserPath)
ahkKey := MapToAhkKeyToken(desc)
if (ahkKey = "")
    ahkKey := "{F10}"  ; default if not found

; Backup & update variables in your runner script
FileCopy(ahkFile, ahkFile ".bak", 1)
UpdateVarInFile(ahkFile, "consoleKey", ahkKey)
UpdateVarInFile(ahkFile, "steamUserId", selectedUserId)  ; <<< NEW: write detected Steam ID

; Show a nicer "Done" GUI with green checkmarks
name := ReadAccountName(selectedUserPath)
done := Gui("+AlwaysOnTop", "CS2 Benchmark Automation")
done.MarginX := 20, done.MarginY := 16
done.SetFont("s12 bold", "Segoe UI")
done.AddText("w760 Center", "1-Click CS2 Benchmark Successfully Setup! Start the AutoHotkey64.ahk to begin Benchmarking!")

done.SetFont("s10", "Segoe UI")
done.AddText("xm w760 c666666", "Details:")

; helper to add a row with a right-side green checkmark
AddRow(label, value := "") {
    global done
    rowText := label
    if (value != "")
        rowText .= "  " value
    done.AddText("xm w700", rowText)
    done.AddText("x+10 w40 Right c00A000", "✓")
}

AddRow("1) Account:", name " [" selectedUserId "]")
AddRow("2) Keys file:", selectedUserPath "\cs2_user_keys.(vcfg/vcf)")
AddRow("3) Parsed ConsoleKey value:", (desc != "" ? desc : "<not found>"))
AddRow("4) AHK token written:", ahkKey)
AddRow("5) Updated script:", ahkFile "   (backup: .bak)")
AddRow("6) steamUserId written:", selectedUserId)   ; <<< NEW: confirmation row

done.AddText("xm w760 c666666", "You can close this window and run your benchmark script.")

ok := done.AddButton("xm w760 h36 Default", "Close")
ok.OnEvent("Click", (*) => done.Destroy())

done.Show("w820 h380")
WinWaitClose(done)
ExitApp

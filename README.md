# CS2 Benchmark Automation

This AutoHotkey v2 script automates running the **CS2 FPS Benchmark Workshop Map** and recording performance data using **CapFrameX**.  

It:
1. Starts CapFrameX (killing any existing instance first).
2. Launches CS2 through Steam.
3. Loads the configured FPS benchmark workshop map.
4. Starts a capture in CapFrameX after the map loads.
5. Quits CS2 after a fixed duration (~125 seconds).

---

## ✨ Features
- Automatic CapFrameX restart before each run.
- Launches CS2 and loads the workshop map via console commands.
- Waits for map load, plays a **double beep** when capture starts.
- Automatically quits CS2 when benchmark ends.
- Adjustable delays and timings in the script.
- Works in **AutoHotkey v2** on Windows.

---

## 📋 Requirements
- **Windows 10/11**
- [**AutoHotkey v2**](https://www.autohotkey.com/)
- **CapFrameX** (portable or installed)
- **Steam** with CS2 installed
- **FPS Benchmark Workshop Map**:
  - [CS2 FPS Benchmark Map](https://steamcommunity.com/sharedfiles/filedetails/?id=3240880604)

---

## ⚙️ Setup

### 1. Download the Script
Save the `.ahk` file to your computer.

### 2. Adjust File Paths
Edit these lines in the script to match your setup:

```ahk
capframexExe := "C:\Path\To\CapFrameX.exe"
steamExe     := "C:\Path\To\Steam.exe"
```

**Example:**
```ahk
capframexExe := "C:\Users\YourName\Desktop\CapFrameX\CapFrameX.exe"
steamExe     := "C:\Program Files (x86)\Steam\steam.exe"
```

---

### 3. Set Your Keys
In the script:
```ahk
consoleKey        := "{F10}"  ; CS2 developer console key
startHotkeyToSend := "{F5}"   ; CapFrameX capture hotkey
```

**In-game CS2**:
- Bind the developer console to **F10** (or your preferred key).

**In CapFrameX**:
- Set **Capture hotkey** to match the script (default: **F5**).

---

## 🎛 CapFrameX Recommended Settings

From the **Capture Logger** tab:

| Setting                   | Value      |
|---------------------------|------------|
| Capture hotkey            | `F5`       |
| Capture time [s]          | `100`      |
| Capture delay [s]         | `3`        |
| Hotkey sound              | `Voice`    |
| Global time               | `ON`       |
| Process ignore list       | Leave empty or configure as needed |
| Run history               | OFF        |
| Aggregation of run history| OFF        |


<img width="556" height="181" alt="image" src="https://github.com/user-attachments/assets/e7ed1244-d3c0-4343-83c7-d8a1b5b8c32e" />


---

## ▶️ Running the Script

1. Launch AutoHotkey v2.
2. Double-click the `.ahk` file to start it.
3. Script flow:
   - Kills any running CapFrameX process.
   - Launches CapFrameX.
   - Launches CS2 via Steam.
   - Waits for CS2 to load, opens the console, and runs:
     ```
     map_workshop 3240880604
     ```
   - Closes console after 3s.
   - Waits 6s, plays **two beeps**, and starts CapFrameX capture.
   - After 125s total, sends `quit` to CS2 console.

---

## ⏳ Adjustable Timings
These can be modified in the script:

```ahk
cs2WindowWaitSeconds := 120     ; Max wait for CS2 window
postWindowSettleMs   := 15000   ; Delay before sending console commands
closeConsoleDelayMs  := 3000    ; Wait after sending map command
mapStartDelayMs      := 6000    ; Wait before capture starts
benchmarkDurationMs  := 125000  ; Wait before quitting CS2
```

---

## 📌 Notes
- Ensure the workshop map is downloaded before running.
- No game or CapFrameX hotkeys should overlap with each other.

---

## 📜 License
Released under the MIT License — free to use, modify, and share.

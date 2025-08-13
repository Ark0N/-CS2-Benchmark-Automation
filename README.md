🎯⚡ 1-Click CS2 Benchmark Automation 📈🖥 (with CapFrameX)

Run **professional-grade CS2 benchmarks** with **true 1% lows** and precise CPU/GPU usage metrics — all in just **one click**.

Download here -> https://github.com/Ark0N/-CS2-Benchmark-Automation/archive/refs/heads/main.zip

This project bundles **CapFrameX** and **AutoHotkey** into a single, ready-to-run package.

<img width="895" height="532" alt="image" src="https://github.com/user-attachments/assets/0beea05f-334c-467b-a552-138e9d71fe11" />

## 🚀 Why This Tool?

Benchmarking CS2 by hand is frustrating — launch the game, try to hit the capture hotkey at just the right moment and then wonder if your results are even comparable. Most of the time, they aren’t.

This tool makes the process consistent, repeatable, and effortless:

1. **Timing** – Capture starts at exactly the same moment every run, down to the millisecond.
2. **Truly repeatable** – Change a bios setting, driver, overclock your GPU — then re-run knowing the test conditions are identical.
3. **Hands-free workflow** – It launches CapFrameX fresh, starts CS2, runs the benchmark, captures with audible beeps, collects the data, and closes the game automatically.
4. **Scientific accuracy** – With precise timing and CapFrameX’s trusted metrics, your results are consistent, comparable, and 100% reproducible.
5. **Exits CS2** automatically when done.

With CapFrameX handling the metrics, you get **real, trustworthy numbers** — not “fake” averages.

---

## ✨ Key Features

- **📦 All-in-One Bundle** – Includes CapFrameX and AutoHotkey scripts, no hunting for tools.
- **⚡ 1-Click GUI** – Just run `GUI-Launcher.bat` once and you’re ready to go.
- **▶ 1-Click Benchmark** – Run `Run_Benchmark.bat` and everything is automated.
- **🎯 Professional Data Quality** – Get real **1% lows**, **frametime analysis**, CPU/GPU usage charts.
- **🛠 Fully Adjustable** – All timings and hotkeys can be tweaked in the `.ahk` scripts.

- **Optional 🛠 Custom cs2_video file** Always use the same CS2 Video Settings for consistent Restults, put your cs2_video.txt settings file into the "cs2_video" folder.

---

## 🛠 Setup — Fast & Easy

1. Just install the - **CS2 FPS Benchmark Workshop Map**:  
   [Download Here](https://steamcommunity.com/sharedfiles/filedetails/?id=3240880604) (must be subscribed)

2. **Download & Extract** this bundle anywhere on your PC. [https://github.com/Ark0N/-CS2-Benchmark-Automation/archive/refs/heads/main.zip](https://github.com/Ark0N/-CS2-Benchmark-Automation/archive/refs/heads/main.zip)

3. In Steam Settings disable "Ask which account to use each time Steam start"

4. **Run `GUI-Lauincher.bat`** — it will configure everything in one go
   <img width="895" height="532" alt="image" src="https://github.com/user-attachments/assets/0beea05f-334c-467b-a552-138e9d71fe11" />

   The "Run Setup First" (setup.ahk) automatically detects your Steam installation directory and allows you to select the Steam account you want to use for the Benchmarks.

    <img width="659" height="307" alt="image" src="https://github.com/user-attachments/assets/5e9cf31f-847f-4936-9fe9-b3ebdfdf0b1f" />

   Please ensure that the CS2 Dust2 Benchmark Workshop map is subscribed to on the selected account.

   The script retrieves the key you have bound to ToggleConsole and records this information—along with your Steam installation directory and Steam User ID into the main benchmarking script, AutoHotkey64.ahk.

   > No manual path editing or tool installs — everything you need is included.

---

## ▶ Running a Benchmark

1. Run **`Run_Benchmark.bat`** for a direct run or use the `GUI-Launcher.bat`
2. Sit back:
   - CapFrameX launches in the background.
   - CS2 starts, loads the workshop FPS Benchmark map.
   - 6 Seconds after the console is closed, the capture begins (listen for the beeps).
   - The script quits CS2 when finished.
3. Open CapFrameX to review your data — full graphs, frametime plots, averages, **1% lows**, CPU/GPU metrics.

---

## 📋 Requirements

- **Windows 10/11**
- **Steam** with CS2 installed
- In Steam Settings disable "Ask which account to use each time Steam start"
- **CS2 FPS Benchmark Workshop Map**:  
  [Download Here](https://steamcommunity.com/sharedfiles/filedetails/?id=3240880604) (must be subscribed)

---

## 🎛 Important CapFrameX Settings (these settings are preconfigured)

**Capture Logger Tab:**
| Setting | Value |
|---------------------------|--------|
| Capture hotkey | `F5` |
| Capture time [s] | `100` |
| Capture delay [s] | `3` |
| Hotkey sound | Voice |
| Global time | ON |
| Run history | OFF |
| Aggregation of run history| OFF |

<img width="556" height="181" alt="image" src="https://github.com/user-attachments/assets/e7ed1244-d3c0-4343-83c7-d8a1b5b8c32e" />

---

## ⚙ Advanced Users

You can edit the `.ahk` files to change:

```ahk
cs2WindowWaitSeconds := 120     ; Max wait for CS2 to open
mapStartDelayMs      := 6000    ; Delay before starting capture
benchmarkDurationMs  := 125000  ; Duration before quitting CS2
consoleKey := "{F10}"
```

A CapFrameX Benchmark of the CS2 Dust2 Workshop Map
1440x1080 strechted low settings
<img width="2004" height="1283" alt="image" src="https://github.com/user-attachments/assets/ee45576d-0422-45a5-b0ca-7d34a982a190" />

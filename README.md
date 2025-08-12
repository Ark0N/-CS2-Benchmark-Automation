🎯⚡ 1-Click CS2 Benchmark Automation 📈🖥 (with CapFrameX)

Run **professional-grade CS2 benchmarks** with **true 1% lows** and precise CPU/GPU usage metrics — all in just **one click**.

This project bundles **CapFrameX** and **AutoHotkey** into a single, ready-to-run package.  

Just install the - **CS2 FPS Benchmark Workshop Map**:  
  [Download Here](https://steamcommunity.com/sharedfiles/filedetails/?id=3240880604) (must be subscribed)

No complicated setup, no manual steps — just **click once to set up**, and **click once to benchmark**. 

GUI-Launcher.bat from the CS2-Benchmark-Bundle.zip
<img width="895" height="532" alt="image" src="https://github.com/user-attachments/assets/0beea05f-334c-467b-a552-138e9d71fe11" />


The setup.ahk automatically detects your Steam installation directory and allows you to select the Steam account you want to use.

Please ensure that the CS2 Dust2 Benchmark Workshop map is subscribed to on the selected account.

The script retrieves the key you have bound to ToggleConsole and records this information—along with your Steam installation directory and Steam user ID—into the main benchmarking script, AutoHotkey64.ahk.

---

## 🚀 Why This Tool?

If you’ve ever tried to benchmark CS2 manually, you know the pain — launching tools separately, starting captures at the right moment, stopping them, and cleaning up afterwards.

This script **does it all automatically**:

1. **Restarts CapFrameX** for a clean capture environment.
2. **Launches CS2** and loads the FPS Benchmark Workshop map.
3. **Starts the benchmark capture** at the perfect time — with audible beeps.
4. **Collects accurate data** for average FPS, 1% lows, CPU/GPU usage, frametimes.
5. **Exits CS2** automatically when done.

With CapFrameX handling the metrics, you get **real, trustworthy numbers** — not “fake” averages.

---

## ✨ Key Features

- **📦 All-in-One Bundle** – Includes CapFrameX and AutoHotkey scripts, no hunting for tools.
- **⚡ 1-Click GUI** – Just run `GUI-Launcher.bat` once and you’re ready to go.
- **▶ 1-Click Benchmark** – Run `Run_Benchmark.bat` and everything is automated. 
- **🎯 Professional Data Quality** – Get real **1% lows**, **frametime analysis**, CPU/GPU usage charts.
- **🔄 Auto-Restart Capture Tool** – Ensures CapFrameX starts fresh every time.
- **🔊 Audio Cues** – Double beep signals when the benchmark capture starts.
- **🛠 Fully Adjustable** – All timings and hotkeys can be tweaked in the `.ahk` scripts.

---

## 🛠 Setup — Fast & Easy

1. **Download & Extract** this bundle anywhere on your PC.
2. **Run `GUI-Lauincher.bat`** — it will configure everything in one go.
3. That’s it! You’re now ready to benchmark.

> No manual path editing or tool installs — everything you need is included.

---

## ▶ Running a Benchmark

1. Run **`Run_Benchmark.bat`** for a direct run or use the `GUI-Lauincher.bat`
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
- **CS2 FPS Benchmark Workshop Map**:  
  [Download Here](https://steamcommunity.com/sharedfiles/filedetails/?id=3240880604) (must be subscribed)

---

## 🎛 Important CapFrameX Settings (these settings are preconfigured within the CS2-Benchmark-Bundle.zip)

**Capture Logger Tab:**
| Setting                   | Value  |
|---------------------------|--------|
| Capture hotkey            | `F5`   |
| Capture time [s]          | `100`  |
| Capture delay [s]         | `3`    |
| Hotkey sound              | Voice  |
| Global time               | ON     |
| Run history               | OFF    |
| Aggregation of run history| OFF    |

<img width="556" height="181" alt="image" src="https://github.com/user-attachments/assets/e7ed1244-d3c0-4343-83c7-d8a1b5b8c32e" />

---

## ⚙ Advanced Users

You can edit the `.ahk` files to change:

```ahk
cs2WindowWaitSeconds := 120     ; Max wait for CS2 to open
mapStartDelayMs      := 6000    ; Delay before starting capture
benchmarkDurationMs  := 125000  ; Duration before quitting CS2

A CapFrameX Benchmark of the CS2 Dust2 Workshop Map

<img width="2213" height="1290" alt="image" src="https://github.com/user-attachments/assets/10d8e523-2502-48a3-bb0e-a54258ab1e43" />




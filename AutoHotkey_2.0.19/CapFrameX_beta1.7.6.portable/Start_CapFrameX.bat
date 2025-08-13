@echo off
setlocal


set SRC_CFG=Configuration\AppSettings.json


set TARGET_DIR=%APPDATA%\CapFrameX\Configuration
set TARGET_CFG=%TARGET_DIR%\AppSettings.json


if not exist "%TARGET_DIR%" (
    mkdir "%TARGET_DIR%"
)


if exist "%TARGET_CFG%" (
    for /f "tokens=1-4 delims=.:/ " %%a in ("%date% %time%") do (
        set TS=%%a-%%b-%%c_%%d
    )
    copy /y "%TARGET_CFG%" "%TARGET_CFG%.bak_!TS!" >nul
    echo [INFO] Backup done: "%TARGET_CFG%.bak_!TS!"
)


copy /y "%SRC_CFG%" "%TARGET_CFG%" >nul
if errorlevel 1 (
    echo [ERROR] Could "%SRC_CFG%" copy to "%TARGET_CFG%"
    pause
    exit /b 1
)


start "" "CapFrameX.exe"

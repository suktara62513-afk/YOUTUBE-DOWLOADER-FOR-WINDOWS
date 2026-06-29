@echo off
:: ==============================================================================
:: SUPER HUMAN YouTube Downloader - Run Script
:: Made by Tarek X ChatGPT
:: Double-click this file to launch the downloader.
:: ==============================================================================

title SUPER HUMAN YouTube Downloader
cd /d "%~dp0"

:: Launch PowerShell with ExecutionPolicy Bypass so the user
:: never needs to configure anything manually.
set "PS_CMD="
where powershell.exe >nul 2>&1 && set "PS_CMD=powershell.exe"
if not defined PS_CMD where pwsh.exe >nul 2>&1 && set "PS_CMD=pwsh.exe"
if not defined PS_CMD (
    echo [✖] PowerShell was not found on this system.
    echo     Please install Windows PowerShell or PowerShell Core.
    echo.
    pause > nul
    exit /b 1
)

"%PS_CMD%" -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%~dp0Downloader.ps1"

:: If the script exits with an error, pause so the user can read it
if %errorlevel% neq 0 (
    echo.
    echo [!] The downloader exited with an error code: %errorlevel%
    echo     Press any key to close this window.
    pause > nul
)

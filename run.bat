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
powershell.exe -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%~dp0Downloader.ps1"

:: If the script exits with an error, pause so the user can read it
if %errorlevel% neq 0 (
    echo.
    echo [!] The downloader exited with an error code: %errorlevel%
    echo     Press any key to close this window.
    pause > nul
)

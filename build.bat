@echo off
:: ==============================================================================
:: SUPER HUMAN YouTube Downloader - Build / Dependency Installer
:: Made by Tarek X ChatGPT
:: Double-click this file to pre-download yt-dlp and ffmpeg into tools/
:: ==============================================================================

title SUPER HUMAN YouTube Downloader - Build
cd /d "%~dp0"

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║          SUPER HUMAN - CYBER BUILD SYSTEM               ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.
echo  [+] Verifying PowerShell environment...
echo.

powershell.exe -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%~dp0Downloader.ps1" -BuildOnly

echo.
if %errorlevel% equ 0 (
    echo  [✔] Build completed successfully. All dependencies are ready.
) else (
    echo  [✖] Build failed. Check the errors above.
)
echo.
echo  Press any key to close this window.
pause > nul

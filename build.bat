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

set "PS_CMD="
where powershell.exe >nul 2>&1 && set "PS_CMD=powershell.exe"
if not defined PS_CMD where pwsh.exe >nul 2>&1 && set "PS_CMD=pwsh.exe"
if not defined PS_CMD (
    echo  [✖] PowerShell was not found on this system.
    echo  Please install Windows PowerShell or PowerShell Core.
    echo.
    pause > nul
    exit /b 1
)

"%PS_CMD%" -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%~dp0Downloader.ps1" -BuildOnly

echo.
if %errorlevel% equ 0 (
    echo  [✔] Build completed successfully. All dependencies are ready.
) else (
    echo  [✖] Build failed. Check the errors above.
)
echo.
echo  Press any key to close this window.
pause > nul

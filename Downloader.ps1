param(
    [switch]$BuildOnly
)

# ==============================================================================
# Made by Tarek X ChatGPT
# Terminal YouTube Downloader (Windows Native PowerShell Edition)
# ==============================================================================

# Enable UTF-8 Support in the Console for Unicode Borders/Glyphs
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ANSI 256 / 24-bit RGB Colors
$esc = [char]27
$C_GREEN = "$esc[38;5;46m"
$C_CYAN = "$esc[38;5;51m"
$C_BLUE = "$esc[38;5;39m"
$C_PURPLE = "$esc[38;5;129m"
$C_MAGENTA = "$esc[38;5;201m"
$C_ORANGE = "$esc[38;5;208m"
$C_WHITE = "$esc[38;5;255m"
$C_GRAY = "$esc[38;5;244m"
$C_YELLOW = "$esc[38;5;226m"
$C_RED = "$esc[38;5;196m"
$C_RESET = "$esc[0m"
$C_BG_GREEN = "$esc[48;5;46m$esc[38;5;16m"

# Ensure clean exit and restore cursor
function Cleanup {
    [Console]::Write($C_RESET)
    [Console]::CursorVisible = $true
}

# Trap terminal exits/Ctrl+C
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Stop"

# Script-scope tools directory
$toolsDir = Join-Path $PSScriptRoot "tools"

# Helper: Escape a single argument for ProcessStartInfo.Arguments
function Escape-Argument {
    param([string]$arg)
    if ($arg -match '[ "]') {
        return '"' + ($arg -replace '"', '\"') + '"'
    }
    return $arg
}

# Helper: Join an array of arguments into a single command-line string
function Join-Arguments {
    param([string[]]$argList)
    return ($argList | ForEach-Object { Escape-Argument $_ }) -join ' '
}

function Get-TerminalWidth {
    try {
        $width = $Host.UI.RawUI.WindowSize.Width
        if ($width -gt 0) { return $width }
    } catch {}
    return 80
}

function Strip-Ansi {
    param([string]$text)
    if (-not $text) { return "" }
    return $text -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
}

function Print-Centered {
    param([string]$text)
    $width = Get-TerminalWidth
    $cleanText = Strip-Ansi $text
    $len = $cleanText.Length
    $pad = [Math]::Max(0, [int](($width - $len) / 2))
    $padding = " " * $pad
    Write-Host "$padding$text"
}

function Draw-BoxHeader {
    param([string]$title)
    $width = 64
    $termW = Get-TerminalWidth
    $pad = [Math]::Max(0, [int](($termW - $width) / 2))
    $padding = " " * $pad

    $borderTop = "─" * ($width - 2)
    Write-Host "$padding$C_GREEN╭$borderTop╮$C_RESET"

    $cleanTitle = Strip-Ansi $title
    $tLen = $cleanTitle.Length
    $tPadLeft = [int](($width - 2 - $tLen) / 2)
    $tPadRight = $width - 2 - $tLen - $tPadLeft

    $leftPadStr = " " * $tPadLeft
    $rightPadStr = " " * $tPadRight
    Write-Host "$padding$C_GREEN│$C_RESET$leftPadStr$title$rightPadStr$C_GREEN│$C_RESET"

    $borderMid = "─" * ($width - 2)
    Write-Host "$padding$C_GREEN├$borderMid┤$C_RESET"
}

function Draw-BoxLine {
    param([string]$content)
    $width = 64
    $termW = Get-TerminalWidth
    $pad = [Math]::Max(0, [int](($termW - $width) / 2))
    $padding = " " * $pad

    $cleanContent = Strip-Ansi $content
    $len = $cleanContent.Length
    $maxW = $width - 4

    if ($len -gt $maxW) {
        $content = $content.Substring(0, $maxW - 3) + "..."
        $len = $maxW
    }

    $padRight = $width - 2 - $len - 1
    $rightPadStr = " " * $padRight

    Write-Host "$padding$C_GREEN│$C_RESET $content$rightPadStr$C_GREEN│$C_RESET"
}

function Draw-BoxFooter {
    $width = 64
    $termW = Get-TerminalWidth
    $pad = [Math]::Max(0, [int](($termW - $width) / 2))
    $padding = " " * $pad

    $borderBottom = "─" * ($width - 2)
    Write-Host "$padding$C_GREEN╰$borderBottom╯$C_RESET"
}

function Wrap-And-DrawBoxLines {
    param([string]$label, [string]$text)
    $width = 64
    $labelLen = (Strip-Ansi $label).Length
    $maxW = $width - 2 - $labelLen - 2

    $len = $text.Length
    if ($len -le $maxW) {
        Draw-BoxLine "$label$text"
    } else {
        $start = 0
        $first = $true
        while ($start -lt $len) {
            $chunkLen = [Math]::Min($maxW, $len - $start)
            $chunk = $text.Substring($start, $chunkLen)
            if ($first) {
                Draw-BoxLine "$label$chunk"
                $first = $false
            } else {
                $indent = " " * $labelLen
                Draw-BoxLine "$indent$chunk"
            }
            $start += $maxW
        }
    }
}

function Show-HeaderBanner {
    $bannerLines = @(
        "╭──────────────────────────────────────────────────────────────╮",
        "│        ████████╗  █████╗  ██████╗  ███████╗ ██╗  ██╗         │",
        "│        ╚══██╔══╝ ██╔══██╗ ██╔══██╗ ██╔════╝ ██║ ██╔╝         │",
        "│           ██║    ███████║ ██████╔╝ █████╗   █████╔╝          │",
        "│           ██║    ██╔══██║ ██╔══██╗ ██╔══╝   ██╔═██╗          │",
        "│           ██║    ██║  ██║ ██║  ██╗ ███████╗ ██║  ██╗         │",
        "│           ╚═╝    ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝         │",
        "│                                                              │",
        "│                TERMINAL YOUTUBE DOWNLOADER                   │",
        "│                  MADE BY TAREK X ANTIGRAVITY                 │",
        "╰──────────────────────────────────────────────────────────────╯"
    )
    [Console]::Write($C_GREEN)
    foreach ($line in $bannerLines) {
        Print-Centered $line
    }
    Write-Host ""
}

function Show-Footer {
    $width = 64
    $termW = Get-TerminalWidth
    $pad = [Math]::Max(0, [int](($termW - $width) / 2))
    $padding = " " * $pad

    Write-Host "$padding$C_GRAY────────────────────────────────────────────────────────────────$C_RESET"
    Write-Host "$padding$C_GRAY                     Made by Tarek X ChatGPT$C_RESET"
    Write-Host "$padding$C_GRAY                  Powered by yt-dlp + ffmpeg$C_RESET"
    Write-Host "$padding$C_GRAY────────────────────────────────────────────────────────────────$C_RESET"
}

function Show-StartupAnimation {
    Clear-Host
    [Console]::Write($C_CYAN)
    
    $bannerLines = @(
        "╭──────────────────────────────────────────────────────────────╮",
        "│        ████████╗  █████╗  ██████╗  ███████╗ ██╗  ██╗         │",
        "│        ╚══██╔══╝ ██╔══██╗ ██╔══██╗ ██╔════╝ ██║ ██╔╝         │",
        "│           ██║    ███████║ ██████╔╝ █████╗   █████╔╝          │",
        "│           ██║    ██╔══██║ ██╔══██╗ ██╔══╝   ██╔═██╗          │",
        "│           ██║    ██║  ██║ ██║  ██╗ ███████╗ ██║  ██╗         │",
        "│           ╚═╝    ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝         │",
        "│                                                              │",
        "│                TERMINAL YOUTUBE DOWNLOADER                   │",
        "│                  MADE BY TAREK X ANTIGRAVITY                 │",
        "╰──────────────────────────────────────────────────────────────╯"
    )
    
    foreach ($line in $bannerLines) {
        Print-Centered $line
        Start-Sleep -Milliseconds 30
    }
    
    Write-Host ""
    Print-Centered "$C_WHITE[+] INITIALIZING SECURE CYBER-DOWNLINK...$C_RESET"
    Start-Sleep -Milliseconds 200
    
    Draw-BoxHeader "$C_GREENSYSTEM PORT DEPLOYMENT STATUS$C_RESET"
    
    $os_version = [Environment]::OSVersion.VersionString
    $ps_version = $PSVersionTable.PSVersion.ToString()
    
    $toolsDir = Join-Path $PSScriptRoot "tools"
    $ytdlp_ver = "Unknown"
    if (Test-Path (Join-Path $toolsDir "yt-dlp.exe")) {
        try {
            $ytdlp_ver = (& (Join-Path $toolsDir "yt-dlp.exe") --version).Trim()
        } catch {}
    }
    
    $ffmpeg_ver = "Unknown"
    if (Test-Path (Join-Path $toolsDir "ffmpeg.exe")) {
        try {
            $ffmpegOut = & (Join-Path $toolsDir "ffmpeg.exe") -version
            if ($ffmpegOut -and $ffmpegOut.Count -gt 0) {
                $ffmpeg_ver = ($ffmpegOut[0] -split " ")[2]
            }
        } catch {}
    }
    
    Draw-BoxLine " Core Architecture: Windows x64 ($os_version)"
    Draw-BoxLine " PowerShell Engine: v$ps_version"
    Draw-BoxLine " Downloader Daemon: yt-dlp (v$ytdlp_ver)"
    Draw-BoxLine " Encoder Protocol:  ffmpeg (v$ffmpeg_ver)"
    Draw-BoxLine " System Timeframe:  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Draw-BoxFooter
    
    Write-Host ""
    Print-Centered "$C_GREENSYSTEM DEPLOYED. PRESS ANY KEY TO DOCK PROTOCOL...$C_RESET"
    [Console]::ReadKey($true) | Out-Null
}

function Show-DepErrorScreen {
    param([string]$err)
    Clear-Host
    Show-HeaderBanner
    Draw-BoxHeader "$C_RED✖ DEPLOYMENT FAILURE DETECTED$C_RESET"
    Draw-BoxLine ""
    Draw-BoxLine "      $C_RED╭─────────────────────────────────╮$C_RESET"
    Draw-BoxLine "      $C_RED│        INSTALLATION FAIL        │$C_RESET"
    Draw-BoxLine "      $C_RED│             [ ✖ ] FAIL          │$C_RESET"
    Draw-BoxLine "      $C_RED╰─────────────────────────────────╯$C_RESET"
    Draw-BoxLine ""
    Wrap-And-DrawBoxLines "Error Detail: " $err
    Draw-BoxLine "Action Required: Choose Retry to scan again"
    Draw-BoxLine "                 or Exit to terminate."
    Draw-BoxFooter
    Write-Host ""
    Write-Host " Choose an option:"
    Write-Host "  1) Retry scanning and installation"
    Write-Host "  0) Exit"
    Write-Host ""

    while ($true) {
        $choice = Read-Host " Select option"
        if ($choice -eq "0") {
            Cleanup
            exit 0
        } elseif ($choice -eq "1") {
            return
        }
    }
}

function Check-Dependencies {
    $toolsDir = Join-Path $PSScriptRoot "tools"
    $ytdlpExists = Test-Path (Join-Path $toolsDir "yt-dlp.exe")
    $ffmpegExists = Test-Path (Join-Path $toolsDir "ffmpeg.exe")

    $ytdlpStatus = if ($ytdlpExists) { "[  $C_GREEN✓ FOUND$C_RESET  ]" } else { "[ $C_RED✗ MISSING$C_RESET ]" }
    $ffmpegStatus = if ($ffmpegExists) { "[  $C_GREEN✓ FOUND$C_RESET  ]" } else { "[ $C_RED✗ MISSING$C_RESET ]" }

    if ($ytdlpExists -and $ffmpegExists) {
        return $true
    }

    Clear-Host
    Show-HeaderBanner
    Draw-BoxHeader "$C_CYANDEPENDENCY SCANNER$C_RESET"
    Draw-BoxLine " The system requires the following protocols:"
    Draw-BoxLine ""
    Draw-BoxLine "  yt-dlp:    $ytdlpStatus"
    Draw-BoxLine "  ffmpeg:    $ffmpegStatus"
    Draw-BoxLine ""
    Draw-BoxFooter
    Write-Host ""

    Draw-BoxHeader "$C_YELLOWMISSING DEPENDENCIES DETECTED$C_RESET"
    Draw-BoxLine " The missing packages will be downloaded and"
    Draw-BoxLine " installed automatically into the tools/ folder."
    Draw-BoxFooter
    Write-Host ""
    Write-Host " Install missing packages now?"
    Write-Host "  1) Yes"
    Write-Host "  0) Exit"
    Write-Host ""

    while ($true) {
        $choice = Read-Host " Select option [0-1]"
        if ($choice -eq "0") {
            Cleanup
            exit 0
        } elseif ($choice -eq "1") {
            break
        }
    }

    Clear-Host
    Show-HeaderBanner
    Draw-BoxHeader "$C_CYANINSTALLATION PROTOCOLS ACTIVE$C_RESET"
    Draw-BoxLine " Deploying missing dependencies..."
    Draw-BoxLine ""

    $totalSteps = 0
    if (-not $ytdlpExists) { $totalSteps++ }
    if (-not $ffmpegExists) { $totalSteps++ }
    $currentStep = 1

    if (-not (Test-Path $toolsDir)) {
        New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
    }

    $oldProgress = $ProgressPreference
    $global:ProgressPreference = 'SilentlyContinue'

    if (-not $ytdlpExists) {
        Draw-BoxLine "  [$currentStep/$totalSteps] Downloading yt-dlp.exe..."
        Draw-BoxFooter
        Write-Host ""

        try {
            $ytdlpUrl = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
            Invoke-WebRequest -Uri $ytdlpUrl -OutFile (Join-Path $toolsDir "yt-dlp.exe")
            $currentStep++
            Clear-Host
            Show-HeaderBanner
            Draw-BoxHeader "$C_CYANINSTALLATION PROTOCOLS ACTIVE$C_RESET"
            Draw-BoxLine " Deploying missing dependencies..."
            Draw-BoxLine ""
            Draw-BoxLine "  ✔ yt-dlp installation complete."
        } catch {
            $global:ProgressPreference = $oldProgress
            Show-DepErrorScreen "Failed to download yt-dlp: $_"
            return $false
        }
    }

    if (-not $ffmpegExists) {
        Draw-BoxLine "  [$currentStep/$totalSteps] Downloading ffmpeg.exe..."
        Draw-BoxFooter
        Write-Host ""

        try {
            $ffmpegUrl = "https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
            $zipPath = Join-Path $toolsDir "ffmpeg.zip"
            $tempExtractDir = Join-Path $toolsDir "ffmpeg_temp"

            Invoke-WebRequest -Uri $ffmpegUrl -OutFile $zipPath

            if (Test-Path $tempExtractDir) {
                Remove-Item -Path $tempExtractDir -Recurse -Force
            }

            Expand-Archive -Path $zipPath -DestinationPath $tempExtractDir -Force

            $ffmpegExe = Get-ChildItem -Path $tempExtractDir -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
            if ($ffmpegExe) {
                Copy-Item -Path $ffmpegExe.FullName -Destination (Join-Path $toolsDir "ffmpeg.exe") -Force
            } else {
                throw "ffmpeg.exe not found in zip package."
            }

            $ffprobeExe = Get-ChildItem -Path $tempExtractDir -Recurse -Filter "ffprobe.exe" | Select-Object -First 1
            if ($ffprobeExe) {
                Copy-Item -Path $ffprobeExe.FullName -Destination (Join-Path $toolsDir "ffprobe.exe") -Force
            }

            Remove-Item -Path $zipPath -Force
            Remove-Item -Path $tempExtractDir -Recurse -Force

            Clear-Host
            Show-HeaderBanner
            Draw-BoxHeader "$C_CYANINSTALLATION PROTOCOLS ACTIVE$C_RESET"
            Draw-BoxLine " Deploying missing dependencies..."
            Draw-BoxLine ""
            if ($ytdlpExists) {
                Draw-BoxLine "  ✔ yt-dlp installation complete."
            }
            Draw-BoxLine "  ✔ ffmpeg installation complete."
        } catch {
            $global:ProgressPreference = $oldProgress
            if (Test-Path $zipPath) { Remove-Item -Path $zipPath -Force }
            if (Test-Path $tempExtractDir) { Remove-Item -Path $tempExtractDir -Recurse -Force }
            Show-DepErrorScreen "Failed to download/install ffmpeg: $_"
            return $false
        }
    }

    $global:ProgressPreference = $oldProgress
    Draw-BoxLine ""
    Draw-BoxLine " All dependencies installed successfully."
    Draw-BoxLine " Restarting Downloader..."
    Draw-BoxFooter
    Write-Host ""
    Start-Sleep -Seconds 1.5
    return $true
}

function Check-For-YtdlpUpdates {
    $toolsDir = Join-Path $PSScriptRoot "tools"
    if (-not (Test-Path (Join-Path $toolsDir "yt-dlp.exe"))) {
        return
    }

    $latestVer = ""
    $job = Start-Job -ScriptBlock {
        try {
            $resp = Invoke-RestMethod -Uri "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest" -TimeoutSec 3
            return $resp.tag_name
        } catch {
            return ""
        }
    }

    $check_cnt = 0
    [Console]::CursorVisible = $false
    while ($job.State -eq "Running") {
        $dots = "." * (($check_cnt % 3) + 1)
        $dotsPadding = " " * (3 - $dots.Length)
        [Console]::Write("$C_CYAN Checking for yt-dlp updates$dots$dotsPadding$C_RESET`r")
        $check_cnt++
        Start-Sleep -Milliseconds 150
    }
    [Console]::Write(" " * 40 + "`r")
    [Console]::CursorVisible = $true

    $latestVer = Receive-Job -Job $job
    Remove-Job -Job $job

    if (-not $latestVer) { return }

    $latestVer = $latestVer -replace 'v', ''
    
    $currentVer = ""
    try {
        $currentVer = (& (Join-Path $toolsDir "yt-dlp.exe") --version).Trim()
    } catch { return }

    if ($latestVer -ne $currentVer) {
        Clear-Host
        Show-HeaderBanner
        Draw-BoxHeader "$C_CYANSOFTWARE UPDATE PROTOCOL$C_RESET"
        Draw-BoxLine " A new yt-dlp version is available."
        Draw-BoxLine ""
        Draw-BoxLine "  Installed version: v$currentVer"
        Draw-BoxLine "  Latest release:    v$latestVer"
        Draw-BoxLine ""
        Draw-BoxFooter
        Write-Host ""
        Write-Host " Update yt-dlp now?"
        Write-Host "  1) Yes (Recommended)"
        Write-Host "  2) Skip"
        Write-Host ""

        while ($true) {
            $choice = Read-Host " Select option [1-2]"
            if ($choice -eq "1" -or $choice -eq "2") {
                break
            }
        }

        if ($choice -eq "2") { return }

        Clear-Host
        Show-HeaderBanner
        Draw-BoxHeader "$C_CYANUPGRADING YT-DLP DAEMON$C_RESET"
        Draw-BoxLine " Running upgrade protocols..."
        Draw-BoxFooter
        Write-Host ""

        $updateJob = Start-Job -ScriptBlock {
            param($exe)
            try {
                $out = & $exe -U
                return $out
            } catch {
                return "Error: $_"
            }
        } -ArgumentList (Join-Path $toolsDir "yt-dlp.exe")

        $spinChars = @('▖', '▘', '▝', '▗')
        $i = 0
        [Console]::CursorVisible = $false
        while ($updateJob.State -eq "Running") {
            $char = $spinChars[$i % $spinChars.Length]
            [Console]::Write("$C_CYAN [$char] Upgrading yt-dlp mainframe...$C_RESET`r")
            Start-Sleep -Milliseconds 80
            $i++
        }
        [Console]::Write(" " * 45 + "`r")
        [Console]::CursorVisible = $true

        $result = Receive-Job -Job $updateJob
        Remove-Job -Job $updateJob

        if ($result -match "Error") {
            Show-DepErrorScreen "Upgrade failed: $result"
            return
        }

        $newVer = "Unknown"
        try {
            $newVer = (& (Join-Path $toolsDir "yt-dlp.exe") --version).Trim()
        } catch {}

        Clear-Host
        Show-HeaderBanner
        Draw-BoxHeader "$C_GREEN✔ UPGRADE COMPLETE$C_RESET"
        Draw-BoxLine " yt-dlp successfully updated to v$newVer."
        Draw-BoxLine " Resuming main protocols..."
        Draw-BoxFooter
        Write-Host ""
        Start-Sleep -Seconds 2
    }
}

function Draw-MenuState {
    param([int]$selected, [array]$heights, [int]$total)
    
    if ($global:MENU_DRAWN) {
        [Console]::Write("$esc[$((4 + $total))A")
    }
    $global:MENU_DRAWN = $true

    Draw-BoxHeader "$C_CYANAVAILABLE RESOLUTIONS$C_RESET"

    for ($idx = 0; $idx -lt $total; $idx++) {
        $line_content = ""
        if ($idx -eq ($total - 1)) {
            $line_content = " 0) Cancel"
        } elseif ($idx -eq ($total - 2)) {
            $line_content = " $( $idx + 1 )) Best Audio (MP3)"
        } else {
            $h = $heights[$idx]
            $label = "${h}p"
            if ($h -eq 2160) {
                $label = "2160p (4K)"
            } elseif ($h -eq 1440) {
                $label = "1440p"
            }
            $line_content = " $( $idx + 1 )) $label"
        }

        if ($idx -eq $selected) {
            Draw-BoxLine "$C_BG_GREEN  $line_content  $C_RESET"
        } else {
            Draw-BoxLine "  $line_content"
        }
    }

    Draw-BoxFooter
}

function Select-Menu {
    param([array]$heights)
    $num_heights = $heights.Count
    $total = $num_heights + 2
    $selected = 0
    $global:MENU_DRAWN = $false

    [Console]::CursorVisible = $false

    while ($true) {
        Draw-MenuState -selected $selected -heights $heights -total $total

        $keyInfo = [Console]::ReadKey($true)
        $key = $keyInfo.Key
        $char = $keyInfo.KeyChar

        if ($key -eq [ConsoleKey]::UpArrow) {
            $selected = ($selected - 1 + $total) % $total
        } elseif ($key -eq [ConsoleKey]::DownArrow) {
            $selected = ($selected + 1) % $total
        } elseif ($key -eq [ConsoleKey]::Enter) {
            [Console]::CursorVisible = $true
            return $selected
        } elseif ($char -ge '0' -and $char -le '9') {
            $val = [int][string]$char
            if ($val -eq 0) {
                [Console]::CursorVisible = $true
                return ($total - 1)
            } else {
                $idx = $val - 1
                if ($idx -lt ($total - 1)) {
                    $selected = $idx
                    Draw-MenuState -selected $selected -heights $heights -total $total
                    Start-Sleep -Milliseconds 150
                    [Console]::CursorVisible = $true
                    return $selected
                }
            }
        }
    }
}

function Draw-ProgressUI {
    param(
        [string]$percent,
        [string]$speed,
        [string]$eta,
        [string]$total_size,
        [string]$dl_size,
        [string]$filename,
        [string]$resolution
    )

    if (-not $percent) { $percent = "0" }
    if (-not $speed) { $speed = "0 B/s" }
    if (-not $eta) { $eta = "--:--" }
    if (-not $total_size) { $total_size = "unknown" }
    if (-not $dl_size) { $dl_size = "0 B" }
    if (-not $filename) { $filename = "Starting download..." }
    if (-not $resolution) { $resolution = "Best" }

    $percentFloat = 0.0
    if ([double]::TryParse($percent, [ref]$percentFloat)) {
        # Parsed successfully
    }
    $percentInt = [int]$percentFloat

    if ($global:PROGRESS_DRAWN) {
        [Console]::Write("$esc[8A")
    }
    $global:PROGRESS_DRAWN = $true

    Draw-BoxHeader "$C_CYANDOWNLOADING MEDIA PROTOCOL$C_RESET"

    $cleanFn = if ($filename.Length -gt 40) { $filename.Substring(0, 37) + "..." } else { $filename }
    Draw-BoxLine " File:       $cleanFn"
    Draw-BoxLine " Res/Type:   $resolution   Speed: $speed"

    $filled = [int]($percentInt * 30 / 100)
    $empty = 30 - $filled
    $bar_filled = "█" * $filled
    $bar_empty = "░" * $empty

    $bar_color = $C_GREEN
    if ($percentInt -lt 30) {
        $bar_color = $C_ORANGE
    } elseif ($percentInt -lt 70) {
        $bar_color = $C_CYAN
    }

    Draw-BoxLine " [$bar_color$bar_filled$C_GRAY$bar_empty$C_RESET] $bar_color$percentInt%$C_RESET"
    Draw-BoxLine " Bytes info: $dl_size of $total_size   ETA: $eta"
    Draw-BoxFooter
}

function Show-SuccessScreen {
    param(
        [string]$target_title,
        [string]$res,
        [string]$dl_time,
        [bool]$is_audio
    )

    $downloadsPath = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads\SUPER HUMAN"
    $ext = if ($is_audio) { "mp3" } else { "mp4" }
    
    $finalFile = Get-ChildItem -Path $downloadsPath -Filter "*.$ext" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    $f_size = "Unknown"
    $f_name = $target_title
    if ($finalFile) {
        $f_name = $finalFile.Name
        $sizeInBytes = $finalFile.Length
        if ($sizeInBytes -ge 1GB) {
            $f_size = "$([Math]::Round($sizeInBytes / 1GB, 2)) GB"
        } elseif ($sizeInBytes -ge 1MB) {
            $f_size = "$([Math]::Round($sizeInBytes / 1MB, 2)) MB"
        } elseif ($sizeInBytes -ge 1KB) {
            $f_size = "$([Math]::Round($sizeInBytes / 1KB, 2)) KB"
        } else {
            $f_size = "$sizeInBytes Bytes"
        }
    }

    Clear-Host
    Show-HeaderBanner

    Draw-BoxHeader "$C_GREEN✔ DOWNLOAD COMPLETED SUCCESSFULLY$C_RESET"
    Draw-BoxLine ""
    Draw-BoxLine "      $C_GREEN╭─────────────────────────────────╮$C_RESET"
    Draw-BoxLine "      $C_GREEN│          DOWNLOAD COMPLETE      │$C_RESET"
    Draw-BoxLine "      $C_GREEN│             [ ✔ ] SUCCESS       │$C_RESET"
    Draw-BoxLine "      $C_GREEN╰─────────────────────────────────╯$C_RESET"
    Draw-BoxLine ""
    Wrap-And-DrawBoxLines "File Name:  " $f_name
    Draw-BoxLine "Location:   Downloads\SUPER HUMAN"
    Draw-BoxLine "Final Size: $f_size"
    Draw-BoxLine "Resolution: $res"
    Draw-BoxLine "Time Taken: $dl_time"
    Draw-BoxFooter

    Show-Footer
    Write-Host ""
    Read-Host "Press ENTER to return to Main Menu..."
}

function Show-ErrorScreen {
    param([string]$err)
    Clear-Host
    Show-HeaderBanner

    Draw-BoxHeader "$C_RED✖ SYSTEM EXCEPTION DETECTED$C_RESET"
    Draw-BoxLine ""
    Draw-BoxLine "      $C_RED╭─────────────────────────────────╮$C_RESET"
    Draw-BoxLine "      $C_RED│          CRITICAL ERROR         │$C_RESET"
    Draw-BoxLine "      $C_RED│             [ ✖ ] FAIL          │$C_RESET"
    Draw-BoxLine "      $C_RED╰─────────────────────────────────╯$C_RESET"
    Draw-BoxLine ""
    Wrap-And-DrawBoxLines "Error Msg:  " $err
    Draw-BoxLine "Suggestion: Check connection, URL validity,"
    Draw-BoxLine "            or video privacy settings."
    Draw-BoxFooter

    Show-Footer
    Write-Host ""
    Read-Host "Press ENTER to return to Main Menu..."
}

# Main Execution Guard block to ensure Cleanup runs
try {
    if ($BuildOnly) {
        $res = Check-Dependencies
        if ($res) {
            Write-Host "`n[+][Cyber-Builder] Environment verification and build completed successfully.`n"
        } else {
            Write-Host "`n[✖][Cyber-Builder] Environment verification and build failed.`n"
            exit 1
        }
        exit 0
    }

    # Run startup routine
    Show-StartupAnimation

    # Run dependency checker loop
    while (-not (Check-Dependencies)) {
        Start-Sleep -Milliseconds 500
    }

    # Run yt-dlp self-update checker
    Check-For-YtdlpUpdates

    # Main loop
    while ($true) {
        Clear-Host
        Show-HeaderBanner
        Draw-BoxHeader "$C_GREENINITIALIZE SECURE DOWNLINK$C_RESET"
        Draw-BoxLine " Paste video URL below to fetch metadata."
        Draw-BoxLine " Enter '0' to exit the downloader."
        Draw-BoxFooter
        Write-Host ""
        [Console]::Write(" $C_CYAN⚡ SYSTEM-URL > $C_RESET")
        
        $url = Read-Host
        if ($url) { $url = $url.Trim() }
        
        if (-not $url) { continue }
        
        if ($url -eq "0") {
            Clear-Host
            Show-HeaderBanner
            Draw-BoxHeader "$C_CYANTERMINATING DOWNLINK PROTOCOL$C_RESET"
            Draw-BoxLine ""
            Draw-BoxLine "      [+] Disconnecting core downloads..."
            Draw-BoxLine "      [+] Reclaiming system memory buffers..."
            Draw-BoxLine "      [+] YouTube downloader offline."
            Draw-BoxLine ""
            Draw-BoxFooter
            Write-Host ""
            Start-Sleep -Milliseconds 800
            Cleanup
            exit 0
        }
        
        if ($url -notmatch "youtube\.com" -and $url -notmatch "youtu\.be") {
            Show-ErrorScreen "Invalid YouTube URL format."
            continue
        }
        
        Clear-Host
        Show-HeaderBanner
        
        $ytArgs = @(
            "--skip-download",
            "--ffmpeg-location", $toolsDir,
            "--print",
            "%(title)s###YT_DELIM###%(uploader)s###YT_DELIM###%(duration_string)s###YT_DELIM###%(view_count)s###YT_DELIM###%(upload_date)s###YT_DELIM###%(resolution)s###YT_DELIM###%(thumbnail)s###YT_DELIM###%(formats.:.height)s",
            $url
        )
        
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = Join-Path $toolsDir "yt-dlp.exe"
        $psi.Arguments = Join-Arguments $ytArgs
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi
        $process.Start() | Out-Null
        
        # Read stdout/stderr asynchronously to avoid deadlocks
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        
        $spinChars = @('▖', '▘', '▝', '▗')
        $i = 0
        [Console]::CursorVisible = $false
        while (-not $process.HasExited) {
            $char = $spinChars[$i % $spinChars.Length]
            [Console]::Write("$C_CYAN [$char] Connecting to YouTube mainframe...$C_RESET`r")
            Start-Sleep -Milliseconds 80
            $i++
        }
        $process.WaitForExit()
        [Console]::Write(" " * 45 + "`r")
        [Console]::CursorVisible = $true
        
        $stdout = $stdoutTask.Result
        $stderr = $stderrTask.Result
        $status = $process.ExitCode
        
        if ($status -ne 0 -or -not $stdout) {
            $err_msg = ""
            $all_out = $stdout + "`n" + $stderr
            foreach ($line in ($all_out -split "`n")) {
                if ($line -like "*ERROR:*") {
                    $err_msg = $line.Substring($line.IndexOf("ERROR:")).Trim()
                    break
                }
            }
            if (-not $err_msg) {
                $err_msg = "Failed connection or private video."
            }
            Show-ErrorScreen $err_msg
            continue
        }
        
        $parts = $stdout -split "###YT_DELIM###"
        $title = $parts[0]
        $uploader = $parts[1]
        $duration = $parts[2]
        $views = $parts[3]
        $upload_date = $parts[4]
        $resolution = $parts[5]
        $thumbnail = $parts[6]
        $heights_raw = $parts[7]
        
        $heights_cleaned = $heights_raw -replace '\[|\]| ', ''
        $height_list = $heights_cleaned -split ',' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ } | Sort-Object -Descending -Unique
        
        if (-not $height_list -or $height_list.Count -eq 0) {
            Show-ErrorScreen "No video heights/resolutions found."
            continue
        }
        
        $formatted_views = $views
        $viewsInt = 0
        if ([int64]::TryParse($views, [ref]$viewsInt)) {
            if ($viewsInt -ge 1000000) {
                $formatted_views = "$([Math]::Round($viewsInt / 1000000, 1))M views"
            } elseif ($viewsInt -ge 1000) {
                $formatted_views = "$([Math]::Round($viewsInt / 1000, 1))k views"
            } else {
                $formatted_views = "$viewsInt views"
            }
        }
        
        $formatted_date = "Unknown"
        if ($upload_date.Length -eq 8) {
            $formatted_date = "$($upload_date.Substring(0,4))-$($upload_date.Substring(4,2))-$($upload_date.Substring(6,2))"
        }
        
        Clear-Host
        Show-HeaderBanner
        Draw-BoxHeader "$C_CYANTARGET ACQUIRED: VIDEO METADATA$C_RESET"
        Wrap-And-DrawBoxLines "Title:  " $title
        Draw-BoxLine "Channel:    $uploader"
        Draw-BoxLine "Duration:   $duration"
        Draw-BoxLine "Views:      $formatted_views"
        Draw-BoxLine "Released:   $formatted_date"
        Draw-BoxLine "Source Res: $resolution"
        
        $clean_thumb = $thumbnail
        if ($clean_thumb.Length -gt 48) {
            $clean_thumb = $clean_thumb.Substring(0, 45) + "..."
        }
        Draw-BoxLine "Thumbnail:  $clean_thumb"
        Draw-BoxFooter
        Write-Host ""
        
        $choice_idx = Select-Menu -heights $height_list
        
        $total_options = $height_list.Count + 2
        if ($choice_idx -eq ($total_options - 1)) {
            continue
        }
        
        Clear-Host
        Show-HeaderBanner
        
        $global:PROGRESS_DRAWN = $false
        $startTime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        
        $downloadsPath = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads\SUPER HUMAN"
        if (-not (Test-Path $downloadsPath)) {
            New-Item -ItemType Directory -Path $downloadsPath -Force | Out-Null
        }
        
        $out_template = Join-Path $downloadsPath "%(title)s.%(ext)s"
        
        $is_audio = $false
        $selected_res = ""
        $dlArgs = @(
            "--newline",
            "--ffmpeg-location", $toolsDir,
            "--progress-template",
            "PROG:%(progress._percent_str)s|%(progress._speed_str)s|%(progress._eta_str)s|%(progress._total_bytes_str)s|%(progress._downloaded_bytes_str)s",
            "-o",
            $out_template
        )
        
        if ($choice_idx -eq ($total_options - 2)) {
            $selected_res = "MP3 Audio"
            $is_audio = $true
            $dlArgs += @(
                "-x",
                "--audio-format",
                "mp3",
                "--audio-quality",
                "0",
                $url
            )
        } else {
            $selected_height = $height_list[$choice_idx]
            $selected_res = "${selected_height}p"
            $dlArgs += @(
                "-f",
                "bestvideo[height=${selected_height}][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height=${selected_height}]+bestaudio/best[height=${selected_height}]",
                "--merge-output-format",
                "mp4",
                "--remux-video",
                "mp4",
                $url
            )
        }
        
        $psiDl = New-Object System.Diagnostics.ProcessStartInfo
        $psiDl.FileName = Join-Path $toolsDir "yt-dlp.exe"
        $psiDl.Arguments = Join-Arguments $dlArgs
        $psiDl.UseShellExecute = $false
        $psiDl.RedirectStandardOutput = $true
        $psiDl.RedirectStandardError = $true
        $psiDl.CreateNoWindow = $true
        
        $dlProcess = New-Object System.Diagnostics.Process
        $dlProcess.StartInfo = $psiDl
        $dlProcess.Start() | Out-Null
        
        $currentFile = ""
        [Console]::CursorVisible = $false
        
        while (-not $dlProcess.StandardOutput.EndOfStream) {
            $line = $dlProcess.StandardOutput.ReadLine()
            if ($line -like "*Destination:*") {
                $rawPath = $line -replace '.*Destination:\s*', ''
                $currentFile = [System.IO.Path]::GetFileName($rawPath)
            } elseif ($line -like "PROG:*") {
                $data = $line -replace 'PROG:', ''
                $parts = $data.Split('|')
                if ($parts.Count -ge 5) {
                    $percent = $parts[0].Trim().Replace('%', '')
                    $speed = $parts[1].Trim()
                    $eta = $parts[2].Trim()
                    $total_size = $parts[3].Trim()
                    $dl_size = $parts[4].Trim()
                    Draw-ProgressUI -percent $percent -speed $speed -eta $eta -total_size $total_size -dl_size $dl_size -filename $currentFile -resolution $selected_res
                }
            } else {
                if ($line -match "Merging" -or $line -match "Merging formats" -or $line -match "Extracting audio") {
                    if ($global:PROGRESS_DRAWN) {
                        [Console]::Write("$esc[8A")
                    }
                    $global:PROGRESS_DRAWN = $true
                    Draw-BoxHeader "$C_PURPLEPOST-PROCESSING PROTOCOL$C_RESET"
                    Draw-BoxLine "  $C_YELLOW⚡ Merging/Extracting audio & video via FFMPEG...$C_RESET"
                    Draw-BoxLine "  Please wait, compiling final container file..."
                    Draw-BoxLine ""
                    Draw-BoxLine ""
                    Draw-BoxFooter
                }
            }
        }
        
        $dlProcess.WaitForExit()
        $dl_status = $dlProcess.ExitCode
        [Console]::CursorVisible = $true
        
        $endTime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $durationSec = $endTime - $startTime
        if ($durationSec -eq 0) { $durationSec = 1 }
        $download_time = "${durationSec} seconds"
        
        if ($dl_status -eq 0) {
            Show-SuccessScreen -target_title $title -res $selected_res -dl_time $download_time -is_audio $is_audio
        } else {
            $stderrOut = $dlProcess.StandardError.ReadToEnd()
            $errDetail = "Download interrupted or returned exit status $dl_status."
            if ($stderrOut) {
                foreach ($l in ($stderrOut -split "`n")) {
                    if ($l -like "*ERROR:*") {
                        $errDetail = $l.Substring($l.IndexOf("ERROR:")).Trim()
                        break
                    }
                }
            }
            Show-ErrorScreen $errDetail
        }
    }
} finally {
    Cleanup
    $ErrorActionPreference = $previousErrorActionPreference
}

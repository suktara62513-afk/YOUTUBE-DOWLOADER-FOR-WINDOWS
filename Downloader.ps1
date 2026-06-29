param(
    [switch]$BuildOnly
)

# ==============================================================================
# SUPER HUMAN YouTube Downloader - Windows Portable PowerShell Edition
# ============================================================================

Set-Location -Path $PSScriptRoot
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ANSI / RGB colors
$esc = [char]27
$C_GREEN = "$esc[38;5;46m"
$C_CYAN = "$esc[38;5;51m"
$C_BLUE = "$esc[38;5;39m"
$C_PURPLE = "$esc[38;5;129m"
$C_ORANGE = "$esc[38;5;208m"
$C_WHITE = "$esc[38;5;255m"
$C_GRAY = "$esc[38;5;244m"
$C_YELLOW = "$esc[38;5;226m"
$C_RED = "$esc[38;5;196m"
$C_RESET = "$esc[0m"
$C_BG_GREEN = "$esc[48;5;46m$esc[38;5;16m"

function Cleanup {
    [Console]::Write($C_RESET)
    [Console]::CursorVisible = $true
}

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Stop"

$toolsDir = Join-Path $PSScriptRoot "tools"

function Download-File {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$Destination
    )

    try {
        if (-not (Test-Path (Split-Path $Destination -Parent))) {
            New-Item -ItemType Directory -Path (Split-Path $Destination -Parent) -Force | Out-Null
        }
        if (Test-Path $Destination) {
            Remove-Item -Path $Destination -Force -ErrorAction SilentlyContinue
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
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
            $start += $chunkLen
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

    Draw-BoxHeader "$C_GREEN SYSTEM DEPLOYMENT STATUS $C_RESET"
    Draw-BoxLine " Core Architecture: Windows x64"
    Draw-BoxLine " PowerShell Engine: v$($PSVersionTable.PSVersion)"
    Draw-BoxLine " System Timeframe:  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Draw-BoxFooter
    Write-Host ""
    Print-Centered "$C_GREEN DEPLOYMENT IN PROGRESS. PLEASE WAIT...$C_RESET"
    Start-Sleep -Milliseconds 400
}

function Show-DepErrorScreen {
    param([string]$err)
    Clear-Host
    Show-HeaderBanner
    Draw-BoxHeader "$C_RED✖ DEPENDENCY ERROR$C_RESET"
    Draw-BoxLine ""
    Wrap-And-DrawBoxLines "Error Detail: " $err
    Draw-BoxLine ""
    Draw-BoxLine "This tool will retry automatically when you press ENTER."
    Draw-BoxFooter
    Write-Host ""
    Read-Host "Press ENTER to retry or close the window to exit"
}

function Install-YtDlp {
    $destExe = Join-Path $toolsDir "yt-dlp.exe"
    $url = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
    return Download-File -Url $url -Destination $destExe
}

function Install-Ffmpeg {
    $zipPath = Join-Path $toolsDir "ffmpeg.zip"
    $tempExtractDir = Join-Path $toolsDir "ffmpeg_temp"
    $url = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"

    if (-not (Download-File -Url $url -Destination $zipPath)) {
        return $false
    }

    if (Test-Path $tempExtractDir) {
        Remove-Item -Path $tempExtractDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    try {
        Expand-Archive -Path $zipPath -DestinationPath $tempExtractDir -Force
        $ffmpegExe = Get-ChildItem -Path $tempExtractDir -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
        $ffprobeExe = Get-ChildItem -Path $tempExtractDir -Recurse -Filter "ffprobe.exe" | Select-Object -First 1
        if (-not $ffmpegExe -or -not $ffprobeExe) {
            throw "ffmpeg binaries were not found inside the downloaded archive."
        }

        Copy-Item -Path $ffmpegExe.FullName -Destination (Join-Path $toolsDir "ffmpeg.exe") -Force
        Copy-Item -Path $ffprobeExe.FullName -Destination (Join-Path $toolsDir "ffprobe.exe") -Force
        return $true
    } catch {
        return $false
    } finally {
        if (Test-Path $zipPath) { Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue }
        if (Test-Path $tempExtractDir) { Remove-Item -Path $tempExtractDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Check-Dependencies {
    $ytdlpExec = Join-Path $toolsDir "yt-dlp.exe"
    $ffmpegExec = Join-Path $toolsDir "ffmpeg.exe"
    $ffprobeExec = Join-Path $toolsDir "ffprobe.exe"

    if (-not (Test-Path $toolsDir)) {
        New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
    }

    $ytdlpExists = Test-Path $ytdlpExec
    $ffmpegExists = Test-Path $ffmpegExec
    $ffprobeExists = Test-Path $ffprobeExec

    if ($ytdlpExists -and $ffmpegExists -and $ffprobeExists) {
        return $true
    }

    Clear-Host
    Show-HeaderBanner
    Draw-BoxHeader "$C_YELLOWAUTOMATED DEPENDENCY INSTALLATION$C_RESET"
    Draw-BoxLine " The required binaries are missing or incomplete."
    Draw-BoxLine " Downloading and provisioning them now..."
    Draw-BoxFooter
    Write-Host ""

    if (-not $ytdlpExists) {
        Draw-BoxLine "  • Installing yt-dlp..."
        if (-not (Install-YtDlp)) {
            Show-DepErrorScreen "Unable to download yt-dlp.exe. Check network and retry."
            return $false
        }
        Draw-BoxLine "  ✔ yt-dlp ready."
    }

    if (-not $ffmpegExists -or -not $ffprobeExists) {
        Draw-BoxLine "  • Installing ffmpeg / ffprobe..."
        if (-not (Install-Ffmpeg)) {
            Show-DepErrorScreen "Unable to download and install ffmpeg. Check network and retry."
            return $false
        }
        Draw-BoxLine "  ✔ ffmpeg and ffprobe ready."
    }

    Draw-BoxLine " All required dependencies are now available."
    Draw-BoxFooter
    Start-Sleep -Milliseconds 700
    return $true
}

function Format-Duration {
    param([int]$seconds)
    if ($seconds -lt 0) { return "Unknown" }
    $ts = [TimeSpan]::FromSeconds($seconds)
    if ($ts.Hours -gt 0) {
        return $ts.ToString("h\:mm\:ss")
    }
    return $ts.ToString("m\:ss")
}

function Get-VideoMetadata {
    param([string]$url)

    $jsonArgs = @(
        "--dump-single-json",
        "--no-warnings",
        "--no-playlist",
        "--skip-download",
        "--restrict-filenames",
        $url
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $toolsDir "yt-dlp.exe"
    $psi.Arguments = ($jsonArgs | ForEach-Object { if ($_ -match ' ') { '"' + $_ + '"' } else { $_ } }) -join ' '
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $process.Start() | Out-Null
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    if ($process.ExitCode -ne 0 -or -not $stdout) {
        $err = if ($stderr) { $stderr.Trim() } else { "Unable to fetch video metadata." }
        return @{ Success = $false; Error = $err }
    }

    try {
        $meta = $stdout | ConvertFrom-Json
    } catch {
        return @{ Success = $false; Error = "Invalid metadata response from yt-dlp." }
    }

    $heightList = @()
    foreach ($format in $meta.formats) {
        if ($null -ne $format.height) {
            $heightList += [int]$format.height
        }
    }
    $heightList = $heightList | Sort-Object -Unique -Descending

    return @{
        Success = $true
        Title = $meta.title
        Uploader = $meta.uploader
        Duration = Format-Duration -seconds $meta.duration
        Views = $meta.view_count
        UploadDate = $meta.upload_date
        Thumbnail = $meta.thumbnail
        Resolution = if ($meta.height) { "$($meta.height)p" } else { "Unknown" }
        HeightList = $heightList
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
        if ($idx -eq ($total - 1)) {
            $line_content = " 0) Cancel"
        } elseif ($idx -eq ($total - 2)) {
            $line_content = " $($idx + 1)) Best Audio (MP3)"
        } else {
            $h = $heights[$idx]
            $label = "${h}p"
            if ($h -eq 2160) { $label = "2160p (4K)" }
            elseif ($h -eq 1440) { $label = "1440p" }
            $line_content = " $($idx + 1)) $label"
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
    $total = $heights.Count + 2
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
    [double]::TryParse($percent, [ref]$percentFloat) | Out-Null
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
    if ($percentInt -lt 30) { $bar_color = $C_ORANGE }
    elseif ($percentInt -lt 70) { $bar_color = $C_CYAN }
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

    $downloadsPath = Join-Path (Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads") "SUPER HUMAN"
    $ext = if ($is_audio) { "mp3" } else { "mp4" }
    $finalFile = Get-ChildItem -Path $downloadsPath -Filter "*.$ext" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

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
    Wrap-And-DrawBoxLines "File Name:  " $f_name
    Draw-BoxLine "Location:   Downloads\\SUPER HUMAN"
    Draw-BoxLine "Final Size: $f_size"
    Draw-BoxLine "Resolution: $res"
    Draw-BoxLine "Time Taken: $dl_time"
    Draw-BoxFooter
    Show-Footer
    Write-Host ""
    Read-Host "Press ENTER to return to the main menu"
}

function Show-ErrorScreen {
    param([string]$err)
    Clear-Host
    Show-HeaderBanner
    Draw-BoxHeader "$C_RED✖ SYSTEM EXCEPTION DETECTED$C_RESET"
    Draw-BoxLine ""
    Wrap-And-DrawBoxLines "Error Msg:  " $err
    Draw-BoxLine "Suggestion: Verify URL, internet connectivity," 
    Draw-BoxLine "            or YouTube access from this machine."
    Draw-BoxFooter
    Show-Footer
    Write-Host ""
    Read-Host "Press ENTER to return to the main menu"
}

try {
    if ($BuildOnly) {
        if (Check-Dependencies) {
            Write-Host "`n[✔] Build completed successfully. All dependencies are ready.`n"
            exit 0
        }
        Write-Host "`n[✖] Build failed. See error details above.`n"
        exit 1
    }

    Show-StartupAnimation

    while (-not (Check-Dependencies)) {
        # If dependency installation failed, retry after the user acknowledges.
    }

    while ($true) {
        Clear-Host
        Show-HeaderBanner
        Draw-BoxHeader "$C_GREENINITIALIZE SECURE DOWNLINK$C_RESET"
        Draw-BoxLine " Paste a YouTube URL below to fetch metadata."
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
        $metadata = Get-VideoMetadata -url $url
        if (-not $metadata.Success) {
            Show-ErrorScreen $metadata.Error
            continue
        }

        $heightList = $metadata.HeightList
        if (-not $heightList -or $heightList.Count -eq 0) {
            Show-ErrorScreen "No downloadable video resolutions were found for this URL."
            continue
        }

        $formattedViews = $metadata.Views
        if ($formattedViews -is [int] -or $formattedViews -is [int64]) {
            if ($formattedViews -ge 1000000) { $formattedViews = "$([Math]::Round($formattedViews / 1000000, 1))M views" }
            elseif ($formattedViews -ge 1000) { $formattedViews = "$([Math]::Round($formattedViews / 1000, 1))k views" }
            else { $formattedViews = "$formattedViews views" }
        }

        $releaseDate = "Unknown"
        if ($metadata.UploadDate -and $metadata.UploadDate.Length -eq 8) {
            $releaseDate = "$($metadata.UploadDate.Substring(0, 4))-$($metadata.UploadDate.Substring(4, 2))-$($metadata.UploadDate.Substring(6, 2))"
        }

        Clear-Host
        Show-HeaderBanner
        Draw-BoxHeader "$C_CYANTARGET ACQUIRED: VIDEO METADATA$C_RESET"
        Wrap-And-DrawBoxLines "Title:  " $metadata.Title
        Draw-BoxLine "Channel:    $metadata.Uploader"
        Draw-BoxLine "Duration:   $metadata.Duration"
        Draw-BoxLine "Views:      $formattedViews"
        Draw-BoxLine "Released:   $releaseDate"
        Draw-BoxLine "Source Res: $metadata.Resolution"

        $cleanThumb = $metadata.Thumbnail
        if ($cleanThumb.Length -gt 48) { $cleanThumb = $cleanThumb.Substring(0, 45) + "..." }
        Draw-BoxLine "Thumbnail:  $cleanThumb"
        Draw-BoxFooter
        Write-Host ""

        $choiceIdx = Select-Menu -heights $heightList
        $totalOptions = $heightList.Count + 2
        if ($choiceIdx -eq ($totalOptions - 1)) { continue }

        Clear-Host
        Show-HeaderBanner
        $global:PROGRESS_DRAWN = $false
        $startTime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $downloadsPath = Join-Path (Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads") "SUPER HUMAN"
        if (-not (Test-Path $downloadsPath)) { New-Item -ItemType Directory -Path $downloadsPath -Force | Out-Null }

        $outTemplate = Join-Path $downloadsPath "%(title)s.%(ext)s"
        $isAudio = $false
        $selectedRes = ""
        $dlArgs = @(
            "--newline",
            "--ffmpeg-location", $toolsDir,
            "--progress-template",
            "PROG:%(progress._percent_str)s|%(progress._speed_str)s|%(progress._eta_str)s|%(progress._total_bytes_str)s|%(progress._downloaded_bytes_str)s",
            "-o",
            $outTemplate
        )

        if ($choiceIdx -eq ($totalOptions - 2)) {
            $selectedRes = "MP3 Audio"
            $isAudio = $true
            $dlArgs += @(
                "-x",
                "--audio-format",
                "mp3",
                "--audio-quality",
                "0",
                $url
            )
        } else {
            $selectedHeight = $heightList[$choiceIdx]
            $selectedRes = "${selectedHeight}p"
            $downloadFormat = "bestvideo[height=${selectedHeight}]+bestaudio/best[height=${selectedHeight}]/best"
            $dlArgs += @(
                "-f",
                $downloadFormat,
                "--merge-output-format",
                "mp4",
                "--remux-video",
                "mp4",
                $url
            )
        }

        $psiDl = New-Object System.Diagnostics.ProcessStartInfo
        $psiDl.FileName = Join-Path $toolsDir "yt-dlp.exe"
        $psiDl.Arguments = ($dlArgs | ForEach-Object { if ($_ -match ' ') { '"' + $_ + '"' } else { $_ } }) -join ' '
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
                $currentFile = $line -replace '.*Destination:\s*', ''
                $currentFile = [System.IO.Path]::GetFileName($currentFile)
            } elseif ($line -like "PROG:*") {
                $data = $line -replace 'PROG:', ''
                $parts = $data.Split('|')
                if ($parts.Count -ge 5) {
                    $percent = $parts[0].Trim().Replace('%', '')
                    $speed = $parts[1].Trim()
                    $eta = $parts[2].Trim()
                    $total_size = $parts[3].Trim()
                    $dl_size = $parts[4].Trim()
                    Draw-ProgressUI -percent $percent -speed $speed -eta $eta -total_size $total_size -dl_size $dl_size -filename $currentFile -resolution $selectedRes
                }
            } else {
                if ($line -match "Merging" -or $line -match "Extracting audio") {
                    if ($global:PROGRESS_DRAWN) {
                        [Console]::Write("$esc[8A")
                    }
                    $global:PROGRESS_DRAWN = $true
                    Draw-BoxHeader "$C_PURPLEPOST-PROCESSING PROTOCOL$C_RESET"
                    Draw-BoxLine "  $C_YELLOW⚡ Merging/Extracting audio & video via ffmpeg...$C_RESET"
                    Draw-BoxLine "  Please wait while the final file is prepared."
                    Draw-BoxLine ""
                    Draw-BoxFooter
                }
            }
        }

        $stderrOut = $dlProcess.StandardError.ReadToEnd()
        $dlProcess.WaitForExit()
        $dl_status = $dlProcess.ExitCode
        [Console]::CursorVisible = $true

        $endTime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $durationSec = $endTime - $startTime
        if ($durationSec -le 0) { $durationSec = 1 }
        $download_time = "$durationSec seconds"

        if ($dl_status -eq 0) {
            Show-SuccessScreen -target_title $metadata.Title -res $selectedRes -dl_time $download_time -is_audio $isAudio
        } else {
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

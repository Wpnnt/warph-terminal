# media.ps1 - yt-dlp downloader suite and FFmpeg media converters

# yt-dlp internal helpers
function _yt_fmt ($Quality) {
    switch ($Quality.ToLower()) {
        '720'  { 'bestvideo[height<=720]+bestaudio/best[height<=720]' }
        '1080' { 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' }
        '2160' { 'bestvideo[height<=2160]+bestaudio/best[height<=2160]' }
        '4k'   { 'bestvideo[height<=2160]+bestaudio/best[height<=2160]' }
        default { 'bestvideo+bestaudio/best' }
    }
}

function _yt_run ($Url, $Audio, $Quality, $Type, $Dir) {
    $tpl = if ($Dir) { "$Dir\%(title)s.%(ext)s" } else { '%(title)s.%(ext)s' }
    if ($Dir) { New-Item -ItemType Directory -Force -Path $Dir | Out-Null }
    if ($Audio) {
        $audioType = if ($Type) { $Type } else { 'mp3' }
        yt-dlp -x --audio-format $audioType --audio-quality 0 -o $tpl @Url
    } else {
        $fmt = if ($Type) { "bestvideo[ext=$Type]+bestaudio/best[ext=$Type]" }
               else { _yt_fmt $Quality }
        yt-dlp -f $fmt -o $tpl @Url
    }
}

# yt-dlp interactive TUI
function yti {
    [CmdletBinding()]
    param([string]$Url)

    if (-not (_has yt-dlp)) {
        Write-Host "yt-dlp is not installed. Run 'setup.ps1' or 'winget install yt-dlp.yt-dlp'" -ForegroundColor Red
        return
    }

    $cyn = $PSStyle.Foreground.BrightCyan
    $grn = $PSStyle.Foreground.BrightGreen
    $ylw = $PSStyle.Foreground.BrightYellow
    $dim = $PSStyle.Foreground.BrightBlack
    $bld = $PSStyle.Bold
    $rst = $PSStyle.Reset

    Write-Host ""
    Write-Host "${cyn}${bld}  +--------------------------------------+"
    Write-Host "${cyn}${bld}  |        yt-dlp Interactive TUI        |"
    Write-Host "${cyn}${bld}  +--------------------------------------+"
    Write-Host ""

    if (-not $Url) {
        $clip = Get-Clipboard -ErrorAction SilentlyContinue
        if ($clip -and ($clip -match '^https?://')) {
            Write-Host "  Found URL in clipboard: ${grn}$clip${rst}"
            $useClip = Read-Host "  Use this URL? [Y/n]"
            if ($useClip -notmatch '^[nN]$') {
                $Url = $clip.Trim()
            }
        }
    }

    while (-not $Url) {
        $Url = Read-Host "  Enter Video/Audio URL"
        if (-not $Url) {
            Write-Host "  ${dim}Cancelled.${rst}"
            return
        }
    }

    Write-Host ""
    Write-Host "  Target: ${grn}$Url${rst}"
    Write-Host ""
    Write-Host "  ${bld}[1]${rst} ${grn}Best Video${rst}                  ${dim}(Current directory)${rst}"
    Write-Host "  ${bld}[2]${rst} ${cyn}Best Video -> ~/Videos${rst}         ${dim}(Auto-saved to Videos)${rst}"
    Write-Host "  ${bld}[3]${rst} ${ylw}Audio (MP3)${rst}                 ${dim}(Current directory)${rst}"
    Write-Host "  ${bld}[4]${rst} ${ylw}Audio (MP3) -> ~/Music${rst}        ${dim}(Auto-saved to Music)${rst}"
    Write-Host "  ${bld}[5]${rst} Custom Quality Video            ${dim}(720p / 1080p / 4K)${rst}"
    Write-Host "  ${bld}[6]${rst} Custom Audio Format            ${dim}(FLAC, WAV, M4A, OPUS)${rst}"
    Write-Host "  ${bld}[7]${rst} Inspect Formats                 ${dim}(List available streams)${rst}"
    Write-Host "  ${bld}[8]${rst} Cancel"
    Write-Host ""

    $choice = ''
    while ($choice -notin '1','2','3','4','5','6','7','8') {
        $choice = Read-Host "  Select option [1-8]"
    }

    switch ($choice) {
        '1' { yt $Url }
        '2' { vyt $Url }
        '3' { yta $Url }
        '4' { vyta $Url }
        '5' {
            Write-Host ""
            Write-Host "  Select quality: ${bld}[1]${rst} 720p  ${bld}[2]${rst} 1080p  ${bld}[3]${rst} 4K (2160p)"
            $qChoice = Read-Host "  Quality [1/2/3]"
            $q = switch ($qChoice) { '1' { '720' } '2' { '1080' } '3' { '4k' } default { '1080' } }
            Write-Host "  Destination: ${bld}[1]${rst} Current Dir  ${bld}[2]${rst} ~/Videos"
            $dChoice = Read-Host "  Dest [1/2]"
            if ($dChoice -eq '2') { vyt $Url -Quality $q } else { yt $Url -Quality $q }
        }
        '6' {
            Write-Host ""
            Write-Host "  Select format: ${bld}[1]${rst} flac  ${bld}[2]${rst} wav  ${bld}[3]${rst} m4a  ${bld}[4]${rst} opus"
            $fChoice = Read-Host "  Format [1-4]"
            $fmt = switch ($fChoice) { '1' { 'flac' } '2' { 'wav' } '3' { 'm4a' } '4' { 'opus' } default { 'flac' } }
            Write-Host "  Destination: ${bld}[1]${rst} Current Dir  ${bld}[2]${rst} ~/Music"
            $dChoice = Read-Host "  Dest [1/2]"
            if ($dChoice -eq '2') { vyta $Url -Type $fmt } else { yta $Url -Type $fmt }
        }
        '7' { ytls $Url }
        '8' { Write-Host "  ${dim}Cancelled.${rst}"; return }
    }
}

function yt {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)][string[]]$Url,
        [switch]$Audio,
        [string]$Quality,
        [string]$Type,
        [string]$Out
    )
    if (-not $Url -and -not $Audio -and -not $Quality -and -not $Type -and -not $Out) {
        yti
        return
    }
    _yt_run $Url $Audio $Quality $Type $Out
}

function yta {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)][string[]]$Url,
        [string]$Type,
        [string]$Out
    )
    _yt_run $Url $true $null $Type $Out
}

function vyt {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)][string[]]$Url,
        [switch]$Audio,
        [string]$Quality,
        [string]$Type
    )
    $dir = if ($Audio) { [Environment]::GetFolderPath('MyMusic') }
           else { [Environment]::GetFolderPath('MyVideos') }
    _yt_run $Url $Audio $Quality $Type $dir
}

function vyta {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)][string[]]$Url,
        [string]$Type
    )
    _yt_run $Url $true $null $Type ([Environment]::GetFolderPath('MyMusic'))
}

function ytls { yt-dlp -F @args }

# FFmpeg Media Converters
function tomp4 ($In) { ffmpeg -i $In -c:v libx264 -crf 23 -c:a aac -b:a 192k "$([IO.Path]::ChangeExtension($In, '.mp4'))" }
function tomp3 ($In) { ffmpeg -i $In -vn -c:a libmp3lame -q:a 0 "$([IO.Path]::ChangeExtension($In, '.mp3'))" }
function towav ($In) { ffmpeg -i $In -vn -c:a pcm_s16le "$([IO.Path]::ChangeExtension($In, '.wav'))" }
function togif ($In, [int]$Fps = 15, [int]$W = 480) { ffmpeg -i $In -vf "fps=$Fps,scale=${W}:-1:flags=lanczos" -loop 0 "$([IO.Path]::ChangeExtension($In, '.gif'))" }
function towebm ($In) { ffmpeg -i $In -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus "$([IO.Path]::ChangeExtension($In, '.webm'))" }
function toflac ($In) { ffmpeg -i $In -vn -c:a flac "$([IO.Path]::ChangeExtension($In, '.flac'))" }

# help.ps1 - Categorized help menu with clean Nerd Font icons and ANSI colors

function Show-Help {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Topic
    )

    $title   = $PSStyle.Foreground.BrightMagenta
    $section = $PSStyle.Foreground.BrightBlue
    $command = $PSStyle.Foreground.BrightGreen
    $desc    = $PSStyle.Foreground.BrightWhite
    $accent  = $PSStyle.Foreground.BrightYellow
    $dim     = $PSStyle.Foreground.BrightBlack
    $reset   = $PSStyle.Reset

    $icWsl   = [char]0xf17c  # 
    $icApps  = [char]0xf40e  # 
    $icNet   = [char]0xf0ac  # 
    $icApi   = [char]0xf1e6  # 
    $icClip  = [char]0xf0c5  # 
    $icDev   = [char]0xf121  # 
    $icDisk  = [char]0xf1f8  # 
    $icYt    = [char]0xf16a  # 
    $icMedia = [char]0xf008  # 
    $icCli   = [char]0xf489  # 
    $icSys   = [char]0xf013  # 
    $icTerm  = [char]0xf489  # 
    $sep     = "────────────────────────────────────────────────────"

    Write-Host @"
${title}${icTerm}  PowerShell Profile Help${reset}
${dim}${sep}${reset}

${section}${icWsl}  WSL${reset}
${dim}${sep}${reset}
  ${command}wls${reset}                ${accent}->${reset} ${desc}List installed WSL distros and their status${reset}
  ${command}woff${reset}               ${accent}->${reset} ${desc}Shut down all WSL distros at once (wsl --shutdown)${reset}
  ${command}wk <distro>${reset}        ${accent}->${reset} ${desc}Terminate a specific distro (ex: wk Ubuntu)${reset}
  ${command}wsh <distro>${reset}       ${accent}->${reset} ${desc}Open the shell of a distro (ex: wsh Ubuntu)${reset}

${section}${icApps}  Apps${reset}
${dim}${sep}${reset}
  ${command}ag [path]${reset}          ${accent}->${reset} ${desc}Open Antigravity IDE (optionally in a folder)${reset}
  ${command}ex [path]${reset}          ${accent}->${reset} ${desc}Open Windows Explorer in the current or given folder${reset}
  ${command}vlc <file>${reset}         ${accent}->${reset} ${desc}Open file/URL in VLC media player${reset}
  ${command}colorpick${reset}          ${accent}->${reset} ${desc}Open PowerToys Color Picker to copy a color${reset}

${section}${icNet}  Network${reset}
${dim}${sep}${reset}
  ${command}myip${reset}               ${accent}->${reset} ${desc}Show public IP + location (copies IP to clipboard)${reset}
  ${command}flushdns${reset}           ${accent}->${reset} ${desc}Clear the Windows DNS cache${reset}
  ${command}testport <host> <port>${reset} ${accent}->${reset} ${desc}Check if a port is reachable on a host${reset}

${section}${icApi}  cURL / APIs${reset}
${dim}${sep}${reset}
  ${command}curltime <url>${reset}     ${accent}->${reset} ${desc}Measure DNS/TLS/TTFB/total time of a request${reset}
  ${command}curlhead <url>${reset}     ${accent}->${reset} ${desc}Show HTTP response headers${reset}
  ${command}curlssl <host>${reset}     ${accent}->${reset} ${desc}Inspect the SSL certificate of a domain${reset}
  ${command}curlstatus <url>${reset}   ${accent}->${reset} ${desc}Show only the HTTP status code${reset}
  ${command}curlfollow <url>${reset}   ${accent}->${reset} ${desc}Trace the chain of HTTP redirects${reset}
  ${command}cget <url>${reset}         ${accent}->${reset} ${desc}Send GET with Accept: application/json${reset}
  ${command}cpost <url> <j>${reset}    ${accent}->${reset} ${desc}Send POST with JSON body${reset}
  ${command}cput <url> <j>${reset}     ${accent}->${reset} ${desc}Send PUT with JSON body${reset}
  ${command}cpatch <url> <j>${reset}   ${accent}->${reset} ${desc}Send PATCH with JSON body${reset}
  ${command}cdel <url>${reset}         ${accent}->${reset} ${desc}Send DELETE${reset}
  ${command}cdl <url>${reset}          ${accent}->${reset} ${desc}Download file with progress bar and resume${reset}
  ${command}cdlr <url>${reset}         ${accent}->${reset} ${desc}Download file with resume and up to 3 retries${reset}

${section}${icClip}  Clipboard / Text${reset}
${dim}${sep}${reset}
  ${command}<cmd> | cb${reset}         ${accent}->${reset} ${desc}Copy a command's output to the clipboard${reset}
  ${command}b64 <text>${reset}         ${accent}->${reset} ${desc}Encode text as Base64${reset}
  ${command}b64d <text>${reset}        ${accent}->${reset} ${desc}Decode Base64 back to text${reset}
  ${command}uuid${reset}              ${accent}->${reset} ${desc}Generate a random UUID v4${reset}
  ${command}genpass [len]${reset}      ${accent}->${reset} ${desc}Generate random password (default 20 chars) and copy${reset}

${section}${icDev}  Dev Workflow${reset}
${dim}${sep}${reset}
  ${command}nuke${reset}               ${accent}->${reset} ${desc}Delete node_modules/.next/dist and reinstall deps${reset}
  ${command}killport <port>${reset}    ${accent}->${reset} ${desc}Kill the process using a port${reset}

${section}${icDisk}  Disk / Cleanup${reset}
${dim}${sep}${reset}
  ${command}cleantemp${reset}          ${accent}->${reset} ${desc}Clear the %TEMP% folder and show how much was freed${reset}

${section}${icYt}  yt-dlp${reset}
${dim}${sep}${reset}
  ${command}yti [url]${reset}          ${accent}->${reset} ${desc}Interactive TUI downloader (auto-reads clipboard)${reset}
  ${command}yt [url]${reset}           ${accent}->${reset} ${desc}best quality video (or opens interactive TUI)${reset}
  ${command}yta <url>${reset}           ${accent}->${reset} ${desc}MP3 audio -> current directory${reset}
  ${command}vyt <url>${reset}           ${accent}->${reset} ${desc}best quality video -> ~/Videos${reset}
  ${command}vyta <url>${reset}          ${accent}->${reset} ${desc}MP3 audio -> ~/Music${reset}
  ${dim}  Flags: ${command}-q 720/1080/4k${dim} quality, ${command}-Type mp4/webm/mkv${dim} or ${command}mp3/flac/m4a${dim}, ${command}-Out <dir>${dim} destination${reset}
  ${command}yt <url> -q 1080${reset}    ${accent}->${reset} ${desc}video capped at 1080p${reset}
  ${command}vyta <url> -Type flac${reset} ${accent}->${reset} ${desc}FLAC -> ~/Music${reset}
  ${command}ytls <url>${reset}          ${accent}->${reset} ${desc}List the available formats${reset}

${section}${icMedia}  FFmpeg${reset}
${dim}${sep}${reset}
  ${command}tomp4 <file>${reset}       ${accent}->${reset} ${desc}Convert to MP4 (H.264 + AAC)${reset}
  ${command}tomp3 <file>${reset}       ${accent}->${reset} ${desc}Extract/convert audio to MP3${reset}
  ${command}towav <file>${reset}       ${accent}->${reset} ${desc}Convert to WAV (PCM 16-bit)${reset}
  ${command}toflac <file>${reset}      ${accent}->${reset} ${desc}Convert to FLAC (lossless)${reset}
  ${command}togif <f> [fps] [w]${reset} ${accent}->${reset} ${desc}Convert to GIF (default 15fps, 480px)${reset}
  ${command}towebm <file>${reset}      ${accent}->${reset} ${desc}Convert to WebM (VP9 + Opus)${reset}

${section}${icCli}  Modern CLI Tools${reset}
${dim}${sep}${reset}
  ${command}la${reset}                 ${accent}->${reset} ${desc}eza: list files with icons (includes hidden)${reset}
  ${command}ll${reset}                 ${accent}->${reset} ${desc}eza: detailed listing with git status${reset}
  ${command}ff <name>${reset}          ${accent}->${reset} ${desc}fd: fast file finder shortcut${reset}
  ${command}bat <file>${reset}         ${accent}->${reset} ${desc}syntax-highlighted file viewer with line numbers${reset}
  ${command}rg <pattern>${reset}       ${accent}->${reset} ${desc}ripgrep: ultra-fast text search${reset}
  ${command}dust${reset}               ${accent}->${reset} ${desc}interactive visual disk usage analyzer${reset}
  ${command}btm${reset}                ${accent}->${reset} ${desc}bottom: modern CPU, memory & process monitor${reset}
  ${command}procs${reset}              ${accent}->${reset} ${desc}modern process tree and status viewer${reset}
  ${command}yazi${reset}               ${accent}->${reset} ${desc}terminal file manager${reset}
  ${command}gitui${reset}              ${accent}->${reset} ${desc}interactive terminal git user interface${reset}
  ${command}tokei [path]${reset}       ${accent}->${reset} ${desc}count lines of code by language${reset}
  ${command}hyperfine <cmd>${reset}    ${accent}->${reset} ${desc}benchmark execution speed of commands${reset}
  ${command}xh <url>${reset}           ${accent}->${reset} ${desc}friendly HTTP client for APIs${reset}
  ${command}broot${reset}              ${accent}->${reset} ${desc}interactive directory tree navigation${reset}

${section}${icSys}  System${reset}
${dim}${sep}${reset}
  ${command}touch <file>${reset}       ${accent}->${reset} ${desc}Create empty file or update timestamp${reset}
  ${command}mkcd <dir>${reset}         ${accent}->${reset} ${desc}Create a folder and enter it${reset}
  ${command}trash <path>${reset}       ${accent}->${reset} ${desc}Move to Recycle Bin (safe delete)${reset}
  ${command}pgrep / pkill / k9${reset} ${accent}->${reset} ${desc}Find / kill processes by name${reset}
  ${command}unzip <file>${reset}       ${accent}->${reset} ${desc}Extract a .zip file${reset}
  ${command}c${reset}                  ${accent}->${reset} ${desc}Clear the screen (Clear-Host)${reset}
  ${command}uptime${reset}             ${accent}->${reset} ${desc}Show how long the PC has been on${reset}
  ${command}winutil${reset}            ${accent}->${reset} ${desc}Run Chris Titus WinUtil (Windows tweaks)${reset}

${dim}${sep}${reset}
"@
}

Set-Alias -Name show -Value Show-Help -Description "Alias for Show-Help"


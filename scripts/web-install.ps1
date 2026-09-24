# web-install.ps1 — Warph Terminal Standalone Web Installer
# Usage:
#   irm <url> | iex
#   irm <url> | iex -ArgumentList "-Install", "-Mode", "3"

#Requires -Version 7

[CmdletBinding()]
param(
    [string]$Branch = 'main',
    [switch]$Install,
    [ValidateSet('1', '2', '3')]
    [string]$Mode = '3',
    [switch]$SkipOptional,
    [switch]$NoTUI,
    [switch]$TUI,
    [switch]$Quiet
)

if ($env:WARPH_BRANCH) {
    $Branch = $env:WARPH_BRANCH
}

$grn  = $PSStyle.Foreground.BrightGreen
$ylw  = $PSStyle.Foreground.BrightYellow
$cyn  = $PSStyle.Foreground.BrightCyan
$red  = $PSStyle.Foreground.BrightRed
$wht  = $PSStyle.Foreground.White
$dim  = $PSStyle.Foreground.BrightBlack
$bold = $PSStyle.Bold
$rst  = $PSStyle.Reset
$w0   = $PSStyle.Foreground.FromRgb(255, 255, 255)

if ($env:NO_COLOR) {
    $grn = $ylw = $cyn = $red = $wht = $dim = $bold = $rst = $w0 = ""
}

# 1. PowerShell 7+ verification
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host ""
    Write-Host "${red}${bold}[ERROR] Warph Terminal requires PowerShell 7 or higher.${rst}"
    Write-Host "You are currently running PowerShell $($PSVersionTable.PSVersion)."
    Write-Host ""
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $doInstallPwsh = Read-Host "  Install PowerShell 7 now via winget? [Y/n]"
        if ($doInstallPwsh -notmatch '^[nN]$') {
            winget install --id Microsoft.PowerShell -e --source winget --accept-package-agreements --accept-source-agreements
            Write-Host "${grn}Please relaunch this script inside PowerShell 7 (pwsh.exe).${rst}"
            return
        }
    } else {
        Write-Host "Install PowerShell 7 via winget:"
        Write-Host "  ${cyn}winget install Microsoft.PowerShell${rst}"
    }
    Write-Host ""
    return
}

# 2. Windows Terminal verification (REQUIRED)
$hasWT = (Get-Command wt -ErrorAction SilentlyContinue) -or (Get-AppxPackage Microsoft.WindowsTerminal* -ErrorAction SilentlyContinue)
if (-not $hasWT) {
    Write-Host ""
    Write-Host "${ylw}${bold}[!] Windows Terminal is REQUIRED for Warph Terminal.${rst}"
    Write-Host "  (Legacy console host cannot render glyphs, true-color ANSI or SVG icons)"
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $doInstallWT = Read-Host "  Install Windows Terminal now via winget? [Y/n]"
        if ($doInstallWT -notmatch '^[nN]$') {
            winget install --id Microsoft.WindowsTerminal -e --source winget --accept-package-agreements --accept-source-agreements
        }
    }
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

$version = $null
if (-not $Branch -or $Branch -eq 'main') {
    try {
        $latestRel = Invoke-RestMethod -Uri "https://api.github.com/repos/Wpnnt/warph-terminal/releases/latest" -Headers @{'User-Agent'='Warph-Terminal-Web-Installer'} -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($latestRel -and $latestRel.tag_name) {
            $version = $latestRel.tag_name
        }
    } catch { }
}

function Get-TerminalWidth {
    try {
        $w = $Host.UI.RawUI.WindowSize.Width
        if ($w -and $w -ge 40) { return $w }
    } catch { }
    return 120
}

function Show-WarphBanner {
    $w = Get-TerminalWidth
    $logoPad = " " * [Math]::Max(0, [int](($w - 72) / 2))

    $bannerFile = if ($PSScriptRoot) { Join-Path $PSScriptRoot "..\assets\banner.ansi" } else { $null }
    $bannerText = $null
    if ($bannerFile -and (Test-Path -LiteralPath $bannerFile)) {
        $bannerText = Get-Content -LiteralPath $bannerFile -Raw
    } else {
        # Embedded fallback for standalone remote execution (irm da.gd/warph | iex)
        $b64 = "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"
        try {
            $gzBytes = [Convert]::FromBase64String($b64)
            $msIn    = [System.IO.MemoryStream]::new($gzBytes)
            $gzDec   = [System.IO.Compression.GZipStream]::new($msIn, [System.IO.Compression.CompressionMode]::Decompress)
            $sr      = [System.IO.StreamReader]::new($gzDec, [System.Text.Encoding]::UTF8)
            $bannerText = $sr.ReadToEnd()
        } catch { }
    }

    if ($bannerText) {
        Write-Host ""
        $lines = $bannerText -split "\r?\n"
        foreach ($l in $lines) {
            if ($l.Trim().Length -gt 0) {
                Write-Host "$logoPad$l"
            } else {
                Write-Host ""
            }
        }
    }

    Write-Host ""
    $vBadge = if ($Branch -and $Branch -ne 'main') { "  ${cyn}[$Branch]${rst}" } elseif ($version) { "  ${dim}$version${rst}" } else { "" }
    Write-Host "  ${w0}${bold}WARPH TERMINAL${rst}$vBadge"
    Write-Host "  ${dim}modular · fast · powershell${rst}"
    Write-Host ""
}

# When executed inside a local repository clone, delegate directly to local setup.ps1
$localSetup = if ($PSScriptRoot) { Join-Path $PSScriptRoot "..\setup.ps1" } else { $null }
if ($localSetup -and (Test-Path -LiteralPath $localSetup)) {
    if ($Install) {
        & (Resolve-Path $localSetup).Path -Install -Mode:$Mode -SkipOptional:$SkipOptional -Quiet:$Quiet -NoTUI:$NoTUI -TUI:$TUI
    } else {
        & (Resolve-Path $localSetup).Path -NoTUI:$NoTUI -TUI:$TUI
    }
    return
}

if (-not $Quiet) {
    Show-WarphBanner
}

$tempZip     = Join-Path ([System.IO.Path]::GetTempPath()) "warph-terminal-latest-$([System.Guid]::NewGuid().ToString('N').Substring(0,8)).zip"
$tempExtract = Join-Path ([System.IO.Path]::GetTempPath()) "warph-setup-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
$zipUrl      = if ($Branch -and $Branch -ne 'main') {
    "https://github.com/Wpnnt/warph-terminal/archive/refs/heads/$Branch.zip"
} elseif ($version) {
    "https://github.com/Wpnnt/warph-terminal/releases/download/$version/warph-terminal.zip"
} else {
    "https://github.com/Wpnnt/warph-terminal/archive/refs/heads/main.zip"
}

try {
    $relText = if ($Branch -and $Branch -ne 'main') { "$Branch (preview)" } elseif ($version) { $version } else { "package" }
    Write-Host "  ${dim}downloading $relText...${rst} " -NoNewline
    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing
    } catch {
        if ($Branch -and $Branch -ne 'main') {
            throw "Failed to download branch archive: $_"
        }
        $zipUrl = "https://github.com/Wpnnt/warph-terminal/archive/refs/heads/main.zip"
        Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing
    }
    Write-Host "${dim}done${rst}"

    Write-Host "  ${dim}extracting assets...${rst} " -NoNewline
    Expand-Archive -LiteralPath $tempZip -DestinationPath $tempExtract -Force
    Write-Host "${dim}done${rst}"
    Write-Host ""

    # Locate setup.ps1 and execute
    $setupScript = Get-ChildItem -Path $tempExtract -Recurse -Filter "setup.ps1" | Where-Object { $_.Directory.Name -eq (Split-Path $_.DirectoryName -Leaf) -or $_.Directory.Name -match "warph-terminal" } | Select-Object -First 1
    if (-not $setupScript) {
        $setupScript = Get-ChildItem -Path $tempExtract -Recurse -Filter "setup.ps1" | Select-Object -First 1
    }

    if (-not $setupScript -or -not (Test-Path -LiteralPath $setupScript.FullName)) {
        throw "Could not locate setup.ps1 inside extracted archive."
    }

    if ($Install) {
        $env:WARPH_NO_BANNER = "1"
        & $setupScript.FullName -Install -Mode:$Mode -SkipOptional:$SkipOptional -Quiet:$Quiet -NoTUI:$NoTUI -TUI:$TUI
    } else {
        & $setupScript.FullName -NoTUI:$NoTUI -TUI:$TUI
    }

} catch {
    Write-Host ""
    Write-Host "  ${red}${bold}[error]${rst} Installation failed: $_"
} finally {
    Remove-Item env:WARPH_NO_BANNER -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $tempZip) {
        Remove-Item -LiteralPath $tempZip -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $tempExtract) {
        Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
}

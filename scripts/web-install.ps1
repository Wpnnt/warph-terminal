# web-install.ps1 — Warph Terminal Standalone Web Installer
# Usage:
#   irm <url> | iex
#   irm <url> | iex -ArgumentList "-Install", "-Mode", "3"

#Requires -Version 7

[CmdletBinding()]
param(
    [switch]$Install,
    [ValidateSet('1', '2', '3')]
    [string]$Mode = '3',
    [switch]$SkipOptional,
    [switch]$Quiet
)

$grn  = $PSStyle.Foreground.BrightGreen
$ylw  = $PSStyle.Foreground.BrightYellow
$cyn  = $PSStyle.Foreground.BrightCyan
$red  = $PSStyle.Foreground.BrightRed
$dim  = $PSStyle.Foreground.BrightBlack
$bold = $PSStyle.Bold
$rst  = $PSStyle.Reset

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

Write-Host ""
Write-Host "${cyn}${bold}Warph Terminal Web Installer${rst}"
Write-Host "${dim}Fetching latest release from GitHub...${rst}"

$tempZip     = Join-Path ([System.IO.Path]::GetTempPath()) "warph-terminal-latest-$([System.Guid]::NewGuid().ToString('N').Substring(0,8)).zip"
$tempExtract = Join-Path ([System.IO.Path]::GetTempPath()) "warph-setup-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
$zipUrl      = "https://github.com/Wpnnt/warph-terminal/archive/refs/heads/main.zip"

try {
    # 2. Download repository archive
    Write-Host "  ${dim}[1/3]${rst} Downloading package archive..." -NoNewline
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing
    Write-Host " ${grn}[OK]${rst}"

    # 3. Extract to temporary workspace
    Write-Host "  ${dim}[2/3]${rst} Extracting installation assets..." -NoNewline
    Expand-Archive -LiteralPath $tempZip -DestinationPath $tempExtract -Force
    Write-Host " ${grn}[OK]${rst}"

    # 4. Locate setup.ps1 and execute
    $setupScript = Get-ChildItem -Path $tempExtract -Recurse -Filter "setup.ps1" | Where-Object { $_.Directory.Name -eq (Split-Path $_.DirectoryName -Leaf) -or $_.Directory.Name -match "warph-terminal" } | Select-Object -First 1
    if (-not $setupScript) {
        $setupScript = Get-ChildItem -Path $tempExtract -Recurse -Filter "setup.ps1" | Select-Object -First 1
    }

    if (-not $setupScript -or -not (Test-Path -LiteralPath $setupScript.FullName)) {
        throw "Could not locate setup.ps1 inside extracted archive."
    }

    Write-Host "  ${dim}[3/3]${rst} Launching setup engine..."
    Write-Host ""

    # Pass through parameters or launch interactive menu
    if ($Install) {
        & $setupScript.FullName -Install -Mode:$Mode -SkipOptional:$SkipOptional -Quiet:$Quiet
    } else {
        & $setupScript.FullName
    }

} catch {
    Write-Host ""
    Write-Host "${red}${bold}[ERROR] Installation failed:${rst} $_"
} finally {
    # 5. Clean up temporary files
    if (Test-Path -LiteralPath $tempZip) {
        Remove-Item -LiteralPath $tempZip -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $tempExtract) {
        Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
}

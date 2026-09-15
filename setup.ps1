# setup.ps1 - Warph Terminal Interactive Installer, Repairer & Uninstaller
# Usage:
#   .\setup.ps1                        (Interactive menu)
#   .\setup.ps1 -Install [-Mode 1|2|3] (Direct install)
#   .\setup.ps1 -Repair                (Fix moved paths & refresh installed files)
#   .\setup.ps1 -Uninstall [-Force]    (Clean uninstall)
#   .\setup.ps1 -Audit                 (Run full test suite & benchmark)

#Requires -Version 7

[CmdletBinding(DefaultParameterSetName = 'Interactive')]
param(
    [Parameter(ParameterSetName = 'Install')]
    [switch]$Install,

    [Parameter(ParameterSetName = 'Install')]
    [ValidateSet('1', '2', '3')]
    [string]$Mode,

    [Parameter(ParameterSetName = 'Install')]
    [switch]$SkipOptional,

    [Parameter(ParameterSetName = 'Repair')]
    [switch]$Repair,

    [Parameter(ParameterSetName = 'Uninstall')]
    [switch]$Uninstall,

    [Parameter(ParameterSetName = 'Uninstall')]
    [switch]$Force,

    [Parameter(ParameterSetName = 'Audit')]
    [switch]$Audit,

    [Parameter(ParameterSetName = 'Prereqs')]
    [switch]$CheckPrereqs,

    [Parameter(ParameterSetName = 'Prereqs')]
    [switch]$InstallPrereqs,

    [Parameter(ParameterSetName = 'Install')]
    [Parameter(ParameterSetName = 'SetFont')]
    [string]$Font,

    [Parameter(ParameterSetName = 'SetFont')]
    [switch]$SetFont,

    [switch]$Quiet
)

$grn  = $PSStyle.Foreground.BrightGreen
$ylw  = $PSStyle.Foreground.BrightYellow
$cyn  = $PSStyle.Foreground.BrightCyan
$red  = $PSStyle.Foreground.BrightRed
$dim  = $PSStyle.Foreground.BrightBlack
$bold = $PSStyle.Bold
$rst  = $PSStyle.Reset

# Project Paths
$repoRoot = if (Test-Path (Join-Path $PSScriptRoot "src\Microsoft.PowerShell_profile.ps1")) {
    $PSScriptRoot
} else {
    Split-Path $PSScriptRoot -Parent
}
$profileSrc       = Join-Path $repoRoot "src\Microsoft.PowerShell_profile.ps1"
$configSrc        = Join-Path $repoRoot "src\config"
$modulesSrc       = Join-Path $repoRoot "src\modules"
$assetsSrc        = Join-Path $repoRoot "assets"
$themeSrc         = Join-Path $repoRoot "themes\cobalt2.omp.json"
if (-not (Test-Path -LiteralPath $themeSrc)) {
    $themeSrc = Join-Path $repoRoot "cobalt2.omp.json"
}

$userHome         = [Environment]::GetFolderPath('UserProfile')
$installDir       = Join-Path $userHome ".warph-terminal"
$installedProfile = Join-Path $installDir "Microsoft.PowerShell_profile.ps1"
$installedTheme   = Join-Path $installDir "cobalt2.omp.json"
$installedLogo    = Join-Path $installDir "assets\logo.svg"
$profileDir       = Split-Path $PROFILE
$themeDest        = Join-Path $profileDir "cobalt2.omp.json"

function Write-Step ($n, $total, $msg) {
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "${cyn}${bold}[$n/$total]${rst} ${bold}$msg${rst}"
    }
}
function Write-Ok  ($msg) { if (-not $Quiet) { Write-Host "  ${grn}[OK]${rst} $msg" } }
function Write-Skip($msg) { if (-not $Quiet) { Write-Host "  ${dim}[SKIP] $msg (skipped)${rst}" } }
function Write-Err ($msg) { Write-Host "  ${red}[FAIL] $msg${rst}" }
function Write-Info($msg) { if (-not $Quiet) { Write-Host "  ${ylw}  $msg${rst}" } }

function Get-WTSettingsPath {
    $paths = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:APPDATA\Microsoft\Windows Terminal\settings.json"
    )
    $found = ($paths | Where-Object { Test-Path $_ } | Select-Object -First 1)
    if ($found) { return $found }

    # If package exists but settings.json has not yet been initialized, create initial structure
    $pkgDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    if (Test-Path $pkgDir) {
        $target = Join-Path $pkgDir "settings.json"
        @{ profiles = @{ list = @() } } | ConvertTo-Json -Depth 5 | Set-Content $target -Encoding UTF8
        return $target
    }
    return $null
}

function Test-Prerequisites {
    [CmdletBinding()]
    param(
        [switch]$AutoInstall
    )

    Write-Host ""
    Write-Host "${cyn}${bold}  +----------------------------------------------+${rst}"
    Write-Host "${cyn}${bold}  |       Warph Terminal - Prerequisites Check   |${rst}"
    Write-Host "${cyn}${bold}  +----------------------------------------------+${rst}"
    Write-Host ""

    $allPassed = $true

    # 1. PowerShell 7+
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Ok "PowerShell $($PSVersionTable.PSVersion) (Required: 7.4+)"
    } else {
        Write-Err "PowerShell 7+ is required. Current: $($PSVersionTable.PSVersion)"
        $allPassed = $false
        $doInstallPwsh = $AutoInstall
        if (-not $doInstallPwsh -and -not $Quiet) {
            $resp = Read-Host "  Install PowerShell 7 now via winget? [Y/n]"
            $doInstallPwsh = ($resp -notmatch '^[nN]$')
        }
        if ($doInstallPwsh) {
            Write-Info "Installing PowerShell 7 via winget..."
            winget install --id Microsoft.PowerShell -e --source winget --accept-package-agreements --accept-source-agreements
        }
    }

    # 2. Windows Terminal (REQUIRED)
    $wtCmd = Get-Command wt -ErrorAction SilentlyContinue
    $wtPkg = Get-AppxPackage Microsoft.WindowsTerminal* -ErrorAction SilentlyContinue
    $wtSettings = Get-WTSettingsPath

    if ($wtCmd -or $wtPkg -or $wtSettings) {
        Write-Ok "Windows Terminal is installed (Required host)"
    } else {
        Write-Err "Windows Terminal is REQUIRED (legacy conhost/cmd cannot render glyphs, true-color ANSI or SVG icons)."
        $allPassed = $false
        $doInstallWT = $AutoInstall
        if (-not $doInstallWT -and -not $Quiet) {
            $resp = Read-Host "  Install Windows Terminal now via winget? [Y/n]"
            $doInstallWT = ($resp -notmatch '^[nN]$')
        }
        if ($doInstallWT) {
            Write-Info "Installing Windows Terminal via winget..."
            winget install --id Microsoft.WindowsTerminal -e --source winget --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "Windows Terminal installed successfully"
                $allPassed = $true
            } else {
                Write-Err "Failed to install Windows Terminal (code $LASTEXITCODE)"
            }
        }
    }

    # 3. Font (Optional Nerd Font, default Cascadia Mono)
    $userFonts = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $winFonts  = "$env:WINDIR\Fonts"
    $hasNerdFont = Get-ChildItem -Path $userFonts, $winFonts -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "Nerd|Caskaydia" } | Select-Object -First 1

    if ($hasNerdFont) {
        Write-Ok "Nerd Font detected: $($hasNerdFont.Name) (Full icon & glyph support)"
    } else {
        Write-Ok "System font available: Cascadia Mono (Nerd Font is optional for extra icons)"
    }

    # 4. Windows Package Manager (winget)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Ok "Windows Package Manager (winget) is available"
    } else {
        Write-Err "winget not found in PATH (automated tool installation may fail)."
        $allPassed = $false
    }

    Write-Host ""
    return $allPassed
}

function Get-AvailableNerdFonts {
    $keys = @('HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts')
    $fonts = foreach ($k in $keys) {
        if (Test-Path $k) {
            $prop = Get-ItemProperty $k -ErrorAction SilentlyContinue
            if ($prop) {
                $prop | Get-Member -MemberType NoteProperty |
                    Where-Object { $_.Name -match 'Nerd|Cascadia|Caskaydia' -and $_.Name -notmatch 'Bold|Italic' } |
                    ForEach-Object {
                        $clean = $_.Name -replace '\s*\((?:TrueType|OpenType)\)\s*$', ''
                        $clean = $clean -replace '\s+(?:Regular|ExtraLight|Light|SemiLight|SemiBold|Medium)$', ''
                        $clean
                    }
            }
        }
    }
    return ($fonts | Where-Object { $_ } | Sort-Object -Unique)
}

function Set-TerminalFont {
    [CmdletBinding()]
    param(
        [string]$FontName
    )

    $wtSettings = Get-WTSettingsPath
    if (-not $wtSettings -or -not (Test-Path $wtSettings)) {
        Write-Err "Windows Terminal settings.json not found."
        return $false
    }

    if (-not $FontName) {
        $avail = Get-AvailableNerdFonts
        Write-Host ""
        Write-Host "${cyn}${bold}  +----------------------------------------------+${rst}"
        Write-Host "${cyn}${bold}  |            Select Terminal Font              |${rst}"
        Write-Host "${cyn}${bold}  +----------------------------------------------+${rst}"
        Write-Host ""

        $fontChoices = [System.Collections.Generic.List[string]]::new()
        foreach ($f in $avail) {
            $fontChoices.Add($f)
        }
        if (-not ($fontChoices -contains "Cascadia Mono")) {
            $fontChoices.Add("Cascadia Mono (System Default)")
        }
        if (-not ($fontChoices -contains "Consolas")) {
            $fontChoices.Add("Consolas (Built-in Windows)")
        }

        Write-Host "  Available Fonts:"
        for ($i = 0; $i -lt $fontChoices.Count; $i++) {
            Write-Host "    ${bold}[$($i+1)]${rst} $($fontChoices[$i])"
        }
        Write-Host "    ${bold}[C]${rst} Enter custom font name"
        Write-Host "    ${bold}[I]${rst} Install new Nerd Font (via oh-my-posh)"
        Write-Host ""
        $choice = Read-Host "  Choose option [1-$($fontChoices.Count), C, I] (Default: 1)"
        if (-not $choice) { $choice = '1' }

        if ($choice -match '^[0-9]+$' -and [int]$choice -ge 1 -and [int]$choice -le $fontChoices.Count) {
            $selected = $fontChoices[[int]$choice - 1]
            $FontName = ($selected -replace '\s*\(.*?\)', '').Trim()
        } elseif ($choice -match '^[iI]$') {
            Write-Host ""
            Write-Host "  Popular options: CascadiaCode, JetBrainsMono, FiraCode, Meslo, Hack"
            $newFont = Read-Host "  Enter font name to install (default: CascadiaCode)"
            if (-not $newFont) { $newFont = "CascadiaCode" }
            $omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
            if ($omp) {
                & oh-my-posh font install $newFont --headless
                $FontName = "$newFont Nerd Font"
            } else {
                Write-Err "oh-my-posh is required to install fonts."
            }
        } elseif ($choice -match '^[cC]$') {
            $FontName = Read-Host "  Enter font face name (e.g. Cascadia Mono, 0xProto Nerd Font)"
        }
    }

    if (-not $FontName) {
        Write-Info "No font selected. Keeping current configuration."
        return $false
    }

    $json = Get-Content $wtSettings -Raw | ConvertFrom-Json
    $wtProfile = $json.profiles.list | Where-Object { $_.name -eq "Warph Terminal" }
    if (-not $wtProfile) {
        Write-Info "Warph Terminal profile not found. Initializing profile in Windows Terminal with font '$FontName'..."
        Invoke-InstallAction -selectedMode '1' -noOptional $true -customFont $FontName
        return $true
    }

    if (-not $wtProfile.font) {
        $wtProfile | Add-Member -MemberType NoteProperty -Name "font" -Value ([PSCustomObject]@{ face = $FontName }) -Force
    } else {
        $wtProfile.font.face = $FontName
    }

    $json | ConvertTo-Json -Depth 20 | Set-Content $wtSettings -Encoding UTF8
    Write-Ok "Windows Terminal profile 'Warph Terminal' updated with font: ${cyn}$FontName${rst}"

    # Verify and grant font permissions
    $userFonts = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    if (Test-Path -LiteralPath $userFonts) {
        icacls $userFonts /grant "*S-1-15-2-1:(OI)(CI)RX" /t | Out-Null
    }

    return $true
}

function Install-WingetPkg ($id, $name) {
    if (Get-Command $name -ErrorAction SilentlyContinue) {
        Write-Skip "$name already installed"
        return
    }
    Write-Info "Installing $name..."
    winget install --id $id --accept-package-agreements --accept-source-agreements --silent
    if ($LASTEXITCODE -eq 0) { Write-Ok "$name installed" }
    else { Write-Err "Failed to install $name (code $LASTEXITCODE)" }
}

function Install-PSModule ($modName) {
    if (Get-Module -ListAvailable -Name $modName) {
        Write-Skip "$modName already installed"
        return
    }
    Write-Info "Installing module $modName..."
    Install-Module -Name $modName -Repository PSGallery -Force -Scope CurrentUser
    Write-Ok "$modName installed"
}

function Invoke-InstallAction ($selectedMode, $noOptional, $customFont) {
    $TOTAL = 4
    Write-Host ""
    Write-Host "${cyn}${bold}  +--------------------------------------+"
    Write-Host "${cyn}${bold}  |     Warph Terminal - Installation    |"
    Write-Host "${cyn}${bold}  +--------------------------------------+"
    Write-Host "  Install Target: ${dim}$installDir${rst}"

    # Verify Prerequisites before proceeding
    $prereqsOk = Test-Prerequisites -AutoInstall:$noOptional
    if (-not $prereqsOk -and -not $Quiet) {
        Write-Host "  ${ylw}Continuing installation. You can install missing prerequisites anytime with Option [2].${rst}"
        Write-Host ""
    }

    # Step 1: Mode Selection
    if (-not $selectedMode) {
        Write-Step 1 $TOTAL "Installation mode"
        Write-Host "  ${bold}[1]${rst} Profile in ${cyn}Windows Terminal${rst}  ${dim}(dedicated dropdown entry & optional default)${rst}"
        Write-Host "  ${bold}[2]${rst} Loader in ${cyn}`$PROFILE${rst}          ${dim}(applies to all terminals: VS Code, Antigravity, pwsh)${rst}"
        Write-Host "  ${bold}[3]${rst} Both ${grn}(Recommended)${rst}"
        Write-Host ""
        while ($selectedMode -notin '1','2','3') {
            $selectedMode = Read-Host "  Choose [1/2/3]"
        }
    }

    $doWT      = $selectedMode -in '1','3'
    $doSymlink = $selectedMode -in '2','3'

    # Step 2: Install files to ~/.warph-terminal (portable, user-independent)
    Write-Step 2 $TOTAL "Installing core modular files to ~/.warph-terminal"
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    if (Test-Path -LiteralPath $profileSrc) {
        Copy-Item -LiteralPath $profileSrc -Destination $installedProfile -Force
        Write-Ok "Profile entrypoint copied -> $installedProfile"
    } else {
        Write-Err "Profile source not found at $profileSrc"
    }

    # Copy config
    if (Test-Path -LiteralPath $configSrc) {
        $targetCfgDir = Join-Path $installDir "config"
        New-Item -ItemType Directory -Force -Path $targetCfgDir | Out-Null
        Copy-Item -Path (Join-Path $configSrc "*") -Destination $targetCfgDir -Force
        Write-Ok "Config copied -> $targetCfgDir"
    } else {
        Write-Err "Config source not found at $configSrc"
    }

    # Copy modules
    if (Test-Path -LiteralPath $modulesSrc) {
        $targetModDir = Join-Path $installDir "modules"
        New-Item -ItemType Directory -Force -Path $targetModDir | Out-Null
        Copy-Item -Path (Join-Path $modulesSrc "*") -Destination $targetModDir -Force
        Write-Ok "Modules copied -> $targetModDir"
    } else {
        Write-Err "Modules source not found at $modulesSrc"
    }

    # Copy themes
    if (Test-Path -LiteralPath $themeSrc) {
        $targetThemeDir = Join-Path $installDir "themes"
        New-Item -ItemType Directory -Force -Path $targetThemeDir | Out-Null
        Copy-Item -LiteralPath $themeSrc -Destination (Join-Path $targetThemeDir "cobalt2.omp.json") -Force
        Copy-Item -LiteralPath $themeSrc -Destination $installedTheme -Force
        Write-Ok "Theme copied -> $installedTheme"
        # Also copy to $profileDir for oh-my-posh fallback
        New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
        Copy-Item -LiteralPath $themeSrc -Destination $themeDest -Force
    } else {
        Write-Err "Theme source not found at $themeSrc"
    }

    # Copy assets
    if (Test-Path -LiteralPath $assetsSrc) {
        $targetAssetDir = Join-Path $installDir "assets"
        New-Item -ItemType Directory -Force -Path $targetAssetDir | Out-Null
        Copy-Item -Path (Join-Path $assetsSrc "*") -Destination $targetAssetDir -Force
        Write-Ok "Assets copied -> $targetAssetDir"
    }

    # Step 3: Profiles Configuration
    Write-Step 3 $TOTAL "Configuring profile targets"

    # Option 1: Windows Terminal
    if ($doWT) {
        $wtSettings = Get-WTSettingsPath
        if (-not $wtSettings) {
            Write-Err "Windows Terminal settings not found."
        } else {
            Write-Info "settings.json: $wtSettings"
            $wtBackup = "$wtSettings.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item $wtSettings $wtBackup
            Write-Ok "Backup created: $wtBackup"

            $json = Get-Content $wtSettings -Raw | ConvertFrom-Json
            $profileName = "Warph Terminal"
            # Use fully resolved $installedProfile path — pwsh.exe does NOT expand Windows %USERPROFILE% syntax
            $cmdline     = "pwsh.exe -NoExit -ExecutionPolicy Bypass -File `"$installedProfile`""
            $profileGuid = "{$(([System.Guid]::NewGuid()).ToString())}"
            $iconPath    = if (Test-Path -LiteralPath $installedLogo) { $installedLogo } else { "ms-appx:///ProfileIcons/{61c54bbd-c2c6-5271-96e7-009a87ff44bf}.png" }

            # Resolve font for profile
            $targetFont = $customFont
            if (-not $targetFont) {
                if ($existing -and $existing.font -and $existing.font.face) {
                    $targetFont = $existing.font.face
                    Write-Ok "Preserving configured profile font: ${cyn}$targetFont${rst}"
                } else {
                    $availableFonts = Get-AvailableNerdFonts
                    if ($availableFonts.Count -gt 0) {
                        $targetFont = $availableFonts[0]
                    } else {
                        $targetFont = "Cascadia Mono"
                    }
                }
            }

            $existing = $json.profiles.list | Where-Object { $_.name -eq $profileName }
            if ($existing) {
                $existing.commandline = $cmdline
                if (Test-Path -LiteralPath $installedLogo) {
                    $existing.icon = $installedLogo
                }
                if ($targetFont) {
                    if (-not $existing.font) {
                        $existing | Add-Member -MemberType NoteProperty -Name "font" -Value ([PSCustomObject]@{ face = $targetFont }) -Force
                    } else {
                        $existing.font.face = $targetFont
                    }
                }
                Write-Ok "Profile '$profileName' updated in Windows Terminal (Font: ${cyn}$targetFont${rst})"
                $targetGuid = $existing.guid
            } else {
                $newProfile = [ordered]@{
                    name             = $profileName
                    guid             = $profileGuid
                    commandline      = $cmdline
                    icon             = $iconPath
                    font             = [ordered]@{
                        face = $targetFont
                    }
                    startingDirectory= "%USERPROFILE%"
                    hidden           = $false
                }
                $json.profiles.list += [PSCustomObject]$newProfile
                Write-Ok "Profile '$profileName' added to Windows Terminal (Font: ${cyn}$targetFont${rst})"
                $targetGuid = $profileGuid
            }

            if (-not $Quiet) {
                $setDefault = Read-Host "  Set 'Warph Terminal' as default profile in Windows Terminal? [Y/n]"
                if ($setDefault -notmatch '^[nN]$') {
                    $json.defaultProfile = $targetGuid
                    Write-Ok "Set 'Warph Terminal' as default profile in Windows Terminal"
                }
            }

            $json | ConvertTo-Json -Depth 20 | Set-Content $wtSettings -Encoding UTF8
            Write-Ok "Windows Terminal settings saved"
        }
    }

    # Option 2: $PROFILE loader (portable dynamic path)
    if ($doSymlink) {
        $pDir = Split-Path $PROFILE
        if (-not (Test-Path -LiteralPath $pDir)) {
            New-Item -ItemType Directory -Force -Path $pDir | Out-Null
        }

        # Backup existing $PROFILE if it exists
        if (Test-Path -LiteralPath $PROFILE) {
            $pContent = Get-Content -LiteralPath $PROFILE -Raw
            $loaderTagStart = "# >>> Warph Terminal Loader >>>"
            $loaderTagEnd   = "# <<< Warph Terminal Loader <<<"
            $loaderBlock    = @(
                $loaderTagStart,
                "`$warphHome   = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.warph-terminal'",
                "`$warphScript = Join-Path `$warphHome 'Microsoft.PowerShell_profile.ps1'",
                "if (Test-Path -LiteralPath `$warphScript) { . `$warphScript }",
                $loaderTagEnd
            ) -join "`r`n"

            if ($pContent -like "*$loaderTagStart*") {
                # Replace existing loader block
                $regex = "(?s)$([regex]::Escape($loaderTagStart)).*?$([regex]::Escape($loaderTagEnd))"
                $newContent = [regex]::Replace($pContent, $regex, $loaderBlock)
                [System.IO.File]::WriteAllText($PROFILE, $newContent, [System.Text.Encoding]::UTF8)
                Write-Ok "Updated portable Warph Terminal loader in `$PROFILE"
            } else {
                # Append loader block preserving existing user settings
                $bak = "$PROFILE.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                Copy-Item -LiteralPath $PROFILE -Destination $bak
                Write-Ok "Backup of existing `$PROFILE -> $bak"
                $appended = $pContent.TrimEnd() + "`r`n`r`n" + $loaderBlock + "`r`n"
                [System.IO.File]::WriteAllText($PROFILE, $appended, [System.Text.Encoding]::UTF8)
                Write-Ok "Appended portable Warph Terminal loader to `$PROFILE"
            }
        } else {
            $loaderBlock = @(
                "# >>> Warph Terminal Loader >>>",
                "`$warphHome   = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.warph-terminal'",
                "`$warphScript = Join-Path `$warphHome 'Microsoft.PowerShell_profile.ps1'",
                "if (Test-Path -LiteralPath `$warphScript) { . `$warphScript }",
                "# <<< Warph Terminal Loader <<<`r`n"
            ) -join "`r`n"
            [System.IO.File]::WriteAllText($PROFILE, $loaderBlock, [System.Text.Encoding]::UTF8)
            Write-Ok "Created `$PROFILE with portable Warph Terminal loader"
        }
    } else {
        # Mode 1: Windows Terminal dedicated profile only. Ensure $PROFILE does not load Warph automatically
        if (Test-Path -LiteralPath $PROFILE) {
            $pContent = Get-Content -LiteralPath $PROFILE -Raw
            $loaderTagStart = "# >>> Warph Terminal Loader >>>"
            if ($pContent -like "*$loaderTagStart*") {
                $regex = "(?s)\r?\n?# >>> Warph Terminal Loader >>>.*?# <<< Warph Terminal Loader <<<\r?\n?"
                $cleaned = [regex]::Replace($pContent, $regex, "")
                [System.IO.File]::WriteAllText($PROFILE, $cleaned.TrimEnd() + "`r`n", [System.Text.Encoding]::UTF8)
                Write-Ok "Cleaned up `$PROFILE loader (Mode 1 keeps regular shell as default)"
            }
        }
    }

    # Step 4: Tools & Dependencies
    Write-Step 4 $TOTAL "Installing core dependencies & font"

    # oh-my-posh
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Write-Skip "oh-my-posh already installed"
    } else {
        Write-Info "Installing oh-my-posh via winget..."
        winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements --silent
        if ($LASTEXITCODE -eq 0) { Write-Ok "oh-my-posh installed" }
        else {
            Write-Info "Fallback to web installer..."
            try {
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
                Write-Ok "oh-my-posh installed"
            } catch {
                Write-Err "Failed: $_"
            }
        }
    }

    # font (OPTIONAL)
    $hasNerdFont = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts", "$env:WINDIR\Fonts" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "Nerd|Caskaydia" } | Select-Object -First 1

    if ($hasNerdFont) {
        Write-Skip "Nerd Font already detected: $($hasNerdFont.Name)"
    } else {
        $doInstallFont = $false
        if (-not $noOptional -and -not $Quiet) {
            $resp = Read-Host "  Install optional CaskaydiaCove Nerd Font (for extra glyphs)? [y/N]"
            $doInstallFont = ($resp -match '^[yYsS]$')
        }
        if ($doInstallFont) {
            Write-Info "Installing CaskaydiaCove Nerd Font..."
            $ompCmd = Get-Command oh-my-posh -ErrorAction SilentlyContinue
            if ($ompCmd) {
                try {
                    & oh-my-posh font install CascadiaCode --headless
                    Write-Ok "CaskaydiaCove Nerd Font installed"
                } catch {
                    Write-Err "Failed to install font: $_"
                }
            }
        } else {
            Write-Ok "Using default system font (Cascadia Mono). Font install skipped."
        }
    }

    # Ensure Windows Terminal / UWP AppContainer has read permission to user fonts (prevents 0xc0000094 crash)
    $userFonts = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    if (Test-Path -LiteralPath $userFonts) {
        icacls $userFonts /grant "*S-1-15-2-1:(OI)(CI)RX" /t | Out-Null
        Write-Ok "Font permissions verified for Windows Terminal AppContainer"
    }

    # zoxide, Terminal-Icons, yt-dlp, deno, ffmpeg
    Install-WingetPkg 'ajeetdsouza.zoxide' 'zoxide'
    Install-PSModule 'Terminal-Icons'
    Install-WingetPkg 'yt-dlp.yt-dlp' 'yt-dlp'
    Install-WingetPkg 'DenoLand.Deno' 'deno'
    Install-WingetPkg 'Gyan.FFmpeg' 'ffmpeg'

    # Optional CLI tools
    if (-not $noOptional) {
        Write-Host ""
        Write-Host "${ylw}${bold}[?]${rst} ${bold}Install optional CLI tools?${rst} ${dim}(eza, bat, fd, delta, dust, bottom, yazi...)${rst}"
        $resp = Read-Host "  Install? [s/N]"
        if ($resp -match '^[sSyY]$') {
            $rustScript = Join-Path $PSScriptRoot "install-rust-tools.ps1"
            if (Test-Path $rustScript) { & $rustScript }
        } else {
            Write-Skip "Optional tools skipped"
        }
    }

    Write-Host ""
    Write-Host "${grn}${bold}  ✓ Installation complete!${rst}"
    if ($doWT) {
        Write-Host "  Open ${cyn}Windows Terminal${rst} -> click ${bold}+${rst} -> ${cyn}Warph Terminal${rst}"
    }
    if ($doSymlink) {
        Write-Host "  Restart the terminal or run: ${cyn}. `$PROFILE${rst}"
    }
    Write-Host ""
}

function Invoke-RepairAction {
    Write-Host ""
    Write-Host "${cyn}${bold}  +--------------------------------------+"
    Write-Host "${cyn}${bold}  |       Warph Terminal - Repair        |"
    Write-Host "${cyn}${bold}  +--------------------------------------+"
    Write-Host "  Current Repo Path: ${dim}$repoRoot${rst}"
    Write-Host ""

    $repaired = $false

    # 1. Update installed files in ~/.warph-terminal
    Write-Host "  Updating installed files in $installDir..."
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    if (Test-Path -LiteralPath $profileSrc) {
        Copy-Item -LiteralPath $profileSrc -Destination $installedProfile -Force
        Write-Ok "Profile entrypoint updated in $installDir"
        $repaired = $true
    }
    if (Test-Path -LiteralPath $configSrc) {
        $targetCfgDir = Join-Path $installDir "config"
        New-Item -ItemType Directory -Force -Path $targetCfgDir | Out-Null
        Copy-Item -Path (Join-Path $configSrc "*") -Destination $targetCfgDir -Force
        Write-Ok "Config refreshed in $targetCfgDir"
        $repaired = $true
    }
    if (Test-Path -LiteralPath $modulesSrc) {
        $targetModDir = Join-Path $installDir "modules"
        New-Item -ItemType Directory -Force -Path $targetModDir | Out-Null
        Copy-Item -Path (Join-Path $modulesSrc "*") -Destination $targetModDir -Force
        Write-Ok "Modules refreshed in $targetModDir"
        $repaired = $true
    }
    if (Test-Path -LiteralPath $themeSrc) {
        $targetThemeDir = Join-Path $installDir "themes"
        New-Item -ItemType Directory -Force -Path $targetThemeDir | Out-Null
        Copy-Item -LiteralPath $themeSrc -Destination (Join-Path $targetThemeDir "cobalt2.omp.json") -Force
        Copy-Item -LiteralPath $themeSrc -Destination $installedTheme -Force
        Copy-Item -LiteralPath $themeSrc -Destination $themeDest -Force
        Write-Ok "Theme updated in $installDir and `$PROFILE dir"
        $repaired = $true
    }
    if (Test-Path -LiteralPath $assetsSrc) {
        $targetAssetDir = Join-Path $installDir "assets"
        New-Item -ItemType Directory -Force -Path $targetAssetDir | Out-Null
        Copy-Item -Path (Join-Path $assetsSrc "*") -Destination $targetAssetDir -Force
        Write-Ok "Assets refreshed in $targetAssetDir"
        $repaired = $true
    }

    # 2. Repair Windows Terminal settings
    $wtSettings = Get-WTSettingsPath
    if ($wtSettings -and (Test-Path $wtSettings)) {
        Write-Host "  Checking Windows Terminal settings..."
        $json = Get-Content $wtSettings -Raw | ConvertFrom-Json
        $wtProfile = $json.profiles.list | Where-Object { $_.name -eq "Warph Terminal" }

        if ($wtProfile) {
            $expectedCmd = "pwsh.exe -NoExit -ExecutionPolicy Bypass -File `"$installedProfile`""
            $needsSave = $false
            if ($wtProfile.commandline -ne $expectedCmd) {
                Write-Info "Updating Windows Terminal commandline:"
                Write-Host "    Old: ${red}$($wtProfile.commandline)${rst}"
                Write-Host "    New: ${grn}$expectedCmd${rst}"
                $wtProfile.commandline = $expectedCmd
                $needsSave = $true
            }
            if (Test-Path -LiteralPath $installedLogo) {
                if ($wtProfile.icon -ne $installedLogo) {
                    $wtProfile.icon = $installedLogo
                    $needsSave = $true
                }
            }
            if ($wtProfile.font -and $wtProfile.font.face) {
                Write-Ok "Preserved profile font: $($wtProfile.font.face)"
            }
            if ($needsSave) {
                $json | ConvertTo-Json -Depth 20 | Set-Content $wtSettings -Encoding UTF8
                Write-Ok "Windows Terminal profile repaired"
                $repaired = $true
            } else {
                Write-Ok "Windows Terminal profile already up to date"
            }
        } else {
            Write-Skip "Warph Terminal profile not found in Windows Terminal list"
        }
    }

    # 3. Repair $PROFILE loader
    Write-Host "  Checking `$PROFILE loader..."
    if (Test-Path -LiteralPath $PROFILE) {
        $pContent = Get-Content -LiteralPath $PROFILE -Raw
        $loaderTagStart = "# >>> Warph Terminal Loader >>>"
        $loaderTagEnd   = "# <<< Warph Terminal Loader <<<"
        $loaderBlock    = @(
            $loaderTagStart,
            "`$warphHome   = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.warph-terminal'",
            "`$warphScript = Join-Path `$warphHome 'Microsoft.PowerShell_profile.ps1'",
            "if (Test-Path -LiteralPath `$warphScript) { . `$warphScript }",
            $loaderTagEnd
        ) -join "`r`n"

        if ($pContent -like "*$loaderTagStart*") {
            if ($pContent -notlike "*`$warphHome   = Join-Path*") {
                Write-Info "Updating Warph Terminal loader in `$PROFILE to portable dynamic path..."
                $regex = "(?s)$([regex]::Escape($loaderTagStart)).*?$([regex]::Escape($loaderTagEnd))"
                $updated = [regex]::Replace($pContent, $regex, $loaderBlock)
                [System.IO.File]::WriteAllText($PROFILE, $updated, [System.Text.Encoding]::UTF8)
                Write-Ok "`$PROFILE loader repaired to portable path"
                $repaired = $true
            } else {
                Write-Ok "`$PROFILE loader already uses portable path"
            }
        } else {
            Write-Skip "`$PROFILE exists without Warph loader"
        }
    } else {
        Write-Skip "`$PROFILE does not exist"
    }

    # 4. Repair Font Permissions (prevents Windows Terminal 0xc0000094 crash)
    Write-Host "  Checking user font permissions for Windows Terminal..."
    $userFonts = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    if (Test-Path -LiteralPath $userFonts) {
        icacls $userFonts /grant "*S-1-15-2-1:(OI)(CI)RX" /t | Out-Null
        Write-Ok "User font permissions verified (AppContainer access granted)"
        $repaired = $true
    }

    Write-Host ""
    if ($repaired) {
        Write-Host "${grn}${bold}  [OK] Repair completed successfully!${rst}"
    } else {
        Write-Host "${grn}${bold}  [OK] All paths and permissions are already up to date!${rst}"
    }
    Write-Host ""
}

function Invoke-UninstallAction ($isForce) {
    Write-Host ""
    Write-Host "${red}${bold}  +--------------------------------------+"
    Write-Host "${red}${bold}  |     Warph Terminal - Uninstall       |"
    Write-Host "${red}${bold}  +--------------------------------------+"
    Write-Host ""

    if (-not $isForce) {
        Write-Host "  This will:"
        Write-Host "   - Remove 'Warph Terminal' from Windows Terminal settings"
        Write-Host "   - Remove the loader block from your `$PROFILE (preserving other personal settings)"
        Write-Host "   - Delete installed files in $installDir"
        Write-Host ""
        $confirm = Read-Host "  Are you sure you want to uninstall Warph Terminal? [y/N]"
        if ($confirm -notmatch '^[yYsS]$') {
            Write-Host "  Uninstall cancelled." -ForegroundColor Yellow
            return
        }
    }

    # 1. Remove Windows Terminal profile
    $wtSettings = Get-WTSettingsPath
    if ($wtSettings -and (Test-Path $wtSettings)) {
        Write-Host "  Removing profile from Windows Terminal..."
        $json = Get-Content $wtSettings -Raw | ConvertFrom-Json
        $countBefore = $json.profiles.list.Count
        $warphProfile = $json.profiles.list | Where-Object { $_.name -eq "Warph Terminal" }
        $json.profiles.list = @($json.profiles.list | Where-Object { $_.name -ne "Warph Terminal" })
        if ($json.profiles.list.Count -lt $countBefore) {
            # Reset defaultProfile if it pointed to Warph Terminal
            if ($warphProfile -and $json.defaultProfile -eq $warphProfile.guid) {
                $ps7 = $json.profiles.list | Where-Object { $_.name -eq "PowerShell 7" }
                if ($ps7) { $json.defaultProfile = $ps7.guid }
                elseif ($json.profiles.list.Count -gt 0) { $json.defaultProfile = $json.profiles.list[0].guid }
                Write-Ok "Reset Windows Terminal default profile"
            }
            $json | ConvertTo-Json -Depth 20 | Set-Content $wtSettings -Encoding UTF8
            Write-Ok "Removed 'Warph Terminal' from Windows Terminal"
        } else {
            Write-Skip "'Warph Terminal' was not found in Windows Terminal"
        }
    }

    # 2. Remove / Restore $PROFILE
    Write-Host "  Cleaning up `$PROFILE..."
    if (Test-Path -LiteralPath $PROFILE) {
        $pContent = Get-Content -LiteralPath $PROFILE -Raw
        $loaderTagStart = "# >>> Warph Terminal Loader >>>"
        if ($pContent -like "*$loaderTagStart*") {
            $regex = "(?s)\r?\n?# >>> Warph Terminal Loader >>>.*?# <<< Warph Terminal Loader <<<\r?\n?"
            $cleaned = [regex]::Replace($pContent, $regex, "")
            [System.IO.File]::WriteAllText($PROFILE, $cleaned.TrimEnd() + "`r`n", [System.Text.Encoding]::UTF8)
            Write-Ok "Removed Warph Terminal loader from `$PROFILE (preserved other settings)"
        } else {
            Write-Skip "No Warph Terminal loader found in `$PROFILE"
        }
    } else {
        Write-Skip "`$PROFILE not found"
    }

    # 3. Remove ~/.warph-terminal installation directory
    if (Test-Path -LiteralPath $installDir) {
        Remove-Item -LiteralPath $installDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Ok "Removed $installDir"
    }

    # 4. Clean copied theme in $profileDir
    if (Test-Path -LiteralPath $themeDest) {
        Remove-Item -LiteralPath $themeDest -Force -ErrorAction SilentlyContinue
        Write-Ok "Removed copied cobalt2.omp.json"
    }

    Write-Host ""
    Write-Host "${grn}${bold}  [OK] Warph Terminal has been cleanly uninstalled.${rst}"
    Write-Host "  ${dim}(Installed CLI packages like eza/bat/ffmpeg remain on your system.)${rst}"
    Write-Host ""
}

function Invoke-AuditAction {
    $testsRunner = Join-Path $repoRoot "tests\run-tests.ps1"
    $auditScript = Join-Path $repoRoot "scripts\audit-profile.ps1"
    if (-not (Test-Path $auditScript)) {
        $auditScript = Join-Path $repoRoot ".agents\skills\pwsh-profile-auditor\scripts\audit-profile.ps1"
    }
    if (Test-Path $testsRunner) {
        & pwsh -NoProfile -File $testsRunner -Benchmark
    } elseif (Test-Path $auditScript) {
        & pwsh -NoProfile -File $auditScript -Benchmark
    } else {
        Write-Err "Neither test runner nor auditor script found."
    }
}

# ─────────────────────────────────────────────────────────────
# Dispatcher
# ─────────────────────────────────────────────────────────────
if ($Install) {
    Invoke-InstallAction -selectedMode $Mode -noOptional $SkipOptional -customFont $Font
} elseif ($SetFont) {
    Set-TerminalFont -FontName $Font
} elseif ($Repair) {
    Invoke-RepairAction
} elseif ($Uninstall) {
    Invoke-UninstallAction -isForce $Force
} elseif ($Audit) {
    Invoke-AuditAction
} elseif ($CheckPrereqs) {
    Test-Prerequisites
} elseif ($InstallPrereqs) {
    Test-Prerequisites -AutoInstall
} else {
    # Interactive Menu
    Write-Host ""
    Write-Host "${cyn}${bold}  +--------------------------------------+"
    Write-Host "${cyn}${bold}  |         Warph Terminal               |"
    Write-Host "${cyn}${bold}  |      Interactive Setup & Manager     |"
    Write-Host "${cyn}${bold}  +--------------------------------------+"
    Write-Host ""
    Write-Host "  ${bold}[1]${rst} ${grn}Install / Update${rst}       ${dim}(Setup theme, profiles, font & tools)${rst}"
    Write-Host "  ${bold}[2]${rst} ${cyn}Check Prerequisites${rst}    ${dim}(Verify & install Windows Terminal, fonts, pwsh)${rst}"
    Write-Host "  ${bold}[3]${rst} ${cyn}Customize Font${rst}         ${dim}(Choose or switch Windows Terminal Nerd Font)${rst}"
    Write-Host "  ${bold}[4]${rst} ${cyn}Repair Paths${rst}           ${dim}(Fix paths after moving the repository folder)${rst}"
    Write-Host "  ${bold}[5]${rst} ${red}Uninstall${rst}              ${dim}(Cleanly remove WT profile & restore `$PROFILE)${rst}"
    Write-Host "  ${bold}[6]${rst} ${ylw}Audit & Benchmark${rst}      ${dim}(Verify AST, 3-way sync & load latency)${rst}"
    Write-Host "  ${bold}[7]${rst} Exit"
    Write-Host ""

    $choice = ''
    while ($choice -notin '1','2','3','4','5','6','7') {
        $choice = Read-Host "  Select an option [1-7]"
    }

    switch ($choice) {
        '1' { Invoke-InstallAction -selectedMode $null -noOptional $false -customFont $null }
        '2' { Test-Prerequisites }
        '3' { Set-TerminalFont }
        '4' { Invoke-RepairAction }
        '5' { Invoke-UninstallAction -isForce $false }
        '6' { Invoke-AuditAction }
        '7' { Write-Host "  Exiting."; exit 0 }
    }
}

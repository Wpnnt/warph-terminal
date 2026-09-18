# Warph Terminal - Image to ASCII / Terminal Art Test Utility
# Usage:
#   .\scripts\test-image-ascii.ps1 -Mode Ultra -Color FullColor -Width 80 -Height 24
#   .\scripts\test-image-ascii.ps1 -Mode Geometric -Color FullColor -Width 80 -Height 24
#   .\scripts\test-image-ascii.ps1 -Mode Hybrid -Color FullColor -Width 80 -Height 24
#   .\scripts\test-image-ascii.ps1 -Mode All

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Path,

    [Parameter()]
    [ValidateSet("HalfBlock", "Complex", "Braille", "Ascii", "Quad", "Ultra", "All")]
    [string]$Mode = "HalfBlock",

    [Parameter()]
    [int]$Width = 80,

    [Parameter()]
    [int]$Height = 24,

    [Parameter()]
    [ValidateSet("FullColor", "Monochrome", "256", "None")]
    [string]$Color = "FullColor",

    [Parameter()]
    [ValidateSet("none", "diffusion", "ordered", "noise")]
    [string]$Dither = "none",

    [Parameter()]
    [ValidateSet("din99d", "rgb")]
    [string]$ColorSpace = "din99d",

    [Parameter()]
    [ValidateRange(1, 9)]
    [int]$Work = 9,

    [Parameter()]
    [ValidateRange(1, 13)]
    [int]$Variant,

    [Parameter()]
    [Alias("Transparent", "NoBg")]
    [switch]$NoBackground,

    [Parameter()]
    [switch]$Invert
)

$ErrorActionPreference = "Stop"

# Resolve target image path
$scriptRoot = $PSScriptRoot
$repoRoot = if ($scriptRoot) { Split-Path $scriptRoot -Parent } else { Get-Location }

if ($Variant) {
    $variantMap = @{
        1  = "assets\variants\v1-titanium-sharp.png"
        2  = "assets\variants\v2-cosmic-cyan.png"
        3  = "assets\variants\v3-eclipse-corona.png"
        4  = "assets\variants\v4-obsidian-steel.png"
        5  = "assets\variants\v5-cyber-indigo.png"
        6  = "assets\variants\v6-stellar-dust.png"
        7  = "assets\variants\v1a-titanium-smooth.png"
        8  = "assets\variants\v1b-titanium-complex.png"
        9  = "assets\variants\v1c-titanium-corona.png"
        10 = "assets\variants\v1d-cyber-titanium.png"
        11 = "assets\variants\v8a-cyan-mist.png"
        12 = "assets\variants\v8b-hyper-contrast.png"
        13 = "assets\variants\v8c-corona-3d.png"
    }
    $Path = Join-Path $repoRoot $variantMap[$Variant]
    if (-not $PSBoundParameters.ContainsKey("Width")) {
        $Width = if ($Variant -ge 7) { 120 } else { 100 }
    }
    if (-not $PSBoundParameters.ContainsKey("Height")) {
        $Height = if ($Variant -ge 7) { 36 } else { 30 }
    }
} elseif (-not $Path) {
    $primaryChoice = if ($NoBackground) { "assets\logo-nobg.png" } else { "assets\logo.png" }
    $candidates = @(
        (Join-Path $repoRoot $primaryChoice),
        (Join-Path $repoRoot "assets\logo-nobg.png"),
        (Join-Path $repoRoot "assets\logo.png"),
        (Join-Path $repoRoot "assets\logo-transparent.png"),
        (Join-Path $repoRoot "assets\logo.svg")
    )
    foreach ($cand in $candidates) {
        if (Test-Path -LiteralPath $cand) {
            $Path = $cand
            break
        }
    }
} elseif ($NoBackground -and (Split-Path $Path -Leaf) -eq "logo.png") {
    $noBgAlt = Join-Path (Split-Path $Path -Parent) "logo-nobg.png"
    if (Test-Path -LiteralPath $noBgAlt) {
        $Path = $noBgAlt
    }
}

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Error "Image file not found: $Path"
    return
}

$resolvedPath = (Resolve-Path -LiteralPath $Path).Path

# Locate Chafa executable
$chafaExe = Get-Command "chafa" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
if (-not $chafaExe) {
    $wingetChafa = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "Microsoft\WinGet\Links\chafa.exe"
    if (Test-Path -LiteralPath $wingetChafa) {
        $chafaExe = $wingetChafa
    }
}

# Terminal styles
$rst = $PSStyle.Reset
$bold = $PSStyle.Bold
$dim = $PSStyle.Dim
$w0 = $PSStyle.Foreground.FromRgb(255, 255, 255)
$w1 = $PSStyle.Foreground.FromRgb(200, 200, 200)
$w2 = $PSStyle.Foreground.FromRgb(150, 150, 150)
$w3 = $PSStyle.Foreground.FromRgb(95,  95,  95)
$w4 = $PSStyle.Foreground.FromRgb(55,  55,  55)
$w5 = $PSStyle.Foreground.FromRgb(30,  30,  30)

function Invoke-ChafaRender {
    param(
        [string]$SymbolType,
        [string]$ColorMode,
        [int]$Cols,
        [int]$Rows,
        [string]$ImgPath,
        [string]$DitherMode,
        [string]$SpaceMode,
        [int]$WorkLevel,
        [switch]$InvertColors
    )

    $argsList = [System.Collections.Generic.List[string]]::new()
    $argsList.Add("--symbols")
    $argsList.Add($SymbolType)
    $argsList.Add("--size")
    $argsList.Add("${Cols}x${Rows}")
    $argsList.Add("--work")
    $argsList.Add($WorkLevel.ToString())
    $argsList.Add("--color-space")
    $argsList.Add($SpaceMode)

    if ($DitherMode -ne "none") {
        $argsList.Add("--dither")
        $argsList.Add($DitherMode)
    }

    switch ($ColorMode) {
        "FullColor"  { $argsList.Add("-c"); $argsList.Add("full") }
        "256"        { $argsList.Add("-c"); $argsList.Add("256") }
        "Monochrome" { $argsList.Add("-c"); $argsList.Add("240"); $argsList.Add("--fg-only") }
        "None"       { $argsList.Add("--colors"); $argsList.Add("none") }
    }

    if ($InvertColors) {
        $argsList.Add("--invert")
    }

    $argsList.Add($ImgPath)

    & $chafaExe @argsList
}

function Invoke-NativeAsciiFallback {
    param(
        [string]$ImgPath,
        [int]$Cols,
        [int]$Rows,
        [switch]$InvertColors
    )

    $ramp = " .:-=+*#%@"
    if ($InvertColors) {
        $ramp = "@%#*+=-:. "
    }

    Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
    $bmp = [System.Drawing.Bitmap]::FromFile($ImgPath)
    try {
        $resized = [System.Drawing.Bitmap]::new($bmp, [System.Drawing.Size]::new($Cols, $Rows))
        try {
            for ($y = 0; $y -lt $Rows; $y++) {
                $lineChars = [System.Text.StringBuilder]::new()
                for ($x = 0; $x -lt $Cols; $x++) {
                    $pixel = $resized.GetPixel($x, $y)
                    $brightness = $pixel.GetBrightness()
                    $idx = [Math]::Floor($brightness * ($ramp.Length - 1))
                    if ($idx -ge $ramp.Length) { $idx = $ramp.Length - 1 }
                    if ($idx -lt 0) { $idx = 0 }
                    [void]$lineChars.Append($ramp[$idx])
                }
                Write-Host $lineChars.ToString()
            }
        } finally {
            $resized.Dispose()
        }
    } finally {
        $bmp.Dispose()
    }
}

function Render-Mode {
    param(
        [string]$TargetMode
    )

    $symbolMap = @{
        "HalfBlock"  = "vhalf"
        "Complex"    = "half+block+quad+braille+border"
        "Braille"    = "braille"
        "Ascii"      = "ascii"
        "Quad"       = "half+block+quad"
        "Ultra"      = "all-wide"
    }

    $title = switch ($TargetMode) {
        "HalfBlock"  { "Dual-Pixel Half-Block (100% Font-Safe 1x2 Subpixels)" }
        "Complex"    { "Complex Safe (Half-Block + Quadrants + Braille + Border - Zero Sextants)" }
        "Braille"    { "High-Density Braille (2x4 Subpixels)" }
        "Ascii"      { "Classic ASCII Density Ramp" }
        "Quad"       { "Quadrant + Half-Block Solid Geometry" }
        "Ultra"      { "Ultra High-Fidelity (Requires Full Unicode 13 Font Support)" }
    }

    $chosenSymbols = if ($CustomSymbols) { $CustomSymbols } else { $symbolMap[$TargetMode] }

    Write-Host "${dim}------------------------------------------------------------${rst}"
    Write-Host "  ${w0}${bold}MODE: $title${rst}"
    Write-Host "  ${dim}Size: ${Width}x${Height} | Color: $Color | Dither: $Dither | Precision: Work $Work | Space: $ColorSpace${rst}"
    Write-Host "${dim}------------------------------------------------------------${rst}"

    if ($chafaExe) {
        Invoke-ChafaRender `
            -SymbolType $chosenSymbols `
            -ColorMode $Color `
            -Cols $Width `
            -Rows $Height `
            -ImgPath $resolvedPath `
            -DitherMode $Dither `
            -SpaceMode $ColorSpace `
            -WorkLevel $Work `
            -InvertColors:$Invert
    } else {
        if ($TargetMode -eq "Ascii") {
            Invoke-NativeAsciiFallback -ImgPath $resolvedPath -Cols $Width -Rows $Height -InvertColors:$Invert
        } else {
            Write-Warning "Chafa CLI is not installed. To render $TargetMode, install Chafa via 'winget install chafa'."
            Invoke-NativeAsciiFallback -ImgPath $resolvedPath -Cols $Width -Rows $Height -InvertColors:$Invert
        }
    }
    Write-Host ""
}

# Banner Header
Write-Host ""
Write-Host "  ${w0}${bold}WARPH TERMINAL - IMAGE TO ASCII TESTER (PRO EDITION)${rst}"
Write-Host "  ${dim}Source: $resolvedPath${rst}"
Write-Host ""

if ($Mode -eq "All") {
    @("HalfBlock", "Complex", "Quad", "Braille", "Ascii") | ForEach-Object {
        Render-Mode -TargetMode $_
    }
} else {
    Render-Mode -TargetMode $Mode
}

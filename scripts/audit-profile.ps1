# audit-profile.ps1 — Warph Terminal Profile Auditor
# Usage: pwsh -NoProfile -File audit-profile.ps1 [-Benchmark]

param(
    [string]$ProfilePath = "",
    [string]$ReadmePath  = "",
    [switch]$Benchmark
)

$repoRoot = $PSScriptRoot
while ($repoRoot -and -not (Test-Path (Join-Path $repoRoot "src\Microsoft.PowerShell_profile.ps1")) -and -not (Test-Path (Join-Path $repoRoot ".git"))) {
    $parent = Split-Path $repoRoot -Parent
    if ($parent -eq $repoRoot) { break }
    $repoRoot = $parent
}

if (-not $ProfilePath) {
    $srcCandidate = Join-Path $repoRoot "src\Microsoft.PowerShell_profile.ps1"
    if (Test-Path -LiteralPath $srcCandidate) {
        $ProfilePath = $srcCandidate
    } else {
        $ProfilePath = Join-Path $repoRoot "Microsoft.PowerShell_profile.ps1"
    }
}
if (-not $ReadmePath) { $ReadmePath = Join-Path $repoRoot "README.md" }

$ProfilePath = [System.IO.Path]::GetFullPath($ProfilePath)
$ReadmePath  = [System.IO.Path]::GetFullPath($ReadmePath)

$grn = $PSStyle.Foreground.BrightGreen
$red = $PSStyle.Foreground.BrightRed
$ylw = $PSStyle.Foreground.BrightYellow
$cyn = $PSStyle.Foreground.BrightCyan
$dim = $PSStyle.Foreground.BrightBlack
$rst = $PSStyle.Reset
$bld = $PSStyle.Bold

Write-Host ""
Write-Host "${cyn}${bld}Warph Terminal - Profile Auditor${rst}"
Write-Host "${dim}----------------------------------------------------${rst}"

$hasErrors = $false

# Gather all target script files (profile entrypoint + config + modular components)
$filesToCheck = @($ProfilePath)
$srcDir = Split-Path $ProfilePath -Parent
$configDir = Join-Path $srcDir "config"
if (Test-Path -LiteralPath $configDir) {
    $configFiles = [System.IO.Directory]::GetFiles($configDir, "*.ps1")
    $filesToCheck += $configFiles
}
$modulesDir = Join-Path $srcDir "modules"
if (Test-Path -LiteralPath $modulesDir) {
    $moduleFiles = [System.IO.Directory]::GetFiles($modulesDir, "*.ps1")
    $filesToCheck += $moduleFiles
}

# 1. AST Syntax Check
Write-Host "  ${dim}[1/4]${rst} Checking PowerShell AST syntax across $($filesToCheck.Count) files..." -NoNewline
$allAsts = @()
$totalLines = 0
$syntaxFailed = $false

foreach ($file in $filesToCheck) {
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$parseErrors)
    $allAsts += $ast
    $totalLines += $ast.Extent.EndLineNumber

    if ($parseErrors -and $parseErrors.Count -gt 0) {
        if (-not $syntaxFailed) {
            Write-Host " ${red}FAIL${rst}"
            $syntaxFailed = $true
            $hasErrors = $true
        }
        foreach ($err in $parseErrors) {
            Write-Host "    ${red}[FAIL] [$(Split-Path $file -Leaf):$($err.Extent.StartLineNumber)] $($err.Message)${rst}"
        }
    }
}

if (-not $syntaxFailed) {
    Write-Host " ${grn}[OK] Valid AST ($totalLines total lines across $($filesToCheck.Count) files)${rst}"
}

# 2. Extract defined functions
$userFunctions = @()
$internalFunctions = @()
$showHelpText = ""

foreach ($ast in $allAsts) {
    $funcAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    foreach ($f in $funcAsts) {
        $fnName = $f.Name
        if ($fnName -eq 'Show-Help') {
            $showHelpText = $f.Extent.Text
            $internalFunctions += $fnName
        } elseif ($fnName -like '_*') {
            $internalFunctions += $fnName
        } else {
            $userFunctions += $fnName
        }
    }
}
$userFunctions = @($userFunctions | Sort-Object -Unique)

Write-Host "  ${dim}[2/4]${rst} Found $($userFunctions.Count) user functions, $($internalFunctions.Count) internal/help functions."

# 3. 3-Way Sync Check (Profile <-> Show-Help <-> README)
Write-Host "  ${dim}[3/4]${rst} Verifying 3-Way Sync (Modules ↔ Show-Help ↔ README)..."

$readmeContent = if (Test-Path $ReadmePath) { Get-Content -Path $ReadmePath -Raw } else { "" }

$missingHelp = @()
$missingReadme = @()

foreach ($fn in $userFunctions) {
    if ($showHelpText -and ($showHelpText -notmatch "\b$([regex]::Escape($fn))\b")) {
        $missingHelp += $fn
    }
    if ($readmeContent -and ($readmeContent -notmatch "\b$([regex]::Escape($fn))\b")) {
        $missingReadme += $fn
    }
}

if ($missingHelp.Count -gt 0) {
    Write-Host "    ${ylw}[WARN] Functions missing in Show-Help:${rst} $($missingHelp -join ', ')"
} else {
    Write-Host "    ${grn}[OK] All user functions present in Show-Help${rst}"
}

if ($missingReadme.Count -gt 0) {
    Write-Host "    ${ylw}[WARN] Functions missing in README.md:${rst} $($missingReadme -join ', ')"
} else {
    Write-Host "    ${grn}[OK] All user functions present in README.md${rst}"
}

# 4. Code portability & standards check
Write-Host "  ${dim}[4/4]${rst} Checking code portability & charset standards..."

$emojiPattern = '[\uD83C-\uD83E][\uDC00-\uDFFF]|[\u2600-\u2712\u2715-\u27BF]'
$linesWithEmoji = @()

foreach ($file in $filesToCheck) {
    $lineNum = 1
    foreach ($line in (Get-Content -Path $file)) {
        if ($line -match $emojiPattern) {
            $linesWithEmoji += "[$(Split-Path $file -Leaf):$lineNum] $line"
        }
        $lineNum++
    }
}

if ($linesWithEmoji.Count -gt 0) {
    Write-Host "    ${ylw}[WARN] Non-standard unicode glyphs found in files:${rst}"
    foreach ($e in $linesWithEmoji) {
        Write-Host "      $e"
    }
} else {
    Write-Host "    ${grn}[OK] Clean terminal charset (ANSI & Nerd Font compatible)${rst}"
}

# Hardcoded paths check
$userPatterns = @('C:\\Users\\[a-zA-Z0-9_-]+', '[A-Z]:\\vault_dev')
$hardcodedMatches = @()
foreach ($file in $filesToCheck) {
    $content = Get-Content -Path $file -Raw
    foreach ($pat in $userPatterns) {
        if ($content -match $pat) {
            $hardcodedMatches += "[$(Split-Path $file -Leaf)] Matches $pat"
        }
    }
}

if ($hardcodedMatches.Count -gt 0) {
    Write-Host "    ${red}[FAIL] Absolute local machine paths found:${rst} $($hardcodedMatches -join '; ')"
    $hasErrors = $true
} else {
    Write-Host "    ${grn}[OK] Portable paths (dynamic resolution)${rst}"
}

# 5. Benchmark (Optional)
if ($Benchmark) {
    Write-Host ""
    Write-Host "  ${cyn}Benchmarking profile load latency...${rst}"
    $latencies = @()
    for ($i = 1; $i -le 3; $i++) {
        $ms = (Measure-Command {
            pwsh -NoProfile -Command ". '$ProfilePath'"
        }).TotalMilliseconds
        $latencies += $ms
    }
    $avgMs = [math]::Round(($latencies | Measure-Object -Average).Average, 1)
    Write-Host "  Load time: ${grn}$avgMs ms${rst}"
}

Write-Host "${dim}----------------------------------------------------${rst}"
if ($hasErrors) {
    Write-Host "${red}${bld}Auditing completed with errors!${rst}"
    exit 1
} else {
    Write-Host "${grn}${bld}Auditing completed successfully!${rst}"
    exit 0
}

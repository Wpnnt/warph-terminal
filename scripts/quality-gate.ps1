# quality-gate.ps1 — Pre-Commit Code Quality Gate for Warph Terminal
# Usage:
#   pwsh -NoProfile -File scripts/quality-gate.ps1           # Runs on staged Git files
#   pwsh -NoProfile -File scripts/quality-gate.ps1 -All      # Runs across entire repository

#Requires -Version 7

[CmdletBinding()]
param(
    [switch]$All
)

$grn = $PSStyle.Foreground.BrightGreen
$red = $PSStyle.Foreground.BrightRed
$ylw = $PSStyle.Foreground.BrightYellow
$cyn = $PSStyle.Foreground.BrightCyan
$dim = $PSStyle.Foreground.BrightBlack
$rst = $PSStyle.Reset
$bld = $PSStyle.Bold

$repoRoot = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "${cyn}${bld}  +----------------------------------------------+${rst}"
Write-Host "${cyn}${bld}  |       Warph Terminal - Code Quality Gate     |${rst}"
Write-Host "${cyn}${bld}  +----------------------------------------------+${rst}"
Write-Host ""

$failed = $false

# 1. Identify files to inspect
$filesToCheck = @()

if ($All) {
    Write-Host "  ${dim}[MODE]${rst} Scanning entire repository..."
    $filesToCheck = Get-ChildItem -Path $repoRoot -Recurse -File |
        Where-Object { $_.FullName -notmatch '\\\.git\\|\\\.ag-kit-backups\\|\\\.agents\\|\\docs\\|\\node_modules\\' -and $_.Extension -in '.ps1', '.psm1', '.psd1', '.md', '.json' } |
        Select-Object -ExpandProperty FullName
} else {
    $stagedOutput = git diff --cached --name-only --diff-filter=ACM
    if ($stagedOutput) {
        $stagedRel = @($stagedOutput | Where-Object { $_ })
        foreach ($rel in $stagedRel) {
            $abs = Join-Path $repoRoot $rel
            if (Test-Path -LiteralPath $abs) {
                $filesToCheck += $abs
            }
        }
    }
    if ($filesToCheck.Count -eq 0) {
        Write-Host "  ${dim}[INFO]${rst} No staged files to verify. Scanning active source files..."
        $filesToCheck = Get-ChildItem -Path (Join-Path $repoRoot "src") -Recurse -Filter "*.ps1" | Select-Object -ExpandProperty FullName
    }
}

Write-Host "  ${dim}[1/4]${rst} Verifying $($filesToCheck.Count) files..."

# 2. Check 1: AST Syntax Validation on PowerShell files
$psFiles = $filesToCheck | Where-Object { $_ -match '\.(ps1|psm1|psd1)$' }
if ($psFiles) {
    Write-Host "  ${dim}[2/4]${rst} Verifying PowerShell AST syntax..." -NoNewline
    $astErrors = @()
    foreach ($f in $psFiles) {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$errors) | Out-Null
        if ($errors) {
            foreach ($e in $errors) {
                $astErrors += "[$(Split-Path $f -Leaf):$($e.Extent.StartLineNumber)] $($e.Message)"
            }
        }
    }
    if ($astErrors.Count -gt 0) {
        Write-Host " ${red}[FAIL]${rst}"
        foreach ($err in $astErrors) {
            Write-Host "    ${red}[AST ERROR] $err${rst}"
        }
        $failed = $true
    } else {
        Write-Host " ${grn}[OK] Valid syntax${rst}"
    }
} else {
    Write-Host "  ${dim}[2/4]${rst} ${dim}No PowerShell files to parse.${rst}"
}

# 3. Check 2: Terminal Charset Compatibility (Standard ASCII / Nerd Font / ANSI Only)
Write-Host "  ${dim}[3/4]${rst} Checking terminal charset compatibility..." -NoNewline
$unsupportedCharsetPattern = '[\uD83C-\uD83E][\uDC00-\uDFFF]|[\u2600-\u2712\u2715-\u27BF]|[\u2300-\u23FF]|[\u2B50\u2B55]'
$charsetViolations = @()

foreach ($f in $filesToCheck) {
    if ($f -match '\.(svg|png|ico|jpg|webp)$') { continue }

    $lines = Get-Content -LiteralPath $f -ErrorAction SilentlyContinue
    if (-not $lines) { continue }
    $lineNum = 1
    foreach ($line in $lines) {
        if ($line -match $unsupportedCharsetPattern) {
            $rel = $f.Replace($repoRoot, '').TrimStart('\/')
            $charsetViolations += "[${rel}:${lineNum}] $line"
        }
        $lineNum++
    }
}

if ($charsetViolations.Count -gt 0) {
    Write-Host " ${red}[FAIL]${rst}"
    Write-Host "    ${red}Found unsupported unicode glyphs (clean ASCII or Nerd Font required):${rst}"
    foreach ($v in ($charsetViolations | Select-Object -First 10)) {
        Write-Host "      $dim$v$rst"
    }
    if ($charsetViolations.Count -gt 10) {
        Write-Host "      $dim... and $($charsetViolations.Count - 10) more violations.$rst"
    }
    $failed = $true
} else {
    Write-Host " ${grn}[OK] Clean charset${rst}"
}

# 4. Check 3: Portability & Code Standards (No Hardcoded Personal Paths or Formulaic Boilerplate)
Write-Host "  ${dim}[4/4]${rst} Verifying portability and code comments..." -NoNewline
$pathPattern = '([a-zA-Z]:\\Users\\[a-zA-Z0-9_-]+|[a-zA-Z]:\\vault_dev|/home/[a-zA-Z0-9_-]+)'
$boilerplatePattern = '(?i)(here is the updated|i hope this helps|this function is responsible for|sure, here is|in this step, we|let me know if you have any questions|delve into|seamless integration|pivotal role|groundbreaking|nestled in|rich tapestry)'
$contentViolations = @()

foreach ($f in $filesToCheck) {
    if ($f -match '\.(svg|png|ico|jpg|webp)$' -or $f -eq $PSCommandPath) { continue }

    $content = Get-Content -LiteralPath $f -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $rel = $f.Replace($repoRoot, '').TrimStart('\/')

    # Path check
    if ($content -match $pathPattern) {
        $contentViolations += "[$rel] Absolute path: $($Matches[1])"
    }

    # Boilerplate / formulaic phrasing check
    if ($content -match $boilerplatePattern) {
        $contentViolations += "[$rel] Formulaic / boilerplate phrasing: '$($Matches[1])'"
    }
}

if ($contentViolations.Count -gt 0) {
    Write-Host " ${red}[FAIL]${rst}"
    foreach ($v in $contentViolations) {
        Write-Host "    ${red}[VIOLATION] $v${rst}"
    }
    $failed = $true
} else {
    Write-Host " ${grn}[OK] Passed${rst}"
}

# 5. Check 4: 3-Way Synchronization Gate (if any module changed)
$modulesChanged = $filesToCheck | Where-Object { $_ -match 'src[\\/]modules[\\/]' }
if ($modulesChanged) {
    Write-Host ""
    Write-Host "  ${cyn}[SYNC]${rst} Module changes detected. Running 3-Way Sync Auditor..."
    $auditor = Join-Path $repoRoot "scripts\audit-profile.ps1"
    if (Test-Path $auditor) {
        & pwsh -NoProfile -File $auditor
        if ($LASTEXITCODE -ne 0) {
            $failed = $true
        }
    }
}

Write-Host ""
Write-Host "${dim}----------------------------------------------------${rst}"

if ($failed) {
    Write-Host "${red}${bld}[REJECTED] Code quality verification failed.${rst}"
    Write-Host "Please address the issues listed above before committing."
    Write-Host ""
    exit 1
} else {
    Write-Host "${grn}${bld}[APPROVED] Code quality verification passed.${rst}"
    Write-Host ""
    exit 0
}

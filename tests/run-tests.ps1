# run-tests.ps1 - Warph Terminal Test Suite Runner
# Usage: pwsh -NoProfile -File tests/run-tests.ps1 [-Benchmark]

[CmdletBinding()]
param(
    [switch]$Benchmark
)

$repoRoot = Split-Path $PSScriptRoot -Parent
$grn = $PSStyle.Foreground.BrightGreen
$red = $PSStyle.Foreground.BrightRed
$cyn = $PSStyle.Foreground.BrightCyan
$rst = $PSStyle.Reset
$bld = $PSStyle.Bold

Write-Host ""
Write-Host "${cyn}${bld}Warph Terminal - Comprehensive Test Suite${rst}"
Write-Host "------------------------------------------------------"

$failed = $false

# 1. Global AST Syntax Sweep
Write-Host "  [1/3] Parsing AST of all project PowerShell scripts..."
$allScripts = Get-ChildItem -Path $repoRoot -Recurse -Filter "*.ps1" | Where-Object { $_.FullName -notmatch '\\\.git\\' }
foreach ($s in $allScripts) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($s.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors) {
        Write-Host "    ${red}[FAIL] $($s.FullName.Replace($repoRoot, ''))${rst}: $errors"
        $failed = $true
    }
}
if (-not $failed) {
    Write-Host "    ${grn}[OK] All $($allScripts.Count) scripts passed AST syntax check${rst}"
}

# 2. Pester / Unit Assertions
Write-Host "  [2/3] Running functional tests (profile.tests.ps1)..."
$testFile = Join-Path $PSScriptRoot "profile.tests.ps1"
if (Test-Path $testFile) {
    & pwsh -NoProfile -File $testFile
    if ($LASTEXITCODE -ne 0) { $failed = $true }
}

# 3. Profile Auditor & 3-Way Sync Gate
Write-Host "  [3/3] Running module sync & standards check..."
$auditor = Join-Path $repoRoot "scripts\audit-profile.ps1"
if (Test-Path $auditor) {
    if ($Benchmark) {
        & pwsh -NoProfile -File $auditor -Benchmark
    } else {
        & pwsh -NoProfile -File $auditor
    }
    if ($LASTEXITCODE -ne 0) { $failed = $true }
}

Write-Host "------------------------------------------------------"
if ($failed) {
    Write-Host "${red}${bld}Test suite failed!${rst}"
    exit 1
} else {
    Write-Host "${grn}${bld}All tests passed successfully!${rst}"
    exit 0
}

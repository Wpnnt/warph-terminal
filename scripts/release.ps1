# release.ps1 — Warph Terminal Automated Release Utility
# Usage:
#   .\scripts\release.ps1                     # Interactive (auto-detect version from commits)
#   .\scripts\release.ps1 -Bump minor -Push   # Bump minor version and push immediately
#   .\scripts\release.ps1 -Version v1.2.0     # Explicit version release
#   .\scripts\release.ps1 -DryRun             # Preview version calculation without changes

#Requires -Version 7

[CmdletBinding()]
param(
    [ValidateSet('auto', 'patch', 'minor', 'major')]
    [string]$Bump = 'auto',

    [string]$Version,

    [switch]$Push,

    [switch]$SkipTests,

    [switch]$DryRun
)

$grn  = $PSStyle.Foreground.BrightGreen
$ylw  = $PSStyle.Foreground.BrightYellow
$cyn  = $PSStyle.Foreground.BrightCyan
$red  = $PSStyle.Foreground.BrightRed
$dim  = $PSStyle.Foreground.BrightBlack
$bold = $PSStyle.Bold
$rst  = $PSStyle.Reset

$repoRoot = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "${cyn}${bold}  +----------------------------------------------+${rst}"
Write-Host "${cyn}${bold}  |       Warph Terminal - Release Automation    |${rst}"
Write-Host "${cyn}${bold}  +----------------------------------------------+${rst}"
Write-Host ""

# 1. Git sanity check
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "${red}[FAIL] Git is not installed or not in PATH.${rst}"
    exit 1
}

$isGitRepo = git rev-parse --is-inside-work-tree 2>$null
if ($isGitRepo -ne 'true') {
    Write-Host "${red}[FAIL] Current directory is not a Git repository.${rst}"
    exit 1
}

# Check for uncommitted changes
$status = git status --porcelain
if ($status) {
    Write-Host "${ylw}[!] Working tree has uncommitted changes:${rst}"
    $status | ForEach-Object { Write-Host "    $dim$_$rst" }
    Write-Host ""
    $proceed = Read-Host "  Continue release with uncommitted changes? [y/N]"
    if ($proceed -notmatch '^[yYsS]$') {
        Write-Host "  Release aborted. Please commit or stash your changes first."
        exit 0
    }
}

# 2. Run test suite
if (-not $SkipTests) {
    Write-Host "  ${dim}[1/4]${rst} Running pre-flight verification & benchmark..."
    $testScript = Join-Path $repoRoot "tests\run-tests.ps1"
    if (Test-Path $testScript) {
        & pwsh -NoProfile -File $testScript -Benchmark
        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "${red}${bold}[FAIL] Pre-flight tests failed. Release aborted.${rst}"
            exit $LASTEXITCODE
        }
    }
} else {
    Write-Host "  ${dim}[1/4]${rst} ${dim}Skipping test suite (-SkipTests specified)${rst}"
}

# 3. Detect latest tag
Write-Host ""
Write-Host "  ${dim}[2/4]${rst} Inspecting repository tags and history..."
$latestTag = git tag -l "v*" --sort=-v:refname | Select-Object -First 1
if (-not $latestTag) {
    $latestTag = "v1.0.0"
    Write-Host "    No existing tags found. Baseline set to ${cyn}$latestTag${rst}"
} else {
    Write-Host "    Latest release tag: ${cyn}$latestTag${rst}"
}

# Parse current SemVer
$curMaj = 1
$curMin = 0
$curPat = 0
if ($latestTag -match '^v?(\d+)\.(\d+)\.(\d+)$') {
    $curMaj = [int]$matches[1]
    $curMin = [int]$matches[2]
    $curPat = [int]$matches[3]
}

# 4. Calculate target version
$targetTag = $null
$detectedBump = $Bump

if ($Version) {
    $targetTag = if ($Version.StartsWith('v')) { $Version } else { "v$Version" }
} else {
    $commits = git log "$latestTag..HEAD" --oneline
    $commitCount = if ($commits) { @($commits).Count } else { 0 }

    Write-Host "    Commits since $($latestTag): ${bold}$commitCount${rst}"
    if ($commits) {
        $commits | Select-Object -First 10 | ForEach-Object { Write-Host "      $dim$_$rst" }
        if ($commitCount -gt 10) { Write-Host "      $dim... and $($commitCount - 10) more$rst" }
    }

    if ($Bump -eq 'auto') {
        if ($commits -match '(?i)BREAKING CHANGE|!:') {
            $detectedBump = 'major'
        } elseif ($commits -match '(?i)feat(?:\(.*?\))?:') {
            $detectedBump = 'minor'
        } else {
            $detectedBump = 'patch'
        }
    }

    switch ($detectedBump) {
        'major' { $targetTag = "v$($curMaj + 1).0.0" }
        'minor' { $targetTag = "v$curMaj.$($curMin + 1).0" }
        'patch' { $targetTag = "v$curMaj.$curMin.$($curPat + 1)" }
    }
}

Write-Host ""
Write-Host "  ${dim}[3/4]${rst} Version Plan:"
Write-Host "    Current : ${dim}$latestTag${rst}"
Write-Host "    Bump    : ${ylw}$detectedBump${rst}"
Write-Host "    Target  : ${grn}${bold}$targetTag${rst}"
Write-Host ""

if ($DryRun) {
    Write-Host "${ylw}[DRY RUN] Would create tag $targetTag. No changes made.${rst}"
    exit 0
}

# 5. Confirm and execute
$doRelease = $Push
if (-not $doRelease) {
    $confirm = Read-Host "  Create tag $targetTag and push release to GitHub? [Y/n]"
    $doRelease = ($confirm -notmatch '^[nN]$')
}

if (-not $doRelease) {
    Write-Host "  Release cancelled."
    exit 0
}

Write-Host ""
Write-Host "  ${dim}[4/4]${rst} Creating tag and dispatching release..."

# Tag locally
git tag -a $targetTag -m "Release $targetTag"
if ($LASTEXITCODE -ne 0) {
    Write-Host "${red}[FAIL] Failed to create git tag $targetTag.${rst}"
    exit 1
}
Write-Host "    ${grn}[OK]${rst} Created tag ${bold}$targetTag${rst}"

# Push to origin
Write-Host "    Pushing to origin..."
git push origin main
git push origin $targetTag

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "${grn}${bold}Release $targetTag successfully dispatched!${rst}"
    Write-Host "GitHub Actions workflow 'release.yml' is now building the package"
    Write-Host "and publishing the release notes automatically."
    Write-Host "Track progress: ${cyn}https://github.com/Wpnnt/warph-terminal/actions${rst}"
} else {
    Write-Host "${red}[FAIL] Failed to push tag $targetTag to remote.${rst}"
}

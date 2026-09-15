# profile.tests.ps1 - Functional and environment tests for Warph Terminal

$repoRoot = Split-Path $PSScriptRoot -Parent
$srcProfile = Join-Path $repoRoot "src\Microsoft.PowerShell_profile.ps1"

$grn = $PSStyle.Foreground.BrightGreen
$red = $PSStyle.Foreground.BrightRed
$dim = $PSStyle.Foreground.BrightBlack
$rst = $PSStyle.Reset

function Assert-Condition ($desc, [scriptblock]$condition) {
    try {
        $res = & $condition
        if ($res) {
            Write-Host "    ${grn}[OK]${rst} $desc"
            return $true
        } else {
            Write-Host "    ${red}[FAIL]${rst} $desc"
            return $false
        }
    } catch {
        Write-Host "    ${red}[FAIL]${rst} $desc (Exception: $_)"
        return $false
    }
}

$allPass = $true

# Test 1: Entrypoint exists
$t1 = Assert-Condition "Source profile entrypoint exists" { Test-Path $srcProfile }
if (-not $t1) { $allPass = $false }

# Test 2: Source config directory exists
$configDir = Join-Path $repoRoot "src\config"
$t2 = Assert-Condition "src/config directory exists" { Test-Path $configDir }
if (-not $t2) { $allPass = $false }

# Test 3: Source modules directory exists
$modulesDir = Join-Path $repoRoot "src\modules"
$t3 = Assert-Condition "src/modules directory exists" { Test-Path $modulesDir }
if (-not $t3) { $allPass = $false }

# Test 4: Profile load execution test in isolated subshell
$testCmd = ". '$srcProfile'; (Get-Command cb, yti, nuke, tomp4, myip, Show-Help).Count -eq 6"
$loadResult = pwsh -NoProfile -Command $testCmd
$t4 = Assert-Condition "Profile loads successfully and registers core functions" { $loadResult -eq 'True' }
if (-not $t4) { $allPass = $false }

# Test 5: Themes directory has cobalt2
$themeFile = Join-Path $repoRoot "themes\cobalt2.omp.json"
$t5 = Assert-Condition "themes/cobalt2.omp.json exists" { Test-Path $themeFile }
if (-not $t5) { $allPass = $false }

# Test 6: Root setup.ps1 and helper scripts exist
$t6 = Assert-Condition "Root setup.ps1 exists" { Test-Path (Join-Path $repoRoot "setup.ps1") }
if (-not $t6) { $allPass = $false }

$t7 = Assert-Condition "scripts/install.ps1 exists" { Test-Path (Join-Path $repoRoot "scripts\install.ps1") }
if (-not $t7) { $allPass = $false }

$t8 = Assert-Condition "scripts/uninstall.ps1 exists" { Test-Path (Join-Path $repoRoot "scripts\uninstall.ps1") }
if (-not $t8) { $allPass = $false }

# Test 9: Visual assets exist
$logoFile = Join-Path $repoRoot "assets\logo.svg"
$t9 = Assert-Condition "assets/logo.svg exists" { Test-Path $logoFile }
if (-not $t9) { $allPass = $false }

if (-not $allPass) {
    exit 1
} else {
    exit 0
}

### Warph Terminal - Modular PowerShell Profile Orchestrator

# Global command check helper
$_cmdCache = @{}
function _has ($Cmd) {
    if (-not $_cmdCache.ContainsKey($Cmd)) {
        $_cmdCache[$Cmd] = [bool](Get-Command $Cmd -ErrorAction SilentlyContinue)
    }
    $_cmdCache[$Cmd]
}

# 1. Load Configurations (Environment, Theme, Integrations, Keybinds)
$_cfgDir = Join-Path $PSScriptRoot "config"
if (Test-Path -LiteralPath $_cfgDir) {
    @('env.ps1', 'theme.ps1', 'integrations.ps1', 'keybinds.ps1') | ForEach-Object {
        $_cfg = Join-Path $_cfgDir $_
        if (Test-Path -LiteralPath $_cfg) { . $_cfg }
    }
}

Write-Host "Use 'Show-Help' to list all available functions" -ForegroundColor Yellow

# 2. Modular Functions Auto-Discovery Loader (loads all domain *.ps1 in modules/)
$_modDir = Join-Path $PSScriptRoot "modules"
if (Test-Path -LiteralPath $_modDir) {
    [System.IO.Directory]::GetFiles($_modDir, "*.ps1") |
    Sort-Object |
    ForEach-Object {
        . $_
    }
}

# 3. Optional Local Overrides (untracked personal/machine settings)
$_localCfg = Join-Path $PSScriptRoot "config\local.ps1"
if (Test-Path -LiteralPath $_localCfg) { . $_localCfg }


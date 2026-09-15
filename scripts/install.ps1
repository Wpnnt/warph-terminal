# install.ps1 — Warph Terminal Direct Installer Shortcut
# Usage:
#   .\scripts\install.ps1                   (Interactive install)
#   .\scripts\install.ps1 -Mode 3           (Install both WT profile and $PROFILE loader)
#   .\scripts\install.ps1 -Mode 3 -Quiet    (Silent installation)

#Requires -Version 7

[CmdletBinding()]
param(
    [ValidateSet('1', '2', '3')]
    [string]$Mode,

    [switch]$SkipOptional,
    [switch]$Quiet
)

& (Join-Path (Split-Path $PSScriptRoot -Parent) "setup.ps1") -Install -Mode:$Mode -SkipOptional:$SkipOptional -Quiet:$Quiet

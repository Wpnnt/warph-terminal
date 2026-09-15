# uninstall.ps1 — Warph Terminal Clean Interactive Uninstaller
# Usage:
#   .\scripts\uninstall.ps1          (Interactive with confirmation)
#   .\scripts\uninstall.ps1 -Force   (Silent / non-interactive)

#Requires -Version 7

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Quiet
)

& (Join-Path (Split-Path $PSScriptRoot -Parent) "setup.ps1") -Uninstall -Force:$Force -Quiet:$Quiet

# setup.ps1 — Convenience wrapper pointing to root setup.ps1
# Usage: .\scripts\setup.ps1 [args]

& (Join-Path (Split-Path $PSScriptRoot -Parent) "setup.ps1") @args

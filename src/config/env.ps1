# env.ps1 — PATH resolution and environment initialization

# Rust CLI tools — add winget package dirs to PATH
$_wingetBase = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages"
if (Test-Path $_wingetBase) {
    Get-ChildItem $_wingetBase -Recurse -Filter "*.exe" -Depth 3 -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch 'unins' } |
    ForEach-Object { $_.DirectoryName } |
    Sort-Object -Unique |
    Where-Object { $env:PATH -notlike "*$_*" } |
    ForEach-Object { $env:PATH = "$_;$env:PATH" }
}

# Standard 64-bit bin directories
@("$env:ProgramFiles\bottom\bin", "$env:ProgramFiles\gitui\bin") |
Where-Object { (Test-Path $_) -and ($env:PATH -notlike "*$_*") } |
ForEach-Object { $env:PATH = "$_;$env:PATH" }

# integrations.ps1 — Third-party CLI integrations (zoxide, atuin, terminal-icons)

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    zoxide init --cmd z powershell | Out-String | Invoke-Expression
}

if (Get-Command atuin -ErrorAction SilentlyContinue) {
    atuin init powershell --disable-up-arrow | Out-String | Invoke-Expression
}

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module -Name Terminal-Icons
}

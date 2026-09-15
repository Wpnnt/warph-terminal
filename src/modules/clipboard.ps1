# clipboard.ps1 - Clipboard and text utilities
function cb { $input | Set-Clipboard }
function b64 ($Text) { [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Text)) }
function b64d ($Text) { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Text)) }
function uuid { [guid]::NewGuid().ToString() }
function genpass ([int]$Len = 20) {
    $pw = -join ((33..126) | Get-Random -Count $Len | ForEach-Object { [char]$_ })
    $pw | Set-Clipboard
    Write-Host "✓ Copied to clipboard" -ForegroundColor Green
    return $pw
}

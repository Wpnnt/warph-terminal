# apps.ps1 - Application launchers with portable fallbacks
function ex { explorer.exe $args }

function ag {
    if (_has antigravity-ide) { antigravity-ide @args }
    elseif (_has code) { code @args }
    else { Write-Host "Neither antigravity-ide nor code found in PATH" -ForegroundColor Yellow }
}

function vlc {
    if (_has vlc) { vlc @args; return }
    $vlcPaths = @(
        "${env:ProgramFiles}\VideoLAN\VLC\vlc.exe",
        "${env:ProgramFiles(x86)}\VideoLAN\VLC\vlc.exe",
        "$env:LOCALAPPDATA\Programs\VideoLAN\VLC\vlc.exe"
    )
    $exe = $vlcPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($exe) { & $exe @args }
    else { Write-Host "VLC not found" -ForegroundColor Yellow }
}

function colorpick {
    if (_has PowerToys.ColorPickerUI) { Start-Process (Get-Command PowerToys.ColorPickerUI).Source; return }
    $ptPaths = @(
        "${env:ProgramFiles}\PowerToys\PowerToys.ColorPickerUI.exe",
        "$env:LOCALAPPDATA\Programs\PowerToys\PowerToys.ColorPickerUI.exe"
    )
    $exe = $ptPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($exe) { Start-Process $exe }
    else { Write-Host "PowerToys ColorPicker not found" -ForegroundColor Yellow }
}

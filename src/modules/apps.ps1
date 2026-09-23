# apps.ps1 - Application launchers with portable fallbacks
function ex { explorer.exe $args }

function ag {
    if (_has antigravity-ide) { antigravity-ide @args }
    elseif (_has code) { code @args }
    else {
        Write-Host "  $($PSStyle.Foreground.BrightYellow)[!]$($PSStyle.Reset) $($PSStyle.Foreground.BrightBlack)Neither antigravity-ide nor code found in PATH$($PSStyle.Reset)"
    }
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
    else {
        Write-Host "  $($PSStyle.Foreground.BrightYellow)[!]$($PSStyle.Reset) $($PSStyle.Foreground.BrightBlack)VLC not found$($PSStyle.Reset)"
    }
}

function colorpick {
    if (_has PowerToys.ColorPickerUI) { Start-Process (Get-Command PowerToys.ColorPickerUI).Source; return }
    $ptPaths = @(
        "${env:ProgramFiles}\PowerToys\PowerToys.ColorPickerUI.exe",
        "$env:LOCALAPPDATA\Programs\PowerToys\PowerToys.ColorPickerUI.exe"
    )
    $exe = $ptPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($exe) { Start-Process $exe }
    else {
        Write-Host "  $($PSStyle.Foreground.BrightYellow)[!]$($PSStyle.Reset) $($PSStyle.Foreground.BrightBlack)PowerToys ColorPicker not found$($PSStyle.Reset)"
    }
}

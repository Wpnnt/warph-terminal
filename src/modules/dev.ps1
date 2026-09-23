# dev.ps1 - Developer workflow shortcuts
function nuke {
    $dirs = @('node_modules', '.bun', '.next', '.nuxt', 'dist', '.turbo')
    $dim = $PSStyle.Foreground.BrightBlack
    $cyn = $PSStyle.Foreground.BrightCyan
    $rst = $PSStyle.Reset
    $dirs | Where-Object { Test-Path $_ } | ForEach-Object {
        Write-Host "  ${dim}Removing ${cyn}$_${rst}"
        Remove-Item $_ -Recurse -Force
    }
    if (Test-Path 'bun.lockb') { bun install } elseif (Test-Path 'package-lock.json') { npm install }
}

function killport ($Port) {
    $dim = $PSStyle.Foreground.BrightBlack
    $cyn = $PSStyle.Foreground.BrightCyan
    $rst = $PSStyle.Reset
    $pid_ = (Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue).OwningProcess | Select-Object -First 1
    if ($pid_) {
        $proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
        Write-Host "  ${dim}Killing ${cyn}$($proc.ProcessName)${dim} (PID ${cyn}$pid_${dim}) on port ${cyn}$Port${rst}"
        Stop-Process -Id $pid_ -Force
    }
    else {
        Write-Host "  ${dim}No process on port ${cyn}$Port${rst}"
    }
}

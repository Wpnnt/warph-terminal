# dev.ps1 - Developer workflow shortcuts
function nuke {
    $dirs = @('node_modules', '.bun', '.next', '.nuxt', 'dist', '.turbo')
    $dirs | Where-Object { Test-Path $_ } | ForEach-Object {
        Write-Host "Removing $_" -ForegroundColor Yellow
        Remove-Item $_ -Recurse -Force
    }
    if (Test-Path 'bun.lockb') { bun install } elseif (Test-Path 'package-lock.json') { npm install }
}

function killport ($Port) {
    $pid_ = (Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue).OwningProcess | Select-Object -First 1
    if ($pid_) {
        $proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
        Write-Host "Killing $($proc.ProcessName) (PID $pid_) on port $Port" -ForegroundColor Yellow
        Stop-Process -Id $pid_ -Force
    }
    else {
        Write-Host "No process on port $Port" -ForegroundColor Gray
    }
}

# rust-tools.ps1 - Modern CLI tool wrappers (Rust ecosystem) with native fallbacks

# Listing (eza)
function la {
    if (_has eza) { eza --icons -a @args }
    else { Get-ChildItem | Format-Table -AutoSize }
}

function ll {
    if (_has eza) { eza --icons -la --git @args }
    else { Get-ChildItem -Force | Format-Table -AutoSize }
}

# Viewer (bat)
Remove-Alias cat -Force -ErrorAction SilentlyContinue
function cat {
    if (_has bat) { bat --style=plain @args }
    else { Get-Content @args }
}

# Disk usage (dust)
function du {
    if (_has dust) { dust @args }
    else { Get-ChildItem -Recurse -File @args | Measure-Object -Property Length -Sum }
}

# Process monitor (bottom)
function top { btm @args }

# Modern process listing (procs)
function ps2 { procs @args }

# Code stats (tokei)
function loc { tokei @args }

# Benchmarking (hyperfine)
function bench { hyperfine @args }

# HTTP client (xh)
function http { xh @args }

# Git TUI (gitui)
function gui { gitui @args }

# File manager (yazi)
function fm { yazi @args }

# Directory tree (broot)
function tree {
    if (_has broot) { broot @args }
    else { Get-ChildItem -Recurse -Depth 2 @args }
}

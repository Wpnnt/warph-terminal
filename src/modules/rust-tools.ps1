# rust-tools.ps1 - Modern CLI tool shortcuts with native fallbacks

# Listing shortcuts for eza
function la {
    if (_has eza) { eza --icons -a @args }
    else { Get-ChildItem | Format-Table -AutoSize }
}

function ll {
    if (_has eza) { eza --icons -la --git @args }
    else { Get-ChildItem -Force | Format-Table -AutoSize }
}

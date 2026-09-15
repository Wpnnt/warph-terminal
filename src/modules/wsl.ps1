# wsl.ps1 - WSL management shortcuts
function wls { wsl -l -v }
function woff { wsl --shutdown }
function wk ($Distro) { wsl --terminate $Distro }
function wsh { wsl -d @args }

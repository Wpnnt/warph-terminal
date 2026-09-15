# theme.ps1 — Oh-My-Posh theme initialization and resolution

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $_themeCandidates = @(
        (Join-Path $PSScriptRoot "..\..\themes\cobalt2.omp.json"),
        (Join-Path $PSScriptRoot "..\themes\cobalt2.omp.json"),
        (Join-Path $PSScriptRoot "themes\cobalt2.omp.json"),
        (Join-Path $PSScriptRoot "cobalt2.omp.json"),
        (Join-Path ([Environment]::GetFolderPath('UserProfile')) ".warph-terminal\themes\cobalt2.omp.json"),
        (Join-Path ([Environment]::GetFolderPath('UserProfile')) ".warph-terminal\cobalt2.omp.json"),
        (Join-Path (Split-Path $PROFILE) "cobalt2.omp.json")
    )
    $_themePath = $_themeCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($_themePath) {
        oh-my-posh init pwsh --config $_themePath | Invoke-Expression
    }
}

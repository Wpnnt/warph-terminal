# theme.ps1 — Oh-My-Posh theme initialization and resolution

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $_themeCandidates = @(
        (Join-Path $PSScriptRoot "..\..\themes\warph.omp.json"),
        (Join-Path $PSScriptRoot "..\themes\warph.omp.json"),
        (Join-Path $PSScriptRoot "themes\warph.omp.json"),
        (Join-Path $PSScriptRoot "warph.omp.json"),
        (Join-Path ([Environment]::GetFolderPath('UserProfile')) ".warph-terminal\themes\warph.omp.json"),
        (Join-Path ([Environment]::GetFolderPath('UserProfile')) ".warph-terminal\warph.omp.json"),
        (Join-Path (Split-Path $PROFILE) "warph.omp.json")
    )
    $_themePath = $_themeCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($_themePath) {
        oh-my-posh init pwsh --config $_themePath | Invoke-Expression
    }
}

# keybinds.ps1 — PSReadLine styling, predictive IntelliSense, and key chords

if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
    try {
        Set-PSReadLineOption -PredictionViewStyle ListView -Colors @{
            Command   = '#6BD0DB'
            Parameter = '#A0CCA0'
            Operator  = '#EBE9EA'
            Variable  = '#7CB7FF'
            String    = '#E5C07B'
            Number    = '#D5D4D5'
            Type      = '#56B6C2'
            Comment   = '#606162'
            Keyword   = '#6BD0DB'
            Error     = '#E06C75'
        } -ErrorAction Stop

        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
        Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
        Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
        Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo
    } catch {
        # Ignored in non-interactive / redirected console hosts
    }
}

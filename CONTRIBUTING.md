# Contributing to Warph Terminal

Contributions are welcome! Whether you are adding a new shortcut, fixing a bug, or improving documentation, follow this quick guide.

---

## How to Contribute

### 1. Create a Branch

Fork the repository and create a new branch from `main`:

```powershell
git checkout -b feature/my-new-shortcut
```

*(Use `fix/<description>` for bug fixes).*

### 2. Make Your Changes

- **Domain shortcuts**: Add them to `src/modules/<domain>.ps1` (e.g. `network.ps1`, `media.ps1`, `system.ps1`). If it's a completely new category, create a new `.ps1` file in `src/modules/` — it will be auto-discovered.
- **Core configuration**: Modify `src/config/` (`env.ps1`, `keybinds.ps1`, `theme.ps1`, `integrations.ps1`).

### 3. Keep 3-Way Synchronization

If you add a new command or alias, you must update 3 places:

1. **The function**: in `src/modules/<domain>.ps1`
2. **The terminal help**: in `Show-Help` (`src/modules/help.ps1`)
3. **The documentation**: in the command table of `README.md`

> The automated test runner verifies that all functions exist in both `Show-Help` and `README.md`. If one is missing, tests will fail.

### 4. Run the Tests

Before opening a pull request, run the test suite to verify syntax and synchronization:

```powershell
pwsh -NoProfile -File tests/run-tests.ps1
```

All 24 scripts must pass AST parsing and the 3-Way Sync check.

### 5. Commit & Open a Pull Request

Use [Conventional Commits](https://www.conventionalcommits.org/):

```powershell
git commit -m "feat(network): add curlssl helper"
git push origin feature/my-new-shortcut
```

Then open a Pull Request against the `main` branch. GitHub Actions will automatically run the test suite on your PR.

---

## Coding Guidelines

- **Short, mnemonic names**: Prefer 2 to 4 characters for frequent commands (e.g. `cb`, `myip`, `mkcd`, `killport`).
- **External tool guards**: If wrapping an external binary (`eza`, `bat`, `fd`, `yt-dlp`), always use the `_has` helper with a native PowerShell fallback:
  ```powershell
  function cat {
      param([Parameter(ValueFromRemainingArguments = $true)]$Args)
      if (_has bat) { bat @Args }
      else { Get-Content @Args }
  }
  ```
- **Zero hardcoded paths**: Never hardcode user paths or drive letters. Use:
  - `[Environment]::GetFolderPath('UserProfile')` (user home)
  - `[Environment]::GetFolderPath('MyVideos')` (videos)
  - `$PSScriptRoot` (relative script directory)
- **Terminal output**: Keep all `Write-Host` messages in English. Use `$PSStyle.Foreground.*` for coloring. Avoid raw emojis.
- **Clipboard feedback**: When a command copies text to the clipboard, show:
  ```powershell
  Write-Host "✓ Copied to clipboard" -ForegroundColor Green
  ```

# Contributing to Warph Terminal

Contributions are welcome! Whether you are adding a new shortcut, fixing a bug, or improving documentation, follow this quick guide.

---

## How to Contribute

### 1. Create a Branch

Fork the repository and branch off `develop`:

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

### 4. Run the Tests & Quality Gate

Before opening a pull request, run the test suite to verify syntax and synchronization:

```powershell
pwsh -NoProfile -File tests/run-tests.ps1
```

All project scripts must pass AST parsing and module synchronization checks. Additionally, Git pre-commit hooks via Husky run automated quality checks to enforce clean syntax, cross-terminal charset compatibility, and portable paths on every `git commit`.

### 5. Commit & Open a Pull Request

Use [Conventional Commits](https://www.conventionalcommits.org/):

```powershell
git commit -m "feat(network): add curlssl helper"
git push origin feature/my-new-shortcut
```

Then open a Pull Request against the `develop` branch. GitHub Actions will automatically run the test suite on your PR.

---

## Coding Guidelines

- Keep command names short and easy to remember (2 to 4 characters where practical, such as `cb`, `myip`, `mkcd`, `killport`).
- Guard external binaries (`eza`, `bat`, `fd`, `yt-dlp`) with the `_has` helper and provide a native PowerShell fallback:
  ```powershell
  function cat {
      param([Parameter(ValueFromRemainingArguments = $true)]$Args)
      if (_has bat) { bat @Args }
      else { Get-Content @Args }
  }
  ```
- Avoid hardcoding system paths or drive letters. Use dynamic lookups instead:
  - `[Environment]::GetFolderPath('UserProfile')` (user home)
  - `[Environment]::GetFolderPath('MyVideos')` (videos directory)
  - `$PSScriptRoot` (relative script directory)
- Keep `Write-Host` messages in English and use `$PSStyle.Foreground.*` for coloring. Stick to standard ASCII or verified Nerd Font glyphs to prevent encoding artifacts across terminal hosts.
- For commands that copy text to the clipboard, provide confirmation:
  ```powershell
  Write-Host "✓ Copied to clipboard" -ForegroundColor Green
  ```

---

## Releases

Releases follow Semantic Versioning with automated packaging via script or GitHub Actions:

### Option A: Local Release Script (Interactive)

Run the release automation tool:

```powershell
.\scripts\release.ps1
```

- Automatically executes pre-flight tests and latency benchmarks.
- Inspects commit messages since the last tag to calculate the appropriate SemVer bump (`major`, `minor`, or `patch`).
- Prompts for confirmation, generates the annotated Git tag, and pushes to GitHub.

You can also pass arguments directly:
```powershell
.\scripts\release.ps1 -Bump minor -Push   # Direct minor bump
.\scripts\release.ps1 -Version v1.2.0     # Explicit version
.\scripts\release.ps1 -DryRun             # Preview version plan
```

### Option B: One-Click GitHub Actions (`workflow_dispatch`)

1. Go to the **Actions** tab on GitHub.
2. Select the **Release Package** workflow.
3. Click **Run workflow**, choose the bump type (`auto`, `patch`, `minor`, `major`), and run.
4. The workflow verifies the codebase, creates the tag, packages `warph-terminal.zip`, and publishes the release notes.


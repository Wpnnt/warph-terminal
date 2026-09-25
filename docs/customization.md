# Customization Guide — Warph Terminal

Learn how to extend Warph Terminal with new command modules, themes, and personalized configurations.

---

## 1. Adding a New Command Module

To create a new domain of commands (e.g. `docker.ps1`, `git.ps1`, `k8s.ps1`):

1. **Create the file in `src/modules/`**:
   Example: `src/modules/docker.ps1`
   ```powershell
   # docker.ps1 — Docker shortcuts
   function dps  { docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" }
   function dimg { docker images }
   function dstop { docker stop $(docker ps -q) }
   ```

2. **Add to `Show-Help`**:
   Open `src/modules/help.ps1` and add your section:
   ```powershell
   ${section}Docker${reset}
   ${dim}----------------------------------------------------${reset}
     ${command}dps${reset}                 ${accent}->${reset} ${desc}List running containers compactly${reset}
     ${command}dimg${reset}                ${accent}->${reset} ${desc}List local docker images${reset}
   ```

3. **Update `README.md`**:
   Add the new commands to the corresponding reference table.

4. **Verify**:
   Run the test suite to verify 3-Way Sync:
   ```powershell
   pwsh -NoProfile -File tests/run-tests.ps1
   ```

---

## 2. Adding or Changing Themes

1. Place your Oh-My-Posh theme JSON file in `themes/`:
   Example: `themes/dracula.omp.json`
2. Update `src/config/theme.ps1` to reference your theme:
   ```powershell
   $_themeCandidates = @(
       (Join-Path $PSScriptRoot "..\..\themes\dracula.omp.json"),
       ...
   )
   ```
3. Run `.\scripts\setup.ps1 -Repair` to refresh the installed themes in `~/.warph-terminal`.

---

## 3. Customizing Keybindings & Colors

Edit `src/config/keybinds.ps1`:
- Modify the `$Colors` dictionary to adjust PSReadLine syntax highlighting.
- Add new custom chord handlers via `Set-PSReadLineKeyHandler`.

---

## 4. Customizing the Terminal Font

Warph Terminal automatically detects all installed Nerd Fonts on your system and configures your Windows Terminal profile to use them.

### Changing the Font via Setup
```powershell
.\setup.ps1 -SetFont                 # Interactive font selector
.\setup.ps1 -Font "0xProto Nerd Font" # Set specific font directly
.\setup.ps1                          # Choose option [3] Customize Font in the menu
```

### Supported Nerd Fonts
Any installed Nerd Font can be used, for example:
- `0xProto Nerd Font`
- `CaskaydiaCove NF` / `CaskaydiaCove Nerd Font`
- `JetBrainsMono Nerd Font`
- `FiraCode Nerd Font`
- `MesloLGS NF`
- `Hack Nerd Font`

You can install additional fonts on demand via option `[3]` in `setup.ps1` or using oh-my-posh:
```powershell
oh-my-posh font install CascadiaCode --headless
```

> [!NOTE]
> Nerd Fonts are completely optional. If you prefer not to install custom fonts or want to avoid network downloads, Warph Terminal cleanly defaults to standard system fonts already present on Windows (`Cascadia Mono` or `Consolas`), ensuring 100% error-free execution.

---

## 5. Personal & Machine Overrides (`local.ps1`)

If you want custom shortcuts, environment variables, or private tokens that are **never committed to Git**:

1. Create `src/config/local.ps1` (or in `~/.warph-terminal/config/local.ps1`).
2. Add your custom functions, export keys, or work aliases:
   ```powershell
   # local.ps1 — Personal & untracked configuration
   $env:GITHUB_TOKEN = "ghp_..."
   function work-vpn { Connect-Vpn -Name "Corporate" }
   ```
3. `local.ps1` is automatically gitignored and loaded at the end of every shell startup.


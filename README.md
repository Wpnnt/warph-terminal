<div align="center">

<img src="assets/logo.svg" alt="Warph Terminal Logo" width="180" />

# Warph Terminal

**A modular, high-performance PowerShell 7 environment for Windows**  
Automated module discovery • Modern Rust CLI tools • Media utilities • Oh My Posh prompt

[![PowerShell](https://img.shields.io/badge/PowerShell-7.4%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6.svg)](https://microsoft.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## Overview

Warph Terminal replaces monolithic PowerShell profiles with a lightweight, decoupled architecture:

- **Modular Discovery**: Modules placed in `src/modules/*.ps1` are auto-loaded at startup without editing manifests.
- **Fast Startup**: Optimized startup path running under 90ms.
- **Zero Hardcoded Paths**: All user, system, and media locations resolve dynamically via .NET APIs.
- **Portable Setup**: Installs to `~/.warph-terminal` and works across machines.
- **Modern CLI Integration**: Native wrappers and fallbacks for modern Rust tools (`eza`, `bat`, `fd`, `bottom`, `ripgrep`, etc.).
- **Interactive Media Toolkit**: yt-dlp terminal UI (`yti`) and single-command FFmpeg format converters.

---

## Prerequisites

Before installing, ensure you have:

1. **[PowerShell 7.4+](https://github.com/PowerShell/PowerShell/releases)** (`pwsh.exe`)
2. **[Windows Terminal](https://apps.microsoft.com/detail/9n0dx20hk701)** (**Required host** — the legacy `conhost.exe` console cannot render Nerd Font glyphs, Cobalt2 true-color ANSI, or SVG profile icons)
3. **A Nerd Font** *(Optional)* — e.g., [CaskaydiaCove Nerd Font](https://www.nerdfonts.com/font-downloads) or [JetBrainsMono NF] to render extra prompt icons and glyphs. If skipped or not installed, Warph Terminal cleanly defaults to standard built-in system fonts (**Cascadia Mono** / **Consolas**) without errors.

> [!TIP]
> **Automatic Prerequisite Setup**: You don't need to install everything manually. Running `.\setup.ps1` (or `install.cmd`) automatically checks your environment and offers to install Windows Terminal and PowerShell 7 via `winget`. Font installation is optional and can be customized at any time with `.\setup.ps1 -SetFont`.

---

## Installation

### Option 1: Quick Install (Recommended)

Run this one-liner in PowerShell 7 to download and launch the installer directly:

```powershell
irm da.gd/warph | iex
```

### Option 2: Release ZIP (One-Click)

1. Download the latest `warph-terminal.zip` from [Releases](https://github.com/Wpnnt/warph-terminal/releases).
2. Extract the archive.
3. Double-click **`install.cmd`** to run the setup automatically.

### Option 3: Git Clone

```powershell
git clone https://github.com/Wpnnt/warph-terminal.git
cd warph-terminal
.\setup.ps1
```

---

### Setup Modes

When prompted, choose your preferred target:

| Option | Mode | Details |
|---|---|---|
| `[1]` | **Windows Terminal Profile** | Creates a dedicated "Warph Terminal" profile entry in Windows Terminal. |
| `[2]` | **Global PowerShell Profile** | Adds a non-destructive loader to your current `$PROFILE`. |
| `[3]` | **Both (Recommended)** | Configures both targets. |

### Helper Scripts

```powershell
.\setup.ps1                  # Interactive management menu (Install, Font, Prereqs, Repair, etc.)
.\setup.ps1 -CheckPrereqs    # Verify and auto-install Windows Terminal, fonts, and tools
.\setup.ps1 -SetFont         # Interactive Nerd Font selector & installer
.\setup.ps1 -Font "<name>"   # Set specific font directly (e.g. -Font "0xProto Nerd Font")
.\scripts\install.ps1        # Direct non-interactive installation (supports -Font "<name>")
.\setup.ps1 -Repair          # Refresh scripts and themes in ~/.warph-terminal
.\scripts\uninstall.ps1      # Clean removal and profile restoration
```

---

## Toolchain & Dependencies

### Core (Installed via `setup.ps1`)

| Dependency | Purpose |
|---|---|
| [oh-my-posh](https://ohmyposh.dev) | Prompt engine (bundled with the Cobalt2 theme) |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` command with directory frecency |
| [Terminal-Icons](https://github.com/devblackops/Terminal-Icons) | File and folder icons in directory listings |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Video and audio downloader (`yt`, `yti`, `yta`, `vyt`, `vyta`) |
| [deno](https://deno.com) | JavaScript runtime required by yt-dlp extractors |
| [ffmpeg](https://ffmpeg.org) | Audio/video conversion and stream muxing |

### Optional Rust CLI Tools (via `install-rust-tools.ps1`)

Run `.\scripts\install-rust-tools.ps1` to install modern CLI alternatives via `winget`:

| Tool | Alias | Replaces / Role |
|---|---|---|
| [eza](https://github.com/eza-community/eza) | `la`, `ll` | Modern `ls` with icons, file metadata, and Git status |
| [bat](https://github.com/sharkdp/bat) | `cat` | Syntax-highlighted file pager |
| [fd](https://github.com/sharkdp/fd) | `ff` | Fast recursive file search |
| [bottom](https://github.com/ClementTsang/bottom) | `top` | Graphical system and process monitor |
| [dust](https://github.com/bootandy/dust) | `du` | Visual disk usage analyzer |
| [broot](https://github.com/Canop/broot) | `tree` | Interactive directory tree navigator |
| [procs](https://github.com/dalance/procs) | `ps2` | Modern process viewer |
| [tokei](https://github.com/XAMPPRocky/tokei) | `loc` | Codebase line counter |
| [hyperfine](https://github.com/sharkdp/hyperfine) | `bench` | CLI command benchmarking tool |
| [gitui](https://github.com/extrawurst/gitui) | `gui` | Terminal UI for Git |
| [yazi](https://github.com/sxyazi/yazi) | `fm` | Terminal file manager |
| [xh](https://github.com/ducaale/xh) | `http` | HTTP client for APIs |
| [atuin](https://github.com/atuinsh/atuin) | — | Shell history search and sync |

---

## Command Reference

### Files & Navigation

| Command | Description |
|---|---|
| `touch <file>` | Create an empty file or update its timestamp |
| `mkcd <dir>` | Create a directory and immediately enter it |
| `trash <path>` | Move a file or folder to the Windows Recycle Bin |
| `ff <glob>` | Fast search for files by name (`fd` or `Get-ChildItem`) |
| `head <file>` | Print the first 10 lines of a file |
| `sed <file> <find> <replace>` | Inline search and replace in a file |
| `which <cmd>` | Locate the executable path of a command |
| `la` | List files including hidden items with icons |
| `ll` | Detailed file list with Git status and permissions |
| `cat <file>` | Print file contents with syntax highlighting (`bat` or `Get-Content`) |
| `du` | Show interactive disk usage (`dust` or fallback) |
| `tree` | Interactive directory tree navigation |
| `cleantemp` | Remove temporary files in `%TEMP%` and report reclaimed space |

### WSL Management

| Command | Description |
|---|---|
| `wls` | List installed WSL distributions and running states |
| `woff` | Shut down all active WSL instances (`wsl --shutdown`) |
| `wk <distro>` | Terminate a specific WSL distribution |
| `wsh <distro>` | Open a shell directly in a given distribution |

### Network & HTTP

| Command | Description |
|---|---|
| `myip` | Query public IP address and geolocation, then copy to clipboard |
| `flushdns` | Flush the Windows DNS resolver cache |
| `testport <host> <port>` | Test TCP connectivity to a remote host and port |
| `curltime <url>` | Measure latency breakdown for DNS, TLS, connect, and transfer |
| `curlhead <url>` | Inspect HTTP response headers |
| `curlssl <domain>` | Verify TLS certificate information and expiration |
| `curlstatus <url>` | Return only the HTTP response status code |
| `curlfollow <url>` | Trace HTTP redirect chains |
| `cget <url>` | Send an HTTP GET request with formatted JSON output |
| `cpost <url> <body>` | Send an HTTP POST request with a JSON payload |
| `cput <url> <body>` | Send an HTTP PUT request with a JSON payload |
| `cpatch <url> <body>` | Send an HTTP PATCH request with a JSON payload |
| `cdel <url>` | Send an HTTP DELETE request |
| `cdl <url>` | Download a file with progress indicators |
| `cdlr <url>` | Download a file with automatic retries on failure |

### Clipboard & Utilities

| Command | Description |
|---|---|
| `cb` | Pipe pipeline input directly into the Windows clipboard |
| `b64 <text>` | Encode a string to Base64 |
| `b64d <text>` | Decode a Base64 string |
| `uuid` | Generate a new UUID v4 and copy it to the clipboard |
| `genpass [length]` | Generate a secure random password (default: 20 characters) and copy it |

### Developer Workflow

| Command | Description |
|---|---|
| `nuke` | Clean build artifacts (`node_modules`, `.next`, `dist`, `target`) and reinstall dependencies |
| `killport <port>` | Find and terminate the process listening on a specified TCP port |
| `top` | Launch system and process monitor (`bottom`) |
| `ps2` | Modern process tree viewer (`procs`) |
| `loc` | Count lines of code by language (`tokei`) |
| `bench <cmd>` | Benchmark execution time of a command (`hyperfine`) |
| `http <args>` | Fast HTTP tool for APIs (`xh`) |
| `fm` | Terminal file manager (`yazi`) |
| `uptime` | Display Windows uptime since last boot |

### Media Downloader (`yt-dlp`)

`yt` and `yta` target the current working directory, while `vyt` and `vyta` save directly to your user `Videos` and `Music` folders.

| Command | Description |
|---|---|
| `yti [url]` | Interactive terminal downloader with clipboard URL auto-detection |
| `yt <url>` | Download best-quality video to current directory (opens TUI if run without args) |
| `yta <url>` | Download best-quality audio as MP3 to current directory |
| `vyt <url>` | Download best-quality video directly to user `Videos` directory |
| `vyta <url>` | Download best-quality audio directly to user `Music` directory |
| `ytls <url>` | List all available streams and formats for a given URL |

**Common parameters:**
- `-q 720|1080|4k`: Set maximum resolution limit.
- `-Type mp4|webm|mkv`: Set preferred video container.
- `-Type mp3|flac|wav|m4a`: Set preferred audio format.
- `-Out <path>`: Custom destination directory.

### Media Conversion (`ffmpeg`)

Convert media files directly in your terminal:

| Command | Description |
|---|---|
| `tomp4 <file>` | Convert video to MP4 (H.264 / AAC) |
| `tomp3 <file>` | Extract or convert audio to high-bitrate MP3 |
| `towav <file>` | Convert audio to 16-bit PCM WAV |
| `togif <file> [fps] [width]` | Convert video segment to optimized GIF (default: 15 fps, 480px) |
| `towebm <file>` | Convert video to WebM (VP9 / Opus) |
| `toflac <file>` | Convert audio to lossless FLAC |

### System & Desktop

| Command | Description |
|---|---|
| `ex [path]` | Open Windows File Explorer at the current or specified path |
| `ag` | Launch Antigravity IDE in the current workspace |
| `vlc <file>` | Play an audio or video file with VLC Media Player |
| `colorpick` | Launch PowerToys Color Picker |
| `winutil` | Launch Chris Titus Tech Windows Utility |
| `pgrep <name>` | Search running processes by partial name |
| `pkill <name>` | Gracefully stop running processes by name |
| `k9 <name>` | Forcefully terminate processes by name (immediate kill) |
| `c` | Clear the terminal screen (`Clear-Host`) |
| `grep <pattern>` | Search text with `ripgrep` (`rg`) or fallback to `Select-String` |
| `Show-Help` | Render an organized overview of all available commands |

---

## Keyboard Shortcuts (PSReadLine)

| Keybinding | Action |
|---|---|
| `Up` / `Down` | History search matching the current input prefix |
| `Tab` | Interactive autocompletion menu |
| `Ctrl+D` | Delete character at cursor |
| `Ctrl+W` | Delete previous word |
| `Alt+D` | Delete next word |
| `Ctrl+Left` / `Ctrl+Right` | Move cursor word by word |
| `Ctrl+Z` / `Ctrl+Y` | Undo / Redo |

---

## Repository Architecture

```
warph-terminal/
├── assets/
│   └── logo.svg                      # Official Warph Terminal vector logo
├── .github/
│   └── workflows/
│       └── audit.yml                 # CI workflow: syntax, functional tests, and 3-way sync
├── scripts/
│   ├── setup.ps1                     # Core setup engine (install, repair, uninstall)
│   ├── web-install.ps1               # Standalone web installer for irm | iex
│   ├── install.ps1                   # Non-interactive quick installation
│   ├── install-rust-tools.ps1        # Optional CLI tools installer
│   ├── uninstall.ps1                 # Clean profile restoration
│   └── audit-profile.ps1             # Local convention and synchronization auditor
├── src/
│   ├── Microsoft.PowerShell_profile.ps1 # Profile orchestrator and dynamic module loader
│   ├── config/                       # Core environment setup
│   │   ├── env.ps1                   # Tool path resolution and environment settings
│   │   ├── integrations.ps1          # Oh My Posh, Zoxide, and Terminal-Icons init
│   │   ├── keybinds.ps1              # PSReadLine colors and keybindings
│   │   └── theme.ps1                 # Theme loading logic
│   └── modules/                      # Domain-specific modules (auto-discovered)
│       ├── apps.ps1                  # Desktop shortcuts (ag, ex, vlc, colorpick)
│       ├── clipboard.ps1             # Clipboard and text tools (cb, b64, uuid, genpass)
│       ├── dev.ps1                   # Development helpers (nuke, killport)
│       ├── help.ps1                  # Show-Help documentation renderer
│       ├── media.ps1                 # Media downloader and FFmpeg converters
│       ├── network.ps1               # Network diagnostics and HTTP helpers
│       ├── rust-tools.ps1            # CLI wrappers for Rust tools
│       ├── system.ps1                # File and system management utilities
│       └── wsl.ps1                   # WSL helpers
├── tests/
│   ├── run-tests.ps1                 # Unified test suite runner
│   └── profile.tests.ps1             # AST and functional test assertions
├── themes/
│   └── cobalt2.omp.json              # Default Oh My Posh Cobalt2 theme
├── setup.ps1                         # Root interactive installer entrypoint
├── install.cmd                       # One-click Windows launcher for zip downloads
├── CONTRIBUTING.md                   # Branching workflow, commit guidelines, and PR rules
├── LICENSE                           # MIT License
├── README.md                         # Command reference and project documentation
└── .gitignore                        # Universal Git ignore rules
```

---

## Customization

### Adding a New Module

Warph Terminal automatically detects and sources any `.ps1` file inside `src/modules/`:

1. Create a new module file: `src/modules/docker.ps1`
   ```powershell
   function dps  { docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" }
   function dimg { docker images }
   function dstop { docker stop $(docker ps -q) }
   ```
2. Add entries to `Show-Help` in `src/modules/help.ps1` and document them in `README.md`.
3. Verify your additions with the test runner:
   ```powershell
   pwsh -NoProfile -File tests/run-tests.ps1
   ```

### Private & Machine-Specific Config (`local.ps1`)

For personal aliases, API tokens, or custom environments you do not want to track in Git:

1. Create `src/config/local.ps1` (or `~/.warph-terminal/config/local.ps1`).
2. Add your environment variables or private functions:
   ```powershell
   $env:GITHUB_TOKEN = "ghp_..."
   function work-vpn { Connect-Vpn -Name "Corporate" }
   ```
3. `local.ps1` is automatically ignored by Git and sourced at the end of profile initialization.

---

## Testing & Quality Assurance

Run the automated test suite locally before submitting changes:

```powershell
pwsh -NoProfile -File tests/run-tests.ps1 -Benchmark
```

The test runner validates:
- **AST Syntax**: Verifies all PowerShell scripts parse with 0 syntax errors.
- **Functional Assertions**: Confirms core profile functions register properly.
- **3-Way Synchronization**: Ensures all functions are documented in `Show-Help` and `README.md`.
- **Conventions**: Rejects hardcoded user directories and unrendered glyphs.
- **Startup Latency**: Measures profile load time in milliseconds.

---

## Contributing

Please review [CONTRIBUTING.md](CONTRIBUTING.md) for branch naming conventions (`develop` base, `feature/*`, `fix/*`), Conventional Commits formatting, and PR submission guidelines.

---

## License

This project is licensed under the [MIT License](LICENSE).

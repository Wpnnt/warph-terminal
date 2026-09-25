# Changelog — Warph Terminal

All notable changes to Warph Terminal are documented in this file following [Keep a Changelog](https://keepachangelog.com/) and [Semantic Versioning](https://semver.org/).

---

## [v1.4.0] — 2026-09-24

### Added
- **Automated Test Suite Runner**: Unified test runner (`tests/run-tests.ps1`) combining AST syntax verification across all scripts with functional assertions and latency benchmarking.
- **Profile Auditor & Quality Gate**: Added `scripts/audit-profile.ps1` and `scripts/quality-gate.ps1` to enforce strict 3-way synchronization between implementation modules, `Show-Help`, and `README.md`.
- **Modular Help System**: Added `src/modules/help.ps1` featuring color-coded sections and Nerd Font category glyphs.
- **TrueColor Terminal Banner**: Pre-rendered half-block terminal banner (`assets/banner.ansi`) with 24-bit RGB gradient rendering for setup UI and web installation.
- **Standalone Web Installer**: Single-command remote installer (`scripts/web-install.ps1`) supporting headless installation, profile target selection, and custom branch previews.
- **Preview Channel Link**: Registered and configured `da.gd/warph_dev` shortlink pointing to the active `develop` branch.

### Changed
- Replaced monolithic setup console output with a styled interactive terminal interface.
- Standardized character encodings and dynamic paths across all helper scripts.

---

## [v1.3.0] — 2026-09-15

### Changed
- Refactored CLI tool wrappers to prioritize native CLI syntax for tools like `eza` and `fd` while maintaining fallback safety.

---

## [v1.2.0] — 2026-09-15

### Added
- Nerd Font glyph support across terminal prompt and help menus.
- UTF-8 console encoding guarantee on shell startup.
- Enhanced profile logo badge rendering.

---

## [v1.1.0] — 2026-09-15

### Added
- GitHub Actions automated release pipeline (`release.yml`) with automated SemVer calculation, zip packaging, and release note generation.

---

## [v1.0.0] — 2026-09-15

### Initial Public Release
- **Domain-Driven Modular Architecture**: Deconstructed monolithic profile into clean, domain-specific modules in `src/modules/` and sequential core configuration in `src/config/`.
- **Auto-Discovery Loader**: High-speed dynamic discovery and sourcing of any `*.ps1` script placed in `src/modules/` without editing manifests.
- **Modern CLI Integration**: Aliases, wrappers, and native fallbacks for CLI tools (`eza`, `bat`, `fd`, `bottom`, `dust`, `procs`, `tokei`, `hyperfine`, `gitui`, `yazi`, `xh`).
- **Interactive Media Toolkit**: Fast `yt-dlp` terminal UI (`yti`) with clipboard URL auto-detection and FFmpeg converters (`tomp4`, `tomp3`, `towav`, `togif`, `towebm`, `toflac`).
- **Network & System Helpers**: Rapid HTTP testing commands (`cget`, `cpost`, `cput`, `cdel`), latency analyzer (`curltime`), TLS certificate inspector (`curlssl`), process kill shortcuts (`killport`, `k9`), and cache cleaning (`cleantemp`, `nuke`).
- **One-Liner Web Installer**: Direct web installation via `irm da.gd/warph | iex`.
- **Portability Guarantee**: 100% dynamic path resolution with zero hardcoded paths or drive letters.

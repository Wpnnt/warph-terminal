# Architecture Specification — Warph Terminal

Warph Terminal is a modular PowerShell 7 environment engineered for Windows 10 and 11. It replaces monolithic profile scripts with a decoupled architecture based on dynamic discovery, zero hardcoded paths, and automated quality verification.

---

## System Architecture

```text
Host (Windows Terminal / ConPTY)
  └── PowerShell 7 (pwsh.exe)
        └── Profile (~/.warph-terminal/Microsoft.PowerShell_profile.ps1)
              ├── src/config/ ───────── Sequential bootstrap (env, theme, integrations, keybinds)
              ├── src/modules/ ──────── Auto-discovered dynamic command bus (*.ps1)
              └── src/config/local.ps1  Untracked private overrides (optional)
```

---

## Directory Responsibilities

| Directory | Layer | Responsibility | Loading Mechanism |
|---|---|---|---|
| `src/config/` | Bootstrap | Environment variables, PATH fixes, Oh-My-Posh theme initialization, tool integrations (`zoxide`, `atuin`, `Terminal-Icons`), and PSReadLine token formatting. | Deterministic sequential load |
| `src/modules/` | Command Bus | Domain functions, CLI wrappers, network helpers, media downloaders, and utilities. | Dynamic runtime auto-discovery (`*.ps1`) |
| `docs/` | Specification | In-depth architectural designs, extension guides, and release changelogs. | Static documentation |
| `themes/` | Presentation | Oh-My-Posh theme definitions and visual tokens (`warph.omp.json`). | Referenced during prompt bootstrap |
| `assets/` | Branding | Vector logo (`logo.svg`), 3D ANSI banner (`banner.ansi`), and curated theme variants. | Static UI assets |
| `scripts/` | Operations | Web installer (`web-install.ps1`), setup engine (`setup.ps1`), profile repair, and release tools. | CLI execution |
| `tests/` | Quality Gate | AST syntax validator, 3-way synchronization auditor, and startup latency benchmark. | Automated CI & pre-commit |

---

## Execution Lifecycle

### Startup Pipeline (< 90ms)

| Phase | Source | Responsibility | Latency |
|---|---|---|---|
| **1. Host** | `wt.exe` → `pwsh.exe` | Spawns shell and invokes `$PROFILE` entrypoint | ~20ms |
| **2. Bootstrap** | `src/config/*.ps1` | Sequential setup: `env` → `theme` → `integrations` → `keybinds` | ~30ms |
| **3. Discovery** | `src/modules/*.ps1` | High-speed .NET IO scan and in-memory dot-sourcing | ~35ms |
| **4. Local** | `src/config/local.ps1` | Loads private untracked tokens and custom aliases | < 5ms |

### Command Resolution Guard (`_has`)

| Condition | Execution Target | Example (`cat file.txt`) | Guarantee |
|---|---|---|---|
| **Binary Found** | Fast CLI binary with optimized flags | `bat @args` (syntax highlighting) | High performance |
| **Binary Missing** | Native PowerShell cmdlet | `Get-Content @args` | Zero-crash fallback |

---

## Core Invariants

- **Zero Hardcoding**: All filesystem paths resolve dynamically via `[Environment]::GetFolderPath` and `$PSScriptRoot`.
- **3-Way Synchronization**: Every command in `src/modules/` is strictly mirrored in `Show-Help` and `README.md` (validated by `tests/run-tests.ps1`).
- **Resilient Fallbacks**: Third-party tools never block shell initialization; missing binaries fail gracefully to native cmdlets.

---

## Documentation Topology (`docs/`)

- **[architecture.md](architecture.md)** — System topology, execution pipeline, and design constraints.
- **[customization.md](customization.md)** — Adding modules, integrating custom themes, and font configuration.
- **[changelog.md](changelog.md)** — Version history aligned with Semantic Versioning.

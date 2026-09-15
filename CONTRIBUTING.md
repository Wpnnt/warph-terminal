# Contributing to Warph Terminal

Thank you for your interest in contributing to **Warph Terminal**! To maintain stability, cross-machine portability, and code quality, please adhere to the following workflow and conventions.

---

## Git Branching Model

We follow an adapted **Git Flow / GitHub Flow** model:

```
main (production releases & tags vX.Y.Z)
  ^
  | (merge via Release PR)
develop (active development & integration)
  ^                     ^
  | (feature branch)     | (bugfix branch)
feature/<name>        fix/<name>
```

### Branch Rules

| Branch | Purpose | Target / Base | Direct Commits? |
|--------|---------|---------------|-----------------|
| `main` | Production-ready, stable releases. Always working and installable. | Tagged releases (`v2.0.0`) | No (PR only) |
| `develop` | Integration branch where features and fixes land. | Base for new branches | Preferred via PR/feature |
| `feature/<name>` | New tools, functions, or major enhancements. | Branch from `develop`, PR to `develop` | Yes |
| `fix/<name>` | Bugfixes, path resolution, OS compatibility fixes. | Branch from `develop`, PR to `develop` | Yes |
| `release/<version>` | Staging and testing before merging into `main`. | Branch from `develop`, PR to `main` | Only release prep |

---

## Conventional Commits

All commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat(<scope>): <description>` - New function or feature
- `fix(<scope>): <description>` - Bug fix or compatibility correction
- `docs(<scope>): <description>` - Documentation or README changes
- `refactor(<scope>): <description>` - Code refactoring without behavioral changes
- `test(<scope>): <description>` - Test or auditor script updates
- `chore(<scope>): <description>` - Housekeeping, dependencies, or git configs

**Examples:**
```bash
git commit -m "feat(git): add branch management shortcuts"
git commit -m "fix(installer): handle spaces in username path safely"
git commit -m "docs: add CONTRIBUTING.md with branch conventions"
```

---

## Development & Coding Standards

1. **Clean Typography**: Use clean ASCII characters and standard text instead of missing/unsupported font glyphs or emojis.
2. **Terminal Feedback Language**: Terminal output (`Write-Host`) must be in **English**.
3. **Color Formatting**: Use `$PSStyle.Foreground.*` for styling rather than hardcoded ANSI escape codes.
4. **Zero Hardcoded Paths**:
   - Never hardcode drive letters (`C:`, `D:`) or usernames (`Warph11`).
   - Use `[Environment]::GetFolderPath('UserProfile')`, `$PSScriptRoot`, or `$HOME`.
5. **Portable Fallbacks**: Every tool relying on external CLI binaries must use the `_has <cmd>` guard with a native PowerShell fallback.
6. **3-Way Synchronization**:
   Whenever a new function or shortcut is added:
   1. Define it in the appropriate module in `src/modules/<domain>.ps1` (or create a new module for a new domain).
   2. Add it to `Show-Help` in `src/modules/help.ps1` in the matching section.
   3. Document it in `README.md`.

---

## Pre-PR Verification Checklist

Before pushing branches or opening a Pull Request, run the automated test suite and auditor:

```powershell
pwsh -NoProfile -File tests/run-tests.ps1 -Benchmark
```

Ensure that:
- [ ] PowerShell AST parser returns **0 syntax errors**.
- [ ] 3-Way Sync reports **100% matched functions**.
- [ ] No hardcoded user paths are detected.
- [ ] Zero emojis rule is respected.

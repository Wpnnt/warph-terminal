## Description
Describe the changes proposed in this Pull Request and why they were made.

## Type of Change
- [ ] `feat`: New command, shortcut, or feature
- [ ] `fix`: Bug fix or edge case correction
- [ ] `docs`: Documentation updates or additions
- [ ] `refactor`: Code reorganization with no behavior change
- [ ] `style`: Formatting, terminal coloring, or layout tweaks
- [ ] `test`: Test suite additions or modifications

## 3-Way Synchronization Checklist
If adding or updating user commands, verify that:
- [ ] Function is defined in `src/modules/<domain>.ps1` (with `_has` guard and native fallback if applicable).
- [ ] Function is documented in `Show-Help` (`src/modules/help.ps1`).
- [ ] Function is documented in the reference table of `README.md`.

## Quality & Verification
- [ ] Ran `pwsh -NoProfile -File tests/run-tests.ps1 -Benchmark` and all tests passed.
- [ ] No hardcoded machine paths (uses `[Environment]::GetFolderPath` or `$PSScriptRoot`).
- [ ] Clean ASCII or verified Nerd Font glyphs (no unrendered Unicode symbols).
- [ ] Conventional Commit message format used.

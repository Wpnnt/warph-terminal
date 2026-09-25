# Security Policy

## Supported Versions

Only the latest release on the `main` branch receives active security updates.

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

Warph Terminal executes PowerShell scripts and interacts with CLI tooling. Security, script integrity, and environment safety are top priorities.

If you discover a potential security concern, unexpected behavior, or vulnerability:

1. **Open an Issue:** Submit a report via [GitHub Issues](https://github.com/Wpnnt/warph-terminal/issues/new) using the title prefix `[SECURITY] <Brief Description>`.
2. **Private Reporting:** Alternatively, you can use [GitHub Security Advisories](https://github.com/Wpnnt/warph-terminal/security/advisories/new) if you prefer to submit your report through GitHub's private vulnerability disclosure system.

Please include:
- A clear description of the issue.
- Minimal steps to reproduce the behavior or a proof-of-concept script.
- Affected PowerShell version (`$PSVersionTable.PSVersion`) and Windows build.
- Recommended fixes or mitigation suggestions, if known.

Issues will be triaged and addressed promptly.

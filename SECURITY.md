# Security Policy

## Supported Versions

The following versions of Shortcuts-Custom are currently supported with security updates:

| Version | Supported |
|---------|-----------|
| 1.x.x   | ✅        |
| < 1.0   | ❌        |

## Reporting a Vulnerability

We take security seriously. If you discover a vulnerability in Shortcuts-Custom, please do not open a public GitHub issue. Instead, please report it privately using one of the following methods:

- **GitHub Private Vulnerability Reporting:** Use the **Report a vulnerability** button under the Security tab of this repository.
- **Email:** Send details to the project maintainer at paul@osasi.org.

### What to Include

Please include as much of the following as possible:

- A description of the vulnerability and its potential impact
- Steps to reproduce the issue
- Any relevant version information (Windows version, AutoHotkey version)
- Suggested fix or mitigation, if known

### What to Expect

- We will acknowledge receipt of your report within **5 business days**.
- We will provide an assessment and expected timeline for a fix within **10 business days**.
- We will notify you when the vulnerability has been patched and credit you in the release notes (unless you prefer to remain anonymous).

## Scope

Shortcuts-Custom is a local Windows desktop application. Key security considerations include:

- **Local file access:** The app reads and writes JSON files on the user's local machine.
- **No authentication:** The app is not designed to be exposed to the public internet and has no built-in authentication layer.
- **No external data transmission:** The app does not send user data to any external server. All data is stored in browser localStorage and local files.
- **Script execution:** The app can launch `.bat`, `.ps1`, or `.exe` files from user-defined shortcuts. Users should only add trusted scripts.

We recommend running Shortcuts-Custom only on trusted local machines.

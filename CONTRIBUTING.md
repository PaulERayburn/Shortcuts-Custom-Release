# Contributing to Shortcuts-Custom

Thank you for your interest in contributing to Shortcuts-Custom! This project is maintained by PaulR and we welcome contributions from the community.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Submitting Changes](#submitting-changes)
- [Branch Protection](#branch-protection)
- [Submitting an Issue](#submitting-an-issue)
- [Reporting Bugs](#reporting-bugs)
- [Requesting Features](#requesting-features)

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it before contributing.

## How to Contribute

1. **Fork** the repository on GitHub.
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/Shortcuts-Custom-Release.git
   ```
3. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make your changes** and commit them (see [Submitting Changes](#submitting-changes)).
5. **Push** your branch to GitHub:
   ```bash
   git push origin feature/your-feature-name
   ```
6. **Open a Pull Request** against the `main` branch of this repository.

## Development Setup

### Prerequisites

- Windows 10 or 11
- [AutoHotkey v2](https://www.autohotkey.com/) — only needed to run from source
- Microsoft Edge (pre-installed on Windows 10/11)
- A text editor (VS Code recommended)

### Running Locally

1. Clone or download the repository.
2. Double-click `popup.ahk` to start the app.
3. You'll see a tooltip: `"Shortcuts Popup ready!"` and a green H icon in your system tray.
4. Edit `.ahk`, `.html`, or `.js` files in your editor, then reload the script (right-click tray icon → Reload Script).

## Submitting Changes

- Write clear, descriptive commit messages in the imperative mood (e.g., `Fix search not filtering by category`).
- Keep pull requests focused — one feature or fix per PR.
- Reference related issues in your PR description (e.g., `Closes #12`).
- Ensure your changes do not break existing hotkeys or UI functionality before submitting.
- Update `CHANGELOG.md` with a brief description of your change under the appropriate version heading.

## Branch Protection

The `main` branch is protected:

- **Pull request required** — no direct pushes to `main`; all changes must go through a PR.
- **1 approving review required** — at least one maintainer must approve your PR.
- **Stale approvals dismissed** — if you push new commits after approval, it must be re-approved.
- **Conversation resolution required** — all review comments must be marked resolved before merging.

## Submitting an Issue

When you open a new issue, you will be prompted to choose a template:

- **Bug Report** — use this to report something that is broken or behaving unexpectedly.
- **Feature Request** — use this to suggest a new feature or improvement.
- **Ask a Question** — links to Discussions, the right place for general questions so they remain searchable for others.

Blank issues are disabled — please use a template so maintainers have the context they need to help you quickly.

## Reporting Bugs

Please use the Bug Report issue template and include:

- A clear description of the problem
- Steps to reproduce the issue
- Expected vs. actual behavior
- Windows version and AutoHotkey version (if running from source)

## Requesting Features

Please use the Feature Request issue template and describe:

- The problem your feature would solve
- Your proposed solution
- Any alternatives you've considered

## Questions?

If you have questions that aren't covered here, feel free to open a [Discussion](https://github.com/PaulERayburn/Shortcuts-Custom-Release/discussions) in the repository.

Thank you for helping improve Shortcuts-Custom!

<p align="center"><img src="gui/assets/ccskin-icon.png" alt="CC#Skin icon" width="88"></p>
<h1 align="center">CC#Skin</h1>
<p align="center">Fonts, appearance and Mods management for Claude desktop.</p>
<p align="center">
<a href="https://github.com/Orxooo/CCSkin/releases/latest"><img src="https://img.shields.io/github/v/release/Orxooo/CCSkin" alt="Latest release"></a>
<img src="https://img.shields.io/badge/macOS-26%2B-lightgrey" alt="macOS 26+">
<a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0--only-blue" alt="GPL-3.0-only"></a>
</p>

**[Download CC#Skin 1.2.1](https://github.com/Orxooo/CCSkin/releases/download/v1.2.1/CCSkin-1.2.1-macOS-arm64.zip)** · [简体中文](README.md) · [Changelog](CHANGELOG.md) · [Report an issue](https://github.com/Orxooo/CCSkin/issues/new/choose)

Current release: **1.2.1 (build 8)**. Requires **Apple Silicon and macOS 26+**. Mods management also needs the official Claude Code CLI **2.1.287+**.

![CC#Skin Mods sources, filters and rankings](docs/assets/mods.png)

## Features

- **Mods discovery**: Four community sources and 156 bundled marketplace entries, manual refresh and custom GitHub marketplaces.
- **Filters and ranking**: Combine search, source, category and installation status. Sort by repository Stars, repository push date, name or local detail views.
- **Plugin management**: Queue install, enable, disable, update and uninstall operations, then apply them through the official Claude Code CLI.
- **Fonts and typography**: Chinese, English, interface and code fonts; sizes, line height, paragraph spacing and reading width.
- **Colors and themes**: Light reading backgrounds, dark themes, saved combinations and JSON import/export.
- **Backup and restoration**: Complete backups before appearance changes, independent test copies and app restoration.

Several entries may share a repository; Stars and push dates describe that whole repository. Local views count detail opens on this Mac and are never uploaded. These sources do not provide verifiable public per-Mod downloads or global views, so those rankings are unavailable. See [Mods usage and data definitions](docs/MODS.md).

## Install

1. Download the app ZIP and [`SHA256SUMS.txt`](https://github.com/Orxooo/CCSkin/releases/download/v1.2.1/SHA256SUMS.txt).
2. Verify the checksum, extract the ZIP and move `CC#Skin.app` into Applications.
3. Open the app. For fonts and appearance, complete the App Management access check in Overview.

```sh
shasum -a 256 CCSkin-1.2.1-macOS-arm64.zip
```

The packaged app needs neither Python nor Xcode. It is signed with an Apple development certificate and is not notarized; see the [user guide](docs/USAGE.md#installation-and-checksums) for first-launch instructions.

To upgrade from claudefont, ClaudeFont or CcSkin, quit the old app and replace it. The bundle ID, settings, themes and backup directories remain compatible.

## Use

**Manage Mods:** Open Mods, search and filter, inspect details and source, queue operations, then choose Apply selected changes. Add custom GitHub marketplaces in Repositories. Browsing never registers a market or installs a plugin. Run `/reload-plugins` or reopen the target Code session afterwards, then verify the actual effect.

**Customize appearance:** Select a target in Overview. Adjust Fonts, Code and Background, or load a theme. Quit that Claude completely, apply changes, reopen it and check the result. To undo, quit Claude and choose Restore app in More actions.

Mods alone do not patch or re-sign Claude.app. Appearance changes use the existing complete-backup, patch and signing flow; start with an independent test copy. Mods use the current user's Claude Code configuration, independently of the main/test target selected for appearance.

## Verification and compatibility

See the [verification record](docs/VERIFICATION.md) for checks, signing, native UI and package coverage. Third-party Mods have not each been accepted inside Claude Desktop; their effects depend on the target session. Historical appearance runtime evidence covers Claude 2.19675.0. Recheck compatibility after Claude updates.

Community Mods run code on your machine. Catalog inclusion and repository popularity do not establish a security review of every third-party plugin.

## Data and development

Settings and themes use `~/.config/claudefont/`; backups and logs use `~/.local/share/claudefont/`. Release checks, catalog refresh and repository metrics contact GitHub. Local detail-view history stays on this Mac.

The client uses Swift / SwiftUI with a bundled Swift appearance engine. Development requires Xcode 26+ and a valid Apple signing identity.

[User guide](docs/USAGE.md) · [Mods guide](docs/MODS.md) · [Build and CLI](docs/DEVELOPMENT.md) · [Architecture](docs/ARCHITECTURE.md) · [Contributing](CONTRIBUTING.md)

## License

Copyright © 2026 Orxooo. [GPL-3.0-only](LICENSE). Independent of Anthropic; no Claude application code or font files are distributed. Community metadata retains its CC0/MIT notices, and third-party plugins retain their own licenses. See [NOTICE](NOTICE).

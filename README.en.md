# ClaudeFont

A font and appearance tool for Claude desktop, with separate Chinese and English font settings, reading layout, code styles and theme management.

[Download](https://github.com/Orxooo/ClaudeFont/releases/latest) · [简体中文](README.md) · [Changelog](CHANGELOG.md) · [Report an issue](https://github.com/Orxooo/ClaudeFont/issues/new/choose)

Requires an Apple Silicon Mac running macOS 26 or later.

![Font and reading layout settings](docs/assets/fonts.png)

## Features

- **Font settings:** Choose Chinese, English and code fonts separately; adjust font sizes and interface scaling.
- **Reading layout:** Adjust body line height, paragraph spacing and reading width.
- **Code styles:** Set fonts and sizes for replies, code blocks, diffs, the editor and terminal.
- **Appearance:** Configure light backgrounds and dark themes separately.
- **Theme management:** Save style combinations and import or export them as JSON files.
- **Backup and restore:** Create a complete backup before applying, use an independent test copy and restore the app when needed.

## Installation

1. Download the macOS package from [Releases](https://github.com/Orxooo/ClaudeFont/releases/latest).
2. Extract the ZIP and move the app to Applications.
3. Open the app and follow the access-check instructions.

The package includes the components it needs to run; Python and Xcode are not required. See the [user guide](docs/USAGE.md#installation-and-checksums) for checksum verification and first-launch instructions.

## Usage

1. Select the Claude app in **Overview**. Start with a test copy on first use.
2. Adjust **Fonts**, **Code** and **Background**, or load a saved combination in **Themes**.
3. Quit the selected Claude completely, then choose **Apply changes**.
4. Reopen Claude and check the actual appearance.

Previews and loaded themes do not write changes automatically. To undo changes, quit Claude and choose **Restore app** in **More actions**.

## Usage notes

ClaudeFont modifies and re-signs the selected Claude app, creating a complete backup before applying. Check compatibility after a Claude update before applying settings again.

Recorded runtime verification covers startup and font rendering on Claude 2.19675.0. Compatibility with other versions and all code regions still needs confirmation; see the [verification record](docs/VERIFICATION.md).

See the [user guide](docs/USAGE.md#english) for access, restoration, themes and local data. Include system and app versions, reproduction steps and redacted logs when reporting an issue.

## Development and contribution

The client uses Swift / SwiftUI with a bundled Swift engine. Development requires Xcode 26 or later and a valid Apple signing identity.

[Build and CLI](docs/DEVELOPMENT.md) · [Architecture](docs/ARCHITECTURE.md) · [Contributing](CONTRIBUTING.md)

## License

Licensed under [GPL-3.0-only](LICENSE). Independently developed by Orxooo and unaffiliated with Anthropic. The project distributes neither Claude application code nor font files; see [project notices](NOTICE).

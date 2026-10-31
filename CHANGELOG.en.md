# Changelog

[简体中文](CHANGELOG.md) · [Latest release](https://github.com/Orxooo/CCSkin/releases/latest)

## [1.2.0](https://github.com/Orxooo/CCSkin/releases/tag/v1.2.0) · 2026-10-31

- Support terminal fonts and scaling in Claude 4.4212.0's `ion-dist.asar` resources.
- Synchronize archive hashes and the enabled Electron 41+ framework integrity digest without disabling integrity validation.
- Sign affected Electron dependencies and Helpers with a consistent Apple certificate, preserving Helper entitlements and library validation. These targets require a local signing certificate.
- Separate write-access probing from style compatibility, fix misleading permission failures, and explain blocked application with a terminal-default reset action.
- Preserve complete backups, failed-startup rollback and exact vendor-signature restoration. Terminal scaling at 105%, startup and full restoration were verified on an independent Claude copy; actual session appearance still needs confirmation.

## [1.1.0](https://github.com/Orxooo/CCSkin/releases/tag/v1.1.0) · 2026-10-26

- Rename the app to CC#Skin and replace its icon.
- Add Mods management with 156 entries across four sources and custom repositories.
- Filter by source, category and installation status; sort by stars, updates or local views.
- Queue plugin installs, enable/disable, updates and removal.
- Align sidebar labels and filter controls; update repository and download links.
- Fix built-in terminal scaling: 110% and other scales now apply to both the loading placeholder and live terminal while keeping the vendor font and zoom logic.
- Extend the selected background to the composer surround, scroll fades, sidebar and plugin code panels in light and dark modes.

## [1.0.0](https://github.com/Orxooo/CCSkin/releases/tag/v1.0.0) · 2026-10-03

- Initial release with fonts, typography, colors and themes.
- Test copies, backup/restore, logs and release checks.
- Fix local font loading, startup after signing and test-copy execution.

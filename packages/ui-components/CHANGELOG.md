# Changelog

All notable changes to this package are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning: [SemVer](https://semver.org/) with Elm semantics (see `docs/conventions.md`, "Changing shared package APIs").

## [Unreleased]

## [2.0.0]

### Changed

- **BREAKING:** `1602/elm-feather` 2.3.5 <= v < 3.0.0 replaces `feathericons/elm-feather`; apps must depend on `1602/elm-feather` (#2).
- **BREAKING:** `Component.MobileDrawer.view` now requires a `label` field (e150ad8). Callers must supply an accessible label.

### Added

- `ui-components.css`: shared stylesheet exporting `@source` paths and dynamic class safelist for UI components (#2).

## [1.0.0]

- Initial release.

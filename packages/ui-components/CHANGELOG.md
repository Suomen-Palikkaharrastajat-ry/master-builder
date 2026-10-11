# Changelog

All notable changes to this package are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning: [SemVer](https://semver.org/) with Elm semantics (see `docs/conventions.md`, "Changing shared package APIs").

## [Unreleased]

### Added

- `Component.Navbar`: `viewBrand`, `viewMenuToggle`, and `viewAppHeader` for Compact application headers (#5).
- `Component.Footer.Family`: canonical links, copyright, disclaimer, and logo for the repository family (#6).
- `Component.Footer`: `viewWith` supporting `topMargin` toggle (`mt-auto` vs `mt-16`) and `extra` column content slot (#6).
- `Component.Button`: `Accent` variant and builder API (`new`, `submit`, `link`, `withVariant`, `withSize`, `withIcon`, `iconOnly`, `withDisabled`, `withLoading`, `withPressed`, `withTarget`, `toHtml`) (#7).
- `Component.Toast`: optional title, `viewToast`, and `region` aria-live container; refactored styling to semantic design tokens (#8).
- `Component.SkipLink`: accessible skip-to-content navigation helper (#11).
- `Component.ScrollToTop`: floating scroll-to-top button with right sidebar clearance option (#11).
- `Component.LoadState`: remote data state helper (`Loading`, `Failure` with Alert & retry, `Success`) and floating `badge` (#11).
- `Component.FeedLinks`: shared subscribe and export section with accessible cards and feed links (#12).

## [2.0.0]

### Changed

- **BREAKING:** `1602/elm-feather` 2.3.5 <= v < 3.0.0 replaces `feathericons/elm-feather`; apps must depend on `1602/elm-feather` (#2).
- **BREAKING:** `Component.MobileDrawer.view` now requires a `label` field (e150ad8). Callers must supply an accessible label.

### Added

- `ui-components.css`: shared stylesheet exporting `@source` paths and dynamic class safelist for UI components (#2).

## [1.0.0]

- Initial release.

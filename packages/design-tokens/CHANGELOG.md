# Changelog

All notable changes to this package are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning: [SemVer](https://semver.org/) with Elm semantics (see `docs/conventions.md`, "Changing shared package APIs").

## [Unreleased]

### Added

- `design-tokens.css`: standalone CSS module providing Tailwind v4 `@theme` and `@utility type-*` typography scale (#2).
- `DesignTokens.Colors.green` and the `--color-brand-green` theme variable (`bg-brand-green`, `text-brand-green`, ...).

### Changed

- `design-tokens.css` is now the file design-guide generates (`make design-tokens`) instead of a hand-maintained copy. It no longer sets `--font-mono`, so `font-mono` falls back to Tailwind's default stack, and `type-mono` uses the longer monospace fallback stack planet and event-calendar had before adopting the shared CSS (previously `ui-monospace, monospace`).

## [1.0.0]

- Initial release (generated from vendor/design-guide).

# Changelog

All notable changes to `palikkaharrastajat/finnish-datepicker` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed (breaking)

- `FinnishDatePicker.view`, `field` and `update` and `FinnishDate.format`, `parse`, `monthName` and `weekdayAbbr` take a locale as their first argument (any record with the fields of `FinnishDate.DateLocale`, e.g. `Locale.fi` from the app toolkit). The package no longer contains Finnish text.

### Fixed

- The date input uses `border-border-brand` instead of `border-border-default` so its boundary meets WCAG 1.4.11 and matches `Component.Form` inputs.

## [1.0.0] - 2026-10-12

### Added

- `FinnishDatePicker` module wrapping `CurrySoftware/elm-datepicker` with Finnish defaults and accessible `field` wrapper.
- `FinnishDate` module providing Finnish month and weekday naming, and date parse/format functions.
- `finnish-datepicker.css` providing token-aligned stylesheet for the datepicker popup.
- Unit tests for date parsing and formatting round-trips.

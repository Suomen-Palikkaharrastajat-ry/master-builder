# Changelog

All notable changes to this package are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning: [SemVer](https://semver.org/) with Elm semantics (see `docs/conventions.md`, "Changing shared package APIs").

## [Unreleased]

### Added

- `Locale`: a language's date and time conventions, with `fi`, `en` and `forCode`.
- `PocketBaseAuth`: `isAuthenticated`, `getToken`, `encodeAuthUser`, `authUserModelJson` (escapes names with quotes), `userFromPopupResult`, `callbackQuery` (percent-decoded `code` and `state` of `#/callback`) and `callbackRedirectUrl`, so event-calendar and service-map can drop their own `Auth.elm` (#16). `fetchOAuthToken` now delegates to `fetchOAuthUser`.
- `pocketbase-auth.js`: `resolveInitAuth`, a blocking start-up refresh (signed out on 401/403 without reload, stored token kept on network errors), and the `PocketBase` / `loadPocketBase` options for loading the SDK from the vendored hub, where a bare `import('pocketbase')` finds none (#16).
- `pocketbase-auth.test.mjs`: tests for the script (`node --test`, part of `make check`) (#16).

### Changed (breaking)

- `FinnishTime`: `weekdayAbbr`, `monthName`, `formatShortDate`, `formatTime` and `formatFullDate` take a `Locale` as their first argument. `isoDateToFinnishDateInput`, `finnishDateInputToIsoDate`, `parseFinnishDate` and `formatFinnishDate` are now `isoDateToDateInput`, `dateInputToIsoDate`, `parseDate` and `formatDate` and take a `Locale`. `finnishWeekdayAbbr` and `finnishMonthName` are removed (use `weekdayAbbr`/`monthName`).

### Added

- `View.MapOverlay`: overlay panels for map controls, filter groups, and responsive detail sheets/drawers (`panel`, `filterGroup`, `detailPanel`, `detailPanelWithHeaderActions`) (#13).
- `FinnishTime`: shared Helsinki timezone and Finnish date/time manipulation and formatting functions (`formatShortDate`, `formatTime`, `formatFullDate`, `parseFinnishDate`, `formatFinnishDate`, `formDateTimeToUtc`, `monthGrid`, …) (#14).
- `PocketBaseAuth`: msg-polymorphic OAuth token fetch (`fetchOAuthToken`), auth state restoration (`restoreAuthFromFlags`), and user JSON decoding (`decodeAuthUser`) (#14).
- `packages/app-toolkit/js/pocketbase-auth.js`: shared JavaScript helpers for token persistence, background refresh, and port subscription wiring (#14).
- `elm.json` declaring the package dependencies (`1602/elm-feather`, `elm/http`, `elm/json`, `elm/url`, `elm/time`, `justinmimbs/date`, `rtfeldman/elm-iso8601-date-strings`) (#2, #14).

## [1.0.0]

### Changed

- `View.Icons.featherIcon` now sets `aria-hidden` on the rendered icon (e150ad8).

- Initial release.

# Changelog

All notable changes to this package are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning: [SemVer](https://semver.org/) with Elm semantics (see `docs/conventions.md`, "Changing shared package APIs").

## [Unreleased]

### Added

- `Component.Layout`: the page shell shared by every site (skip link, header, mobile drawer, main, footer, scroll-to-top, toast region), driven by the site's resolved configuration and layout strings.
- `SiteSettings`: types and decoders for a site's `config.toml` as resolved per language by `packages/site-config`.
- `SiteSettings.fromFlags`: language, settings, default language and decode error for an app's startup; `Lang.attributeFor`: the `lang` attribute for content in another language than the interface.
- `Lang`: the supported languages; `UiStrings`: the layout and component labels per language (Finnish and English).
- `Component.Navbar`: `viewBrand`, `viewMenuToggle`, and `viewAppHeader` for Compact application headers (#5).
- `Component.Footer`: `viewWith` supporting `topMargin` toggle (`mt-auto` vs `mt-16`) and `extra` column content slot (#6).
- `Component.Button`: `Accent` variant and builder API (`new`, `submit`, `link`, `withVariant`, `withSize`, `withIcon`, `iconOnly`, `withDisabled`, `withLoading`, `withPressed`, `withTarget`, `toHtml`) (#7).
- `Component.Toast`: optional title, `viewToast`, and `region` aria-live container; refactored styling to semantic design tokens (#8).
- `Component.SkipLink`: accessible skip-to-content navigation helper (#11).
- `Component.ScrollToTop`: floating scroll-to-top button with right sidebar clearance option (#11).
- `Component.LoadState`: remote data state helper (`Loading`, `Failure` with Alert & retry, `Success`) and floating `badge` (#11).
- `Component.FeedLinks`: shared subscribe and export section with accessible cards and feed links (#12).
- `Component.Form`: accessible form field components (`textInput`, `textarea`, `checkbox`, `radioGroup`, `fileInput`, `fieldRow`) (#9).

### Changed (breaking)

- `Component.Footer.Family`: now only `view options footerSettings`; content comes from configuration (family defaults in `packages/site-config/family.toml`). `viewWith`, `links`, `linksExcept`, `siteLabel`, `copyright`, `disclaimer` and `logo` are removed.
- `Component.Alert.view`: `onDismiss` is `Maybe { msg, label }`; `Component.Tag.view`: `onRemove` is `Maybe { msg, label }`. The label is the button's accessible name, which the components used to hard-code in Finnish.
- `Component.Layout`: `Config` gains `showHeader`; the footer links to a site's other languages. `SiteSettings` gains `languages`.
- Components no longer contain display text; callers pass it (from `UiStrings`): `MobileDrawer.view` takes `closeLabel`, `Toast.view` takes `closeLabel`, `Toast.viewToast` takes the close label as its first argument, `Dialog.view` takes `closeLabel`, `Pagination.view` takes `labels`, `Breadcrumb.view` takes the landmark label as its first argument, `LogoCard.view` takes the "recommended" badge text as its first argument.

### Fixed

- `ui-components.css`: safelist the `space-y-*` classes that `TailwindExtra.space_y` builds at runtime; they were missing from app production CSS unless the app happened to use the same class itself. `script/check-safelist.mjs` (run by `make check` and the Downstream workflow) keeps the list complete.
- `Component.Footer`: the brand layout matches the family reference footer (kalenteri.palikkaharrastajat.fi): 12px uppercase label, 14px links in two columns from `sm` up (one column below), 12px legal text (#6).
- `Component.Footer.Family`: `links` no longer lists `planeetta.palikkaharrastajat.fi`, which is not a family site (#6).
- `Component.FeedLinks`: a single panel (feeds only, no cards) spans the full width instead of one third (#12).
- `Component.Form`: text inputs, textareas, file inputs and checkboxes use `border-border-brand` instead of `border-border-default`, whose 1.2:1 contrast against the page background failed WCAG 1.4.11 (#9).

## [2.0.0]

### Changed

- **BREAKING:** `1602/elm-feather` 2.3.5 <= v < 3.0.0 replaces `feathericons/elm-feather`; apps must depend on `1602/elm-feather` (#2).
- **BREAKING:** `Component.MobileDrawer.view` now requires a `label` field (e150ad8). Callers must supply an accessible label.

### Added

- `ui-components.css`: shared stylesheet exporting `@source` paths and dynamic class safelist for UI components (#2).

## [1.0.0]

- Initial release.

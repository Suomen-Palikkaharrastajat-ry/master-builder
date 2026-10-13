# Site configuration (`config.toml`)

Every site in the family — the content sites built by this hub and the
dedicated apps — describes itself in one `config.toml`. The file is layered on
the family defaults in `packages/site-config/family.toml` and resolved by
`packages/site-config/site-config.mjs` into one complete configuration per
language.

## Minimal file

```toml
[site]
url         = "https://kalenteri.palikkaharrastajat.fi"
title       = "Palikkakalenteri"
description = "Suomen Palikkaharrastajat ry:n tapahtumakalenteri"

[navbar]
variant = "app"
```

Everything else (icons, PWA, branding, footer label, links, copyright and
disclaimer) comes from the family defaults. A site that defines no footer links
of its own shows the canonical family links without the link to itself.

## Languages

```toml
[i18n]
default   = "fi"
languages = ["fi", "en"]

[site]
url         = "https://kalenteri.palikkaharrastajat.fi"
title       = "Palikkakalenteri"
description = "Tapahtumakalenteri"

[site.en]
title       = "Brick Calendar"
description = "Event calendar"
```

- A file without `[i18n]` is a Finnish-only site.
- Text in the **default language** sits directly in the section.
- Text in **another language** sits in a sub-table named after it
  (`[site.en]`, `[footer.en]`).
- **Language-neutral** keys (URLs, paths, colours, flags) only ever sit directly
  in the section.

The build fails, listing every problem, when

- a language table is not listed in `[i18n] languages`, or is the default language;
- a language-neutral key sits in a language table, or a key is unknown;
- text the site sets for its default language is missing for another language
  (there is no silent fallback);
- a translated link list has other targets, or another order, than the default one.

Which keys are translatable is declared once, in `SCHEMA` in `site-config.mjs`.

`{year}` in `[footer] copyright` is replaced with the build year.

Nested tables (`[pwa.icons]`, `[app.strings]`) are merged key by key, so a site
overrides single values without repeating the rest.

## App settings

`[app]` is free-form and belongs to the app: language-neutral settings directly
in it, per-language overrides in `[app.<lang>]`. A table a language overrides
(`[app.en.strings]`) must contain every key of the default one; there is no
silent fallback there either. Decode it in Elm with
`SiteSettings.appDecoder`.

## Using the configuration

| Where | How |
|---|---|
| Hub (elm-pages) | `Config.task` (a `BackendTask`) |
| App build (Vite) | `packages/site-config/vite.mjs`: generates the document head and `site.webmanifest`, and provides `virtual:site-config` |
| App (Elm) | pass `virtual:site-config` as a flag; decode with `SiteSettings.localizedDecoder`, pick a language with `SiteSettings.forLang` |
| App (JavaScript) | `packages/site-config/browser.mjs`: `requestedLang`, `pickLang`, `appSettings`, `showLanguage` (sets the `lang` attribute and rewrites the head's description and social tags, which the static page carries in the default language) |
| Static generators (Haskell) | `packages/site-config/gen-haskell.mjs` writes a `SiteConfig` module: site URL, title, description, organisation, month and weekday names (from `locales.json`, the table the Elm `Locale` is tested against) and every string in `[app]` and `[app.statics]`, per language |
| Elm tests | `packages/site-config/gen-fixture.mjs` writes the resolved config as an Elm string, so tests render the app's real configuration |
| Anything else | `node packages/site-config/cli.mjs config.toml` prints the resolved JSON |

## In an app repository

- `config.toml` sits at the repository root.
- `make site-config` regenerates the files derived from it (the Elm test
  fixture and, where there is a Haskell generator, `statics/src/SiteConfig.hs`).
  They are committed.
- `make site-config-check` (part of `make elm-check`) fails when they are out
  of date or when display text sits outside translations.
- Text the JavaScript or the Haskell generators render goes in `[app]`,
  `[app.strings]` or `[app.statics]`, with per-language overrides in `[app.<lang>]`.
- A visitor switches language with `?lang=<code>`; the choice is remembered. A
  language the site does not declare is ignored.

## Layout and language

Every site renders its chrome with `Component.Layout.view`, giving it the
resolved `SiteSettings` and `UiStrings.forLang lang`. Views contain no display
text of their own:

| Kind of text | Home |
|---|---|
| Layout labels ("Avaa valikko", "Sulje") | `UiStrings` in `packages/ui-components` |
| Site content (title, footer, link labels) | `config.toml` |
| App feature text | the app's `I18n.elm`, `t : Lang -> MsgKey -> String` |
| Dates and times | a `Locale` (`packages/app-toolkit`), passed to `FinnishTime` and the date picker |

`script/check-i18n.mjs` fails when a string literal with Finnish letters or
common Finnish interface words appears outside a translation module; it runs in `make check` and in the
Downstream workflow.

## Adding a language

1. Add it to `Lang`, `UiStrings.forLang`, `Locale.forCode` and to
   `SUPPORTED_LANGUAGES` in `site-config.mjs`.
2. Translate the family defaults: add `[<section>.<lang>]` tables to `family.toml`.
3. In the site: list it in `[i18n] languages` and translate what the site sets itself.

# Repo-family conventions

Shared conventions for the Suomen Palikkaharrastajat ry repositories. This is the
canonical reference; individual repos link here instead of re-documenting these
rules. Starter files live in [`templates/`](templates/).

The family — which repositories belong to it, how each depends on this hub,
which hub commit it is on and what it needs at runtime — is described in
[`family.md`](family.md).

## Canonical sources (what lives where)

| Concern | Canonical home |
|---|---|
| Design tokens (machine) | `design-guide/content/*.toml` → generated into `master-builder/packages/design-tokens/` |
| Design tokens CSS | `packages/design-tokens/design-tokens.css` (generated from `design-guide/dist/design-tokens.css`) |
| Shared component styles & safelist | `packages/ui-components/ui-components.css` |
| Brand font (Outfit files, `@font-face`, OFL) | `master-builder/public/fonts/`, served to apps by `packages/site-config/vite.mjs` |
| Design system (prose: colors, typography, logos, WCAG) | `master-builder/AGENTS.md` → "Design system" |
| LEGO color catalog (reference) | `design-guide/reference/allowed-colors.csv` |
| Shared Elm UI components | `master-builder/packages/ui-components/` |
| Shared Finnish date picker | `master-builder/packages/finnish-datepicker/` |
| Shared Elm app plumbing (FinnishTime, PocketBaseAuth, MapOverlay, Geocoding, MapWidget, Icons) | `master-builder/packages/app-toolkit/` |
| Shared Haskell statics modules (DescriptionHtml, ImageFetcher) | `master-builder/packages-hs/statics-common/` |
| Shared elm-review LlmAgent rules | `master-builder/review/src/LlmAgent/` |
| Shared npm-tools Nix builder | `master-builder/pkgs/mk-npm-tools.nix` |
| CI Nix setup (composite action) | `master-builder/.github/actions/setup-nix/` |
| CI native frontend build (composite action) | `master-builder/.github/actions/build-frontend/` |
| Reusable content deploy workflow | `master-builder/.github/workflows/deploy-content.yml` |

Apps consume all of the above through the pinned `vendor/master-builder` submodule
(+ the `elm-app/packages` symlink for Elm). Bump the pin deliberately with
`git submodule update --remote vendor/master-builder`.

## nixpkgs & devenv

- `devenv.yaml`: pin nothing in the URL — use `url: github:nixos/nixpkgs`
  (lowercase). Reproducibility comes from the committed `devenv.lock`.
- **All family repos share one `devenv.lock` revision.** Bump them together, never
  one at a time: a repo on its own nixpkgs revision cannot reuse the shared cachix
  cache, and divergence is how you end up with one repo's CI failing to evaluate
  while its siblings are green. Run `devenv update` in one repo, then copy the
  resulting `devenv.lock` to the others.
- Toolchain baseline: **GHC 9.6**, **nodejs_22**, `profile: shell`.
- devenv.nix defines `shell` and (for apps) a `ci` profile, wired as
  `profiles.<name>.module = { imports = [ … ]; }`. The bare `profiles.<name> = …`
  form does not work with devenv v2.1.2.
- **Do not apply overlays in the `ci` profile.** An overlay re-instantiates the
  whole package set, so every derivation hash changes and CI can no longer pull
  from the shared cachix cache. Repo-local package pins (PocketBase versions and
  the like) belong in the `shell` profile only. Haskell overrides are different —
  they go through `overrides.nix` / `hpkgsFor`, which only touches the Haskell set.
- The `ci` profile puts the Nix-built generator binary on `PATH` so `make dist-ci`
  never compiles Haskell; it also needs `elm-review` and `elm-json` because CI
  runs `make check`.
- CI installs devenv **v2.1.2** via the shared `setup-nix` composite action.

## Makefile vocabulary

Every tooling repo's Makefile is self-documenting (`## ` help comments, `help`
target first). Standard target names:

| Target | Meaning |
|---|---|
| `help` | List targets (default) |
| `vendor` | Init/update submodules (+ CI git@→https rewrite) |
| `shell` | Enter devenv shell |
| `build` | Production build of the app/artifact |
| `dist` / `dist-ci` / `dist-local` | Assemble deployable output → `dist/` |
| `check` | Lint/format validation (no changes) |
| `format` | Auto-format all code |
| `test` | Run all tests |
| `clean` | Remove build artifacts |

Apps namespace language-specific targets: `elm-*` (elm-build, elm-check,
elm-review, elm-test, elm-format) and `statics-*` (statics-build, statics-test,
statics-check, statics-format — the Haskell generator).

`check` and `test` are siblings, not a chain: `test: elm-test statics-test` and
`check: elm-check statics-check`. CI runs both as separate steps so a lint
failure and a test failure are distinguishable in the job log.

## Cabal invocations

The repo root holds `cabal.project`, not a package — `packages: statics/` means
the root is **not** a package directory. Always name the target explicitly:

```sh
cabal build statics          # not: cabal build
cabal test statics-test      # not: cabal test
cabal install statics …      # not: cabal install
cd statics && cabal check    # cabal check has no target argument
```

A bare invocation fails with `[Cabal-7134] No targets given and there is no
package in the current directory`. This is the single most common way these
repos break after the Haskell sources move under `statics/`.

## CI checkouts

Any job that reads `cabal.project` needs the shared `statics-common` package from
the submodule, so its checkout must request submodules:

```yaml
- uses: actions/checkout@v4
  with:
    submodules: true
```

This applies to the `build-update-binary` job as much as to `build` — it is easy
to miss because the job fails only at link time.

## Vite inside devenv

`enterShell` points `node_modules` and `elm-app/node_modules` at the Nix store,
which is read-only. Vite's default config loader bundles `vite.config.mjs` into
`node_modules/.vite-temp/` first, so a plain `vite build` fails with
`ENOENT: … mkdir '…/node_modules/.vite-temp'`. Every build target therefore runs

```make
VITE_FLAGS ?= --configLoader runner
	cd elm-app && vite build $(VITE_FLAGS)
```

`runner` loads the config directly and never writes the temp file. The scheduled
workflows are unaffected — they use a real `pkgs/node_modules` directory — but
they inherit the flag harmlessly.

## Artifact directory

The deployable output directory is **`dist/`** everywhere (matches the Vite
default and the content pipeline). Do not use `build/`.

## Repository layout (apps)

```
statics/            Haskell static generator (src/, app/, tests/, *.cabal)
elm-app/            Elm 0.19 SPA (src/, tests/); Page/ and View/ for larger apps
elm-app/packages    → symlink to ../vendor/master-builder/packages
assets/             Files copied verbatim into dist/ (not the Haskell package)
fixtures/           PocketBase migrations, Keycloak realm (backend apps)
pkgs/               npm-tools.nix (thin wrapper) + package.json / package-lock.json
review/             elm-review config sourcing shared rules from vendor/master-builder
vendor/master-builder  Pinned submodule (shared Elm/Haskell packages, CI tooling)
```

`elm-app/packages` is a **committed** symlink (`git add -f` it — the `.gitignore`
must not cover it). Do not generate it from `make vendor`: elm-review and the
Vite build both resolve it before any make target has necessarily run.

Note the deliberate split: **`statics/`** is the Haskell package directory;
**`assets/`** is the verbatim-copied asset directory. Do not reintroduce a
`static/` directory (it collides visually with `statics/`).

## elm-review

Apps and design-guide run the shared LlmAgent rules from
`master-builder/review/src/LlmAgent/` (NoTailwindRawStrings, RequireModuleDoc,
RequireTypeAnnotation, NoExposingEverything; NoDebug and NoInlineStyleAttribute
are available too) — rules tuned to keep generated code legible to LLM coding
agents. Each app's `review/src/LlmAgent` is a symlink to the hub's, and its
`ReviewConfig.elm` picks the rules it runs. `make elm-check` runs `elm-format --validate` +
`elm-review`.

## Changing shared package APIs

Shared packages (`packages/ui-components`, `app-toolkit`, `design-tokens`,
`finnish-datepicker`, `osm-opening-hours`, `packages-hs/statics-common`) are consumed by every app
repo, so API changes follow SemVer with Elm's `elm diff` rules. Notably, adding
a field to a record argument (e.g. `Button.view`'s config) is a **MAJOR**
change, because every caller constructs that record.

**Prefer additive changes.** Do not add a field to an existing `view` record.
Instead use one of:

- **Option A — builder (recommended for new or heavily-optioned components):**

  ```elm
  Button.new { label = "Tallenna", onClick = Save }
      |> Button.withVariant Button.Primary
      |> Button.withIcon FeatherIcons.save
      |> Button.asSubmit
      |> Button.toHtml
  ```

  Options are opaque, so adding one is a MINOR change.

- **Option B — `viewWith`:** keep `view` unchanged and add
  `viewWith : Options -> Config msg -> Html msg` plus `defaultOptions`.

**Process rules**

- A MAJOR change must be merged together with (or after) PRs that fix every
  app. The `downstream` workflow must be green, or red only for apps with an
  open, linked fix PR.
- Every PR touching `packages/` (or `packages-hs/`) updates the relevant
  `CHANGELOG.md` under "Unreleased" (Keep a Changelog format).
- Apps record the hub version they are on in their own CHANGELOG or commit
  message when moving the `vendor/master-builder` pin.

The `downstream` workflow (`.github/workflows/downstream.yml`) compiles every
app (event-calendar, planet, service-map and competitions) against hub changes to `packages/`,
`packages-hs/`, `review/`, `pkgs/` and `.github/actions/`, by replacing each
app's pinned `vendor/master-builder` with the commit under test. A red
`downstream` job means an app needs a matching change before the hub change is
merged (see the policy above). It runs `make elm-build`, `make elm-test` and,
for apps using `statics-common`, `make statics-build`; it does not run
`make check` yet. `check-i18n` scans `elm-app/src elm-app/main.js statics/src statics/app` in
every app and skips the paths an app does not have.

## Consuming shared Elm packages

Apps compile the shared packages as **source directories**, not through the Elm
package registry, so a package's declared `dependencies` are not enforced by
the compiler. The contract is therefore:

- List every needed `packages/*/src` directory in the app's
  `source-directories`, and include **each package's dependencies** (see its
  `elm.json`) in the app's own `elm.json`, within the declared ranges.
  `node script/check-consumer-deps.mjs <path/to/app/elm.json>` verifies this
  (the `downstream` workflow runs it).
- `elm-tailwind-classes` must be exactly the version in
  `pkgs/package.json` (currently `0.6.1`). Apps run `elm-tailwind-classes gen`
  before compiling, which generates the `Tailwind*` modules the components
  import. Because of these generated imports, `ui-components` cannot be built
  standalone with `elm make --docs`; verify it with an app build instead.
- Feather icons: **`1602/elm-feather` 2.x** (module `FeatherIcons`) everywhere.
  Do not use `feathericons/elm-feather`.
- Shared CSS and safelists: apps should `@import` the tokens and component CSS
  rather than hand-copying `@theme` blocks:

  ```css
  @import "tailwindcss";
  @import "./vendor/master-builder/packages/design-tokens/design-tokens.css";
  @import "./vendor/master-builder/packages/ui-components/ui-components.css";
  @import "./vendor/master-builder/public/fonts/outfit.css";
  @source "./src";
  ```

  The font import path above is for a CSS file at the app root; from
  `elm-app/main.css` it is `../vendor/master-builder/public/fonts/outfit.css`.
  Apps keep no font files or `@font-face` of their own.

  Each app build logs two expected Vite warnings, that
  `/fonts/Outfit-VariableFont_wght.woff2` and `.ttf` "didn't resolve at build
  time, it will remain unchanged to be resolved at runtime". The app's `public/`
  has no `fonts/`; the site-config plugin copies the hub's into `dist/fonts`
  after the bundle. The absolute URLs are deliberate (the static pages link
  `/fonts/outfit.css` too), so do not switch to relative URLs to silence them.

## Site layout, configuration and language

Every site describes itself in `config.toml` and renders its chrome with
`Component.Layout.view`; see [site-config.md](site-config.md). In short:

- Do not assemble header, drawer or footer in a site. Pass the site's resolved
  `SiteSettings`, `UiStrings.forLang lang` and the parts that differ to the shell.
- The footer is `Component.Footer.Family.view`, fed from configuration. Its
  content (label, links, copyright, disclaimer) is the family default in
  `packages/site-config/family.toml` unless the site's `[footer]` overrides it.
- Views contain no display text. Layout labels live in `UiStrings`, site content
  in `config.toml`, feature text in the site's `I18n.elm` (`t : Lang -> …`), and
  dates go through a `Locale`. `script/check-i18n.mjs` enforces this.

The footer's reference look is kalenteri.palikkaharrastajat.fi: 12px uppercase
label, 14px links in two columns (one below `sm`), 12px legal text.
`tests/FooterTest.elm` pins layout and typography, `tests/LayoutTest.elm` the
shell, and `packages/site-config/site-config.test.mjs` the canonical link list.
Change them in the hub and bump the pins; do not restyle them in an app.

## Commit style

Conventional Commits (`feat:`, `fix:`, `chore:`, `ci:`, `docs:`, …) in every
repo, including the content repos. AGENTS.md files carry the per-repo git rules.

## Licensing

No repo currently ships a LICENSE. Recommendation (pending the association's
decision): MIT for the code repos, CC BY 4.0 for the content repos. The LEGO
trademark disclaimer stays in each site's `config.toml` footer.

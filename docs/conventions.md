# Repo-family conventions

Shared conventions for the Suomen Palikkaharrastajat ry repositories. This is the
canonical reference; individual repos link here instead of re-documenting these
rules. Starter files live in [`templates/`](templates/).

The family:

- **bricklayer** (Haskell) — LEGO-style logo asset generator.
- **design-guide** (Haskell) — design-token pipeline (TOML → W3C tokens JSON + Elm package).
- **master-builder** (elm-pages) — site-builder pipeline, shared Elm packages, shared CI tooling. **This repo is the hub** — it is vendored as a submodule by every app and checked out by every content build, so shared code and docs travel with it.
- **logo / website / guides** — content-only repos built by master-builder at CI.
- **planet / event-calendar / service-map** — standalone apps: Haskell static generator + Elm SPA using master-builder's Elm packages.

## Canonical sources (what lives where)

| Concern | Canonical home |
|---|---|
| Design tokens (machine) | `design-guide/content/*.toml` → generated into `master-builder/packages/design-tokens/` |
| Design system (prose: colors, typography, logos, WCAG) | `master-builder/AGENTS.md` → "Design system" |
| LEGO color catalog (reference) | `design-guide/reference/allowed-colors.csv` |
| Shared Elm UI components | `master-builder/packages/ui-components/` |
| Shared Elm app plumbing (Geocoding, MapWidget, Icons) | `master-builder/packages/app-toolkit/` |
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
RequireTypeAnnotation, NoExposingEverything) — rules tuned to keep generated code
legible to LLM coding agents. `make elm-check` runs `elm-format --validate` +
`elm-review`.

## Commit style

Conventional Commits (`feat:`, `fix:`, `chore:`, `ci:`, `docs:`, …) in every
repo, including the content repos. AGENTS.md files carry the per-repo git rules.

## Licensing

No repo currently ships a LICENSE. Recommendation (pending the association's
decision): MIT for the code repos, CC BY 4.0 for the content repos. The LEGO
trademark disclaimer stays in each site's `config.toml` footer.

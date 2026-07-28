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
| Reusable content deploy workflow | `master-builder/.github/workflows/deploy-content.yml` |

Apps consume all of the above through the pinned `vendor/master-builder` submodule
(+ the `elm-app/packages` symlink for Elm). Bump the pin deliberately with
`git submodule update --remote vendor/master-builder`.

## nixpkgs & devenv

- `devenv.yaml`: pin nothing in the URL — use `url: github:nixos/nixpkgs`
  (lowercase). Reproducibility comes from the committed `devenv.lock`.
- Update deliberately with `devenv update`; commit the resulting `devenv.lock`.
- Toolchain baseline: **GHC 9.6**, **nodejs_22**, `profile: shell`.
- devenv.nix defines `shell` and (for apps) `ci` profiles; `imports = [ shell ]`.
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
elm-review, elm-test, elm-format) and `statics-*` (Haskell generator).

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

# Palikkaharrastajat Site

Static site generator for [Suomen Palikkaharrastajat ry](https://palikkaharrastajat.fi).
Built with [elm-pages](https://elm-pages.com), Elm 0.19.1, and Tailwind CSS v4.

## Architecture

**Dual-repo design.** This repository contains the **site code**: Elm routes, a 33-component UI library, design tokens, and the build system. The actual page **content** (Markdown files with YAML frontmatter) lives in a separate content repository.

At build time, `deploy/fetch-content.sh` clones the content repo into the workspace before `elm-pages build` runs. For local development you can use the bundled `template/` directory or point at a local `content/` checkout.

```
┌──────────────────────┐          ┌──────────────────────┐
│   Code repo (this)   │  build   │    Content repo       │
│  ─────────────────── │ ──────►  │  ─────────────────── │
│  app/  (Elm routes)  │  pulls   │  *.md pages           │
│  src/  (components)  │  content │  public/ (assets)     │
│  style.css           │          │  .github/ (pipeline)  │
│  deploy/             │          │                       │
└──────────────────────┘          └──────────────────────┘
```

## Prerequisites

- [devenv](https://devenv.sh) (recommended) — provides Elm, Node.js, elm-pages, and all build tools in a reproducible Nix shell
- Or manually: Node.js 22+, Elm 0.19.1, elm-pages CLI

## Quick start

```bash
# Enter the development shell (installs all tools)
devenv shell

# Start dev server with bundled example content
make dev

# Start dev server with content/ directory
make watch
```

## Content repo requirements

The content repo must contain Markdown files at the root with YAML frontmatter:

```yaml
---
title: "Page Title"
description: "SEO description"
published: true
nav: true           # Include in site navigation (default: false)
navTitle: "Short"   # Optional shorter label for nav (default: title)
order: 1            # Navigation sort order (default: 999)
---

Page body in Markdown…
```

- `index.md` → renders at `/`
- Any other `<slug>.md` → renders at `/<slug>`
- `blog/<slug>.md` → renders at `/blog/<slug>`
- Slugs are always inferred from the filename/path; `slug` in frontmatter is ignored.

### Static assets

Content-specific images and files can be placed in `content/public/`. They are merged into `public/` at build time via `make sync-assets`.

## Configuration

### Repository variables (Settings → Actions → Variables)

| Variable | Required | Description |
|---|---|---|
| `CONTENT_OWNER` | No | GitHub owner of the content repo |
| `CONTENT_REPO` | No | GitHub repo name |
| `CONTENT_REF` | No | Branch/tag/SHA (default: `main`) |
| `OAUTH_CLIENT_ID` | No | GitHub OAuth App client ID for admin editor |

### Repository secrets (Settings → Actions → Secrets)

| Secret | Required | Description |
|---|---|---|
| `CONTENT_PAT` | Only for private content repos | PAT with `repo` scope |

## Development

| Command | Description |
|---|---|
| `devenv shell -- make dev` | Dev server using `template/` |
| `devenv shell -- make watch` | Dev server using `content/` |
| `devenv shell -- make build` | Production build to `dist/` |
| `devenv shell -- make check` | Validate elm-format + elm-review |
| `devenv shell -- make format` | Auto-format Elm sources |
| `devenv shell -- make design-tokens` | Regenerate tokens from TOML |

## Building & deployment

```bash
# Build (fetches external content if configured)
devenv shell -- make build

# Deploy (push to main triggers CI)
devenv shell -- make deploy
```

The CI pipeline:
1. Restores caches (npm, Elm, elm-pages)
2. Runs `deploy/fetch-content.sh`
3. Injects build metadata via `deploy/inject-build-meta.sh`
4. Builds with `elm-pages build`
5. Deploys `dist/` to GitHub Pages
6. Runs `deploy/smoke-test.sh`

## Design system

Colors, typography, spacing, and motion tokens are defined in `style.css` as Tailwind v4 `@theme` custom properties. The canonical reference is at [logo.palikkaharrastajat.fi](https://logo.palikkaharrastajat.fi/).

Design tokens are generated from TOML sources in `vendor/design-guide/` and vendored as typed Elm modules in `vendor/design-tokens/`.

### Vendored packages / local packages

The project keeps two internal Elm packages with shared UI and tokens:

- `vendor/design-tokens/` (generated, committed) — typed design tokens as an Elm package.
- `vendor/ui-components/` (vendored component library) — the `Component.*` modules exposed as an Elm package.

If you prefer a `./packages/` workspace layout (monorepo packages folder), you may place or symlink these packages under `./packages/design-tokens` and `./packages/ui-components` — the build only requires their `src/` directories to be reachable via `elm.json` `source-directories`. The repository currently exposes these packages from `vendor/` by default.

## Project structure

```
app/                Elm page routes (Index, Slug_, Blog/Slug_)
src/                Shared modules (MarkdownRenderer, Frontmatter, TailwindTokens)
vendor/ui-components/ or packages/ui-components/  34 UI components exposed as a vendored Elm package (Component.*)
vendor/design-guide/  Git submodule — Haskell token pipeline (TOML → Elm)
vendor/design-tokens/ or packages/design-tokens/ Generated Elm package (committed to git)
content/            Content repo mount point
template/           Bundled example content
public/             Static assets (logos, favicons, fonts)
deploy/             CI/CD scripts (fetch-content, inject-build-meta, smoke-test)
script/             Elm code generation tool (AddRoute, AddStaticRoute)
review/             elm-review config with 4 LLM-optimised rules
admin-app/          Standalone SPA — browser-based content editor (future)
style.css           Tailwind v4 @theme with design tokens
```

## Admin editor (future)

The `admin-app/` directory contains a standalone SPA for in-browser Markdown editing via the GitHub API. It reads and writes files in the content repo. This feature is not yet wired into the main site.

## License

See individual files for licensing information.

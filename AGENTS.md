# Agent Instructions

## Build commands

All build commands must be run inside the devenv shell:

```
devenv shell -- make dev
devenv shell -- make watch
devenv shell -- make build
devenv shell -- make check
devenv shell -- make format
devenv shell -- make design-tokens
devenv shell -- elm-json install <package>
```

Do **not** use `npx`, bare `elm`, or bare `elm-pages` — they are not on PATH outside devenv.

## Project overview

Static site generator for Suomen Palikkaharrastajat ry (Finnish LEGO enthusiast org).
Built with **elm-pages 11**, **Elm 0.19.1**, and **Tailwind CSS v4**.

**Dual-repo architecture**: this repo holds Elm routes, UI components, build system, and design tokens.
A separate **content repo** holds Markdown pages with YAML frontmatter, fetched at build time
by `deploy/fetch-content.sh`. Local development uses `template/` (bundled example content) or
`content/` (external content repo clone).

## Key directories

| Directory | Purpose |
|---|---|
| `app/` | elm-pages routes (`Route/Index.elm`, `Route/Slug_.elm`, `Route/Blog/Slug_.elm`) |
| `src/` | Shared modules: `MarkdownRenderer`, `Frontmatter`, `ContentDir`, `SiteMeta`, `TailwindTokens`, `TailwindExtra` |
| `src/Component/` | 33 UI components (Accordion, Alert, Badge, Button, Card, Dialog, Hero, etc.) |
| `vendor/design-guide/` | Git submodule — Haskell pipeline: TOML → W3C Design Tokens JSON + typed Elm package |
| `vendor/design-tokens/` | Generated Elm package (`DesignTokens.*` modules), committed to git |
| `content/` | Content repo mount point (Markdown + static assets). Has its own git repo in production |
| `content/reference/` | Previous design-guide site (elm-pages app) — kept as reference for component implementations |
| `template/` | Bundled example content for `make dev` |
| `public/` | Static assets: logos, favicons, fonts, robots.txt, site-config.json |
| `script/` | Elm code generation tool (AddRoute, AddStaticRoute) with its own `elm.json` |
| `deploy/` | CI/CD shell scripts: `fetch-content.sh`, `inject-build-meta.sh`, `patch-tailwind-resolver.mjs`, `smoke-test.sh` |
| `review/` | elm-review config with 4 LLM-optimised rules |
| `admin-app/` | Standalone SPA — browser-based content editor via GitHub API (not wired up yet) |

## Makefile targets

| Target | Description |
|---|---|
| `make dev` | Start dev server using `template/` |
| `make watch` | Start dev server using `content/` |
| `make build` | Production build to `dist/` |
| `make check` | Validate elm-format + elm-review (no changes) |
| `make format` | Auto-format Elm sources |
| `make fetch-content` | Sync content from external repo (set `CONTENT_OWNER`, `CONTENT_REPO`) |
| `make sync-assets` | Copy non-markdown content assets to `public/` |
| `make clean` | Remove build artifacts |
| `make vendor` | Init/update git submodules |
| `make design-tokens` | Regenerate tokens from `vendor/design-guide/content/*.toml` |
| `make deploy` | Push to main (triggers CI) |
| `make test` | Run smoke test against `SITE_URL` |

## Design tokens

`vendor/design-guide/` is a git submodule containing a Haskell pipeline that generates
W3C Design Tokens (2025.10) JSON and a typed Elm package from 9 TOML source files.

The generated Elm package is vendored into `vendor/design-tokens/` and committed to git,
so daily builds do **not** require the submodule to be checked out or built.

### Token modules

| Module | Contents |
|---|---|
| `DesignTokens.Colors` | Brand (3), skin-tones (4), rainbow (7), semantic (11) |
| `DesignTokens.Typography` | Font family, 10 type scale entries |
| `DesignTokens.Spacing` | Base unit, 8 scale steps, 4 breakpoints, border radii |
| `DesignTokens.Motion` | 3 durations, 3 easings |
| `DesignTokens.Effects` | 6 box shadows, 6 z-index layers |
| `DesignTokens.Accessibility` | 3 focus ring tokens |
| `DesignTokens.Opacity` | 9-step opacity scale |
| `DesignTokens.Components` | 25+ component token mappings |

To regenerate after editing TOML:

```bash
devenv shell -- make design-tokens
```

### Token usage in Elm

Components access design tokens through `TailwindTokens` (semantic color wrapper) and
`TailwindExtra` (Tailwind class helpers). Never import `DesignTokens.*` directly in components.

```elm
import TailwindTokens as TC
import TailwindExtra as TwEx

classes [ Tw.bg_simple TC.brand, Tw.text_simple TC.textOnDark ]
```

## Component library

33 components in `src/Component/`, imported as `Component.*`:

```elm
import Component.Card as Card
import Component.Alert as Alert
import Component.Hero as Hero
```

Reference implementations from the previous design-guide site are in `content/reference/src/Component/`.

### Markdown embedding

Components are available in Markdown via custom HTML tags in `src/MarkdownRenderer.elm`:

```markdown
<callout type="info">Information message</callout>
<hero title="Title" subtitle="Subtitle">CTA buttons</hero>
<card title="Card Title">Card body</card>
<accordion><accordion-item summary="Q">Answer</accordion-item></accordion>
```

## Content architecture

Content pages are Markdown files with YAML frontmatter:

```yaml
---
title: "Page Title"
description: "SEO description"
slug: page-slug
published: true
nav: true           # Show in navigation (default: false)
navTitle: "Nav"     # Optional shorter nav label
order: 1            # Nav sort order (default: 999)
---
```

- `app/Route/Index.elm` renders `index.md`
- `app/Route/Slug_.elm` renders all other `.md` files as `/:slug`
- `app/Shared.elm` builds navigation from pages with `nav: true`, sorted by `order`

## elm-review

Four custom rules in `review/src/LlmAgent/` enforce LLM-friendly code:

| Rule | Purpose |
|---|---|
| `NoTailwindRawStrings` | Enforce typed token imports over raw class strings |
| `RequireModuleDoc` | Mandatory `{-\| ... -}` module documentation |
| `RequireTypeAnnotation` | Type signatures on all top-level values |
| `NoExposingEverything` | Explicit export lists, no `exposing (..)` |

Run: `devenv shell -- make check`

## Design system

**CSS reference:** Fetch `https://logo.palikkaharrastajat.fi/brand.css` for the canonical
`@theme`, `@utility type-*`, `@font-face`, and reduced-motion rule.

**Human-readable:** https://logo.palikkaharrastajat.fi/
**Machine-readable (JSON-LD):** https://logo.palikkaharrastajat.fi/design-guide/index.jsonld

### Color tokens

Use semantic Tailwind classes from `style.css` — never hardcode hex values:

| Semantic class | Value | Usage |
|---|---|---|
| `bg-brand` / `text-brand` | `#05131D` | Primary dark |
| `text-text-on-dark` | `#FFFFFF` | Text on dark surfaces |
| `text-text-muted` | `#6B7280` | Secondary labels |
| `text-text-subtle` | `#9CA3AF` | Placeholders, captions |
| `bg-bg-page` | `#FFFFFF` | Page background |
| `bg-bg-subtle` | `#F9FAFB` | Card/panel backgrounds |
| `bg-brand-yellow` | `#FAC80A` | Accent/CTA backgrounds |
| `border-border-default` | `#E5E7EB` | Default borders |
| `border-border-brand` | `#05131D` | Brand borders |
| `text-brand-red` | `#C91A09` | Error/danger states |

All colour usage must pass WCAG AA contrast.

### Typography

Font: **Outfit variable** (100–900), self-hosted from `public/fonts/`. Never substitute.
Use `type-*` utility classes from `style.css`. Never use raw Tailwind size/weight combos.

| Class | Size | Weight | Notes |
|---|---|---|---|
| `type-display` | 3rem | 700 | Hero headlines only |
| `type-h1` | 1.875rem | 700 | One per page |
| `type-h2` | 1.5rem | 700 | Section headings |
| `type-h3` | 1.25rem | 600 | Sub-section headings |
| `type-h4` | 1.125rem | 600 | Card/widget headings |
| `type-body` | 1rem | 400 | Default body copy |
| `type-body-small` | 0.875rem | 500 | UI controls, labels |
| `type-caption` | 0.875rem | 400 | Metadata, footnotes |
| `type-mono` | 0.875rem | 400 | Code snippets (monospace) |
| `type-overline` | 0.75rem | 600 | Category labels (uppercase) |

### Layout

- Max content width: `max-w-5xl` (1024px)
- Horizontal padding: `px-4` (16px) on all screens
- Full wrapper: `max-w-5xl mx-auto px-4`
- Mobile-first: base styles for mobile, `sm:` / `md:` / `lg:` for overrides
- Minimum touch target: 44×44px

### Focus rings

Use `focus-visible:ring-2 focus-visible:ring-brand` on all interactive elements.
Do NOT use `focus:ring-*` (keyboard-only; no ring on mouse click).

### Logos

Self-hosted from `public/logo/`. SVG first; WebP with PNG fallback for raster.

- **Dark background** (nav): `/logo/horizontal/svg/horizontal-full-dark.svg`
- **Light background**: `/logo/horizontal/svg/horizontal-full.svg`
- **Square mark**: `/logo/square/svg/square-basic.svg`

Minimum clear space: 25% of logo width. Minimum size: 80px (square), 200px (horizontal).

## Git / commit rules

- Do **not** commit `TODO.md` (workspace-local planning file)
- `content/` is a separate repository; do not commit content changes to this repo
- `vendor/design-tokens/` IS committed (generated but vendored)
- `vendor/design-guide/` is a submodule — do not modify directly
- `dist/`, `elm-stuff/`, `.elm-pages/`, `.elm-tailwind/`, `gen/` are gitignored

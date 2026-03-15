# Palikkaharrastajat Site

Elm-pages static site for [Suomen Palikkaharrastajat ry](https://palikkaharrastajat.fi).
Built with [elm-pages](https://elm-pages.com) and Tailwind CSS v4.
Deployed to GitHub Pages via GitHub Actions.

## Architecture

This repository contains the **site code** — Elm routes, reusable UI components,
and the Tailwind design system. The actual page **content** (Markdown files) can
live either here or in a separate repository.

```
┌──────────────────────┐          ┌──────────────────────┐
│   Code repo (this)   │  build   │    Content repo       │
│  ─────────────────── │ ──────►  │  ─────────────────── │
│  app/  (Elm routes)  │  pulls   │  template/             │
│  src/  (components)  │  content │    index.md           │
│  style.css           │          │    about.md           │
│  scripts/            │          │    blog/hello.md      │
└──────────────────────┘          └──────────────────────┘
```

At build time `scripts/fetch-content.sh` clones the content repo and copies its
`template/` directory into this workspace before `elm-pages build` runs.

The in-browser admin editor (at `/admin`) also points at the content repo so
edits are committed there, not here.

## Content repo structure

The content repo must have a `template/` directory with Markdown files:

```
template/
  index.md          ← home page
  about.md          ← /about route
  blog/
    hello.md        ← /blog/hello route
  <slug>.md         ← any additional /‹slug› routes
```

Each file needs YAML frontmatter:

```markdown
---
title: Page title
description: Short description for meta tags
slug: page-slug
published: true
---

Page body in Markdown…
```

## Configuration

### Repository variables (Settings → Secrets and variables → Actions → Variables)

| Variable | Required | Description |
|---|---|---|
| `CONTENT_OWNER` | No | GitHub owner of the content repo (user or org). Defaults to this repo's owner. |
| `CONTENT_REPO` | No | GitHub repo name of the content repo. Defaults to this repo. |
| `CONTENT_REF` | No | Branch, tag, or SHA to check out. Defaults to `main`. |
| `OAUTH_CLIENT_ID` | No | GitHub OAuth App client ID for the admin editor. |

### Repository secrets (Settings → Secrets and variables → Actions → Secrets)

| Secret | Required | Description |
|---|---|---|
| `CONTENT_PAT` | Only for private content repos | Personal Access Token with `repo` scope, used to clone a private content repo during the build. |

### Typical setup for a separate public content repo

1. Create a new GitHub repository (e.g. `my-org/site-content`) with the
   `template/` directory structure described above.
2. In **this** repository go to **Settings → Secrets and variables → Actions**.
3. Add repository variables:
   - `CONTENT_OWNER` = `my-org`
   - `CONTENT_REPO` = `site-content`
4. Push to `main` — the CI pipeline will clone the content repo and build.

### Typical setup for a separate private content repo

Same as above, plus:

5. Create a [fine-grained PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
   with **Read access to contents** on the content repo.
6. Add a repository secret `CONTENT_PAT` = `<the token>`.

## Local development

### Prerequisites

- [Node.js](https://nodejs.org) 20+
- [devenv](https://devenv.sh) (optional, for the full Nix-based dev shell)

### Quick start

```bash
# Install JS dependencies
make install

# Dev server using the bundled example content in template/
make dev

# Dev server using a locally checked-out content repo in content/
make watch   # sets CONTENT_DIR=content automatically

# Dev server using any other directory
CONTENT_DIR=my-content npx elm-pages dev
```

The `CONTENT_DIR` environment variable controls which directory elm-pages reads
Markdown files from. It defaults to `template/` (the bundled example content).

### Devenv shell (full Nix environment)

```bash
make shell   # enter the devenv shell
make dev     # then start the dev server inside the shell
```

## Building

```bash
# Build into dist/ (fetches external content first if configured)
CONTENT_OWNER=my-org CONTENT_REPO=site-content make build

# Or, if env vars are set in your shell already
make build
```

The `build` target:
1. Runs `scripts/fetch-content.sh` — syncs content from the external repo into `template/` (no-op when not configured)
2. Runs `npx elm-pages build` — compiles Elm, bundles CSS, outputs to `dist/`

## Deployment

Push to `main` to trigger the GitHub Actions pipeline:

```bash
make deploy   # git push origin main
```

The pipeline:
1. Restores npm / Elm / elm-pages caches
2. Runs `scripts/fetch-content.sh` (using `CONTENT_OWNER`, `CONTENT_REPO`, `CONTENT_PAT`)
3. Injects build metadata into `public/site-config.json`
4. Builds the site with `npx elm-pages build`
5. Deploys `dist/` to GitHub Pages
6. Runs a smoke test to verify the deployment

## Admin / CMS

The `/admin` route provides an in-browser Markdown editor backed by the GitHub
API. It reads and writes files in the **content repo** (configured via
`site-config.json` at runtime).

To use the admin editor:

1. Navigate to `<your-site>/admin`
2. Enter a GitHub Personal Access Token with `repo` (private) or `public_repo`
   (public) scope for the content repo
3. Browse files, edit Markdown, and commit changes directly from the browser

When a commit is pushed to the content repo you can trigger a rebuild of this
site via the **Actions → Build and Deploy → Run workflow** button, or configure
a [repository dispatch](https://docs.github.com/en/rest/repos/repos#create-a-repository-dispatch-event)
webhook in the content repo to trigger the build automatically.

## Project structure

```
app/Route/          Elm page routes (Index, Slug_, Blog/Slug_, Admin)
src/Components/     Reusable Elm UI components (Hero, Card, Button, …)
src/               Frontmatter decoder, Markdown renderer
template/            Markdown content files (may be synced from external repo)
public/             Static assets (site-config.json, admin JS, favicon)
scripts/            Build helper scripts
style.css           Tailwind v4 @theme with brand design tokens
elm-pages.config.mjs elm-pages + Vite configuration
.github/workflows/  CI/CD pipeline
```

## Design system

Colors, typography, spacing, and motion tokens are defined in `style.css` as
Tailwind v4 `@theme` custom properties and documented in `AGENTS.md`.
Brand assets (logo, fonts) are served from `logo.palikkaharrastajat.fi`.

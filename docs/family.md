# The repository family

> Last verified: 2026-10-13. Run `make family-status` to refresh the
> [hub version status](#hub-version-status) table.

Suomen Palikkaharrastajat ry's sites and tools live in separate repositories
that share code, conventions and services through this repository,
**master-builder** (the hub). This page says what each repository is, how it
depends on the hub and on the others, and what it needs at runtime.
[`conventions.md`](conventions.md) says how the repositories are expected to be built;
this page records how they actually are, including where they deviate.

## Dependency graph

Solid arrows are build-time dependencies, dotted arrows runtime ones.

```mermaid
flowchart LR
  designguide[design-guide] -->|submodule + make design-tokens| hub[master-builder]
  hub -->|elm-review rules, cloned by make check| designguide

  hub -->|deploy-content.yml@main| website
  hub -->|deploy-content.yml@main| guides
  hub -->|deploy-content.yml@main| logo

  hub -->|submodule pin| eventcalendar[event-calendar]
  hub -->|submodule pin| servicemap[service-map]
  hub -->|submodule pin| planet
  hub -->|submodule pin| competitions
  hub -->|submodule pin| brickframe[brick-frame]
  hub -->|submodule pin| membershipcard[membership-card]

  pocketbase[(PocketBase data.palikkaharrastajat.fi)] -.->|runtime API| eventcalendar
  pocketbase -.->|runtime API| servicemap
  pocketbase -.->|events| brickbot
  keycloak[(Keycloak)] -.->|sign-in| eventcalendar
  keycloak -.->|sign-in| servicemap
  keycloak -.->|sign-in| membershipcard
  keycloak -.->|sign-in| competitions
  tiles[service-map-tiles] -.->|style.json and tiles| servicemap
  eventcalendar -.->|event edit pages| servicemap
  brickframe -.->|bricks-viewer script| hub
  emmet -.->|member accounts| keycloak
```

## Hub version status

Regenerate with `make family-status` (prints the table) or
`script/family-status.sh --update` (also rewrites it here). The script reads
each repository's `main` on GitHub, so it shows what is published, not local
work in progress.

> **2026-10-13:** the sections for event-calendar, service-map, planet, website
> and guides below describe them as of their move to the shared `config.toml`
> and layout (hub commit `a977711` and later). Until those branches are on
> their `main`, the table shows the older pins that GitHub has.

<!-- family-status:start -->
| Repo | Depends on hub via | Pinned commit | Commits behind main | Checked on |
|---|---|---|---|---|
| event-calendar | submodule `vendor/master-builder` | `ff12d3d` | 28 | 2026-10-13 |
| service-map | submodule `vendor/master-builder` | `3010555` | 25 | 2026-10-13 |
| planet | submodule `vendor/master-builder` | `2d1d5a3` | 19 | 2026-10-13 |
| competitions | submodule `vendor/master-builder` | `821ffef` | 95 | 2026-10-13 |
| brick-frame | submodule `vendor/master-builder` | `821ffef` | 95 | 2026-10-13 |
| membership-card | submodule `vendor/master-builder` | `821ffef` | 95 | 2026-10-13 |
| website | workflow `deploy-content.yml@main` | `main` (unpinned) | 0 (follows `main`) | 2026-10-13 |
| guides | workflow `deploy-content.yml@main` | `main` (unpinned) | 0 (follows `main`) | 2026-10-13 |
| logo | workflow `deploy-content.yml@main` | `main` (unpinned) | 0 (follows `main`) | 2026-10-13 |
<!-- family-status:end -->

Three ways of depending on the hub exist:

- **Submodule pin** (`vendor/master-builder`): the apps. A hub change reaches an
  app only when the app bumps its pin; `.github/workflows/downstream.yml`
  builds event-calendar's, service-map's, planet's and competitions' `main`
  against hub commits that touch shared code (it is path-filtered), so
  breakage is seen first. competitions is private: its job checks it out with
  the `DOWNSTREAM_READ_TOKEN` secret; it is skipped (green, without having
  checked anything) on fork PRs, and fails on push or manual runs when the
  secret is absent. Its build log is public like the rest of the hub's. The other submodule consumers
  are not in that matrix.
- **Reusable workflow** (`deploy-content.yml@main`): the content sites. They
  are **unpinned**: every hub merge changes those sites at their next deploy,
  so a breaking hub change reaches production through them first. Two ways to
  close that gap, neither implemented: (a) add the content builds to the
  Downstream matrix (build without deploying), which catches breakage before
  merge but still ships every hub change; or (b) tag hub releases and pin
  `deploy-content.yml@vX`, which makes updates deliberate at the cost of a
  bump per site per release.
- **Clone at check time**: design-guide clones the hub for its lint rules.

## Repositories

### master-builder (public)

- **Role:** the hub: elm-pages site builder for the content sites, the shared Elm and Haskell packages, the shared site configuration loader, and the CI tooling.
- **Published at:** https://demo.palikkaharrastajat.fi (GitHub Pages; the template content, last deployed in March 2026). Its main output is the three content sites it builds from their repositories: palikkaharrastajat.fi, oppaat.palikkaharrastajat.fi and logo.palikkaharrastajat.fi.
- **Stack:** Elm 0.19.1, elm-pages 3, Tailwind CSS 4, Vite 7, Node 22, Nix (devenv).
- **Provides:** `packages/ui-components` (components, `Component.Layout`, `SiteSettings`, `Lang`, `UiStrings`), `packages/design-tokens` (generated), `packages/app-toolkit` (`Locale`, `FinnishTime`, `Geocoding`, map views, `PocketBaseAuth`), `packages/finnish-datepicker`, `packages/osm-opening-hours`, `packages/site-config` (`config.toml` loader, family defaults, Vite plugin, generators), `packages-hs/statics-common`, `review/` (elm-review rules), `script/` (checks), `mk/site-config.mk`, `.github/actions/*`, `.github/workflows/deploy-content.yml`, `public/` (the family's icons, social image and logos).
- **Other upstreams:** design-guide (submodule `vendor/design-guide`, SSH URL in `.gitmodules`); brick-frame's viewer script, loaded at runtime from kehys.palikkaharrastajat.fi.
- **Runtime services:** none.
- **CI / deploy:** `downstream.yml` (builds the three apps against every hub commit); `deploy-content.yml` (reusable; called by the content repositories).

### design-guide (public)

- **Role:** design-token pipeline: `content/*.toml` → W3C tokens JSON, an Elm package and CSS.
- **Published at:** nothing directly; its output is committed into the hub.
- **Stack:** Haskell (cabal), Nix (devenv).
- **Depends on the hub via:** `make check` clones the hub into `review/vendor/master-builder` for the elm-review rules. The hub in turn vendors design-guide as a submodule and copies its output into `packages/design-tokens/` with `make design-tokens`. **This is a cycle**: neither can be checked without the other being reachable.
- **Runtime services:** none.

### website (public)

- **Role:** content (Markdown, `config.toml`, images) of the association's main site.
- **Published at:** https://palikkaharrastajat.fi
- **Depends on the hub via:** reusable workflow `deploy-content.yml@main` with a `builder_ref` input (default `main`).
- **Uses from the hub:** the whole site builder; `config.toml` is layered on the family defaults, including the footer links. Enables the `[admin]` editor (`content_repo = "website"`).
- **Runtime services:** none.
- **CI / deploy:** GitHub Pages, on push.
- **Known deviations:** unpinned hub (see above). No issue tracks this yet.

### guides (public)

- **Role:** content of the guides site "Palikkaoppaat".
- **Published at:** https://oppaat.palikkaharrastajat.fi
- **Depends on the hub via:** reusable workflow `deploy-content.yml@main`.
- **Uses from the hub:** the whole site builder; `[navbar] variant = "compact"`; nested content directories (`jasenpalvelut/`); the family footer links.
- **Runtime services:** none.
- **CI / deploy:** GitHub Pages, on push.
- **Known deviations:** unpinned hub. No issue tracks this yet.

### logo (public)

- **Role:** content of the logo, colour and typography reference site.
- **Published at:** https://logo.palikkaharrastajat.fi (cited by the hub's `AGENTS.md` as the design reference: `brand.css`, `design-guide/index.jsonld`).
- **Depends on the hub via:** reusable workflow `deploy-content.yml@main`.
- **Other upstreams:** none in its own repository: it holds only Markdown and `config.toml`. The logo and icon files it presents are served from the hub's `public/`.
- **Relation to design-guide:** design-guide is the source of the tokens (it generates what the hub ships in `packages/design-tokens`); logo is the published, human-readable presentation of the same design. When the two disagree, design-guide is canonical for token values.
- **Known deviations:** unpinned hub. Its `config.toml` still carries its own footer link list, and gives its footer disclaimer as a single string (the loader accepts that). No issue tracks these yet.

### event-calendar (public)

- **Role:** the event calendar "Palikkakalenteri".
- **Published at:** https://kalenteri.palikkaharrastajat.fi
- **Stack:** Elm SPA (Vite, Tailwind 4), Haskell static generator (feeds, iCalendar, HTML/PDF export), Leaflet.
- **Depends on the hub via:** submodule pin `vendor/master-builder`.
- **Uses from the hub:** `ui-components` (`Component.Layout`, `Account`, forms, alerts, …), `design-tokens`, `app-toolkit`, `finnish-datepicker`, `site-config` (Vite plugin, generators, `mk/site-config.mk`), `statics-common`, `review/` rules, shared icons and logos.
- **Runtime services:** PocketBase (`data.palikkaharrastajat.fi`), Keycloak (OIDC through PocketBase), OpenStreetMap tiles, Nominatim (geocoding).
- **CI / deploy:** `deploy.yml` (GitHub Pages) and `scheduled.yml` (regenerates the static files four times a day).

### service-map (public)

- **Role:** the service map "Palikkakartta" of shops, exhibitions and other places.
- **Published at:** https://kartta.palikkaharrastajat.fi (also `embed.html` for embedding)
- **Stack:** Elm SPA (Vite, Tailwind 4), Haskell static generator (feeds), MapLibre GL.
- **Depends on the hub via:** submodule pin `vendor/master-builder`.
- **Uses from the hub:** as event-calendar, plus `osm-opening-hours`.
- **Other upstreams:** service-map-tiles (basemap style and tiles); event-calendar (links to its event edit pages through `[app] calendar_url`, and shows its events).
- **Runtime services:** PocketBase, Keycloak, tiles.palikkaharrastajat.fi, Nominatim.
- **CI / deploy:** `deploy.yml` (GitHub Pages) and `scheduled.yml` (four times a day).

### planet (public)

- **Role:** the feed aggregator "Palikkalinkit".
- **Published at:** https://linkit.palikkaharrastajat.fi
- **Stack:** Haskell feed aggregator that generates the Elm data module, OPML and a search index; Elm SPA (Vite, Tailwind 4).
- **Depends on the hub via:** submodule pin `vendor/master-builder`.
- **Uses from the hub:** `ui-components` (`Component.Layout`, `Button`, `Form`, `SiteSettings`, `Lang`, `UiStrings`), `design-tokens`, `site-config`, `review/` rules, shared icons and logos.
- **Runtime services:** none (the feeds are fetched at build time).
- **CI / deploy:** `deploy.yml` (GitHub Pages) and `scheduled.yml` (four times a day).

### competitions (private)

- **Role:** "Palikkakilpailu", the building competition service.
- **Stack:** custom PocketBase 0.37.5 Go backend (`go.mod`, `pb_hooks/`, `pb_migrations/`), Elm SPA, Haskell gallery pipeline, Keycloak realm `competitions`; Caddy and Mailpit locally.
- **Depends on the hub via:** submodule pin `vendor/master-builder`.
- **Uses from the hub:** `ui-components` (`Component.Layout`, `Account`, `SiteSettings`, `Lang`, `UiStrings`), `design-tokens`, `site-config` (`config.toml`), `review/` rules, shared icons and logos; `elm-app/packages` is a committed symlink and icons come from `1602/elm-feather`.
- **CI / deploy:** `quality.yml` (shared `setup-nix` action); `deploy.yml` and `scheduled.yml` are disabled. Built against hub changes by the Downstream workflow (private checkout through the `DOWNSTREAM_READ_TOKEN` secret; its build log is public, since the hub is, so compiler and test errors quote private source lines, which the repository owner must accept).
- **Conventions:** conforms once the `family-conventions` branch of [Suomen-Palikkaharrastajat-ry/competitions#1](https://github.com/Suomen-Palikkaharrastajat-ry/competitions/issues/1) is merged (until then its `main` is behind). The status table shows the pin.
- **Remaining follow-ups** (also tracked in that issue):
  - `config.toml` holds a placeholder production URL; the font comes from a local `outfit.css` until the hub ships one.
  - `devenv.yaml` follows nixpkgs master.
  - No `cabal.project` and no `src/` layout like the other Haskell repositories; the build output goes to `build/`.
  - `review/src/LlmAgent` and `pkgs/npm-tools.nix` are copies of the hub's.
  - `Styles.hs` uses hex colours.

### brick-frame (public)

- **Role:** 3D viewer and tooling for brick models; its viewer script is used on the hub-built sites.
- **Published at:** https://kehys.palikkaharrastajat.fi (docs at `/docs/`)
- **Stack:** Elm, Haskell, JavaScript.
- **Depends on the hub via:** submodule pin `vendor/master-builder`; its `elm.json` lists `design-tokens` and `ui-components`.
- **CI / deploy:** `deploy.yml` (GitHub Pages).
- **Known deviations:** an old pin (see the status table); not part of the Downstream matrix, so hub changes are never built against it. Has no `config.toml` and does not use `Component.Layout`. No issue tracks these yet.

### membership-card (public)

- **Role:** the electronic membership card.
- **Published at:** https://kortti.palikkaharrastajat.fi
- **Stack:** Elm SPA (Vite, Tailwind 4), `joakin/elm-canvas`.
- **Depends on the hub via:** submodule pin `vendor/master-builder`; its `elm.json` lists `design-tokens` and `ui-components`.
- **Runtime services:** Keycloak (OIDC, authorization code with PKCE).
- **CI / deploy:** `deploy.yml` (GitHub Pages).
- **Known deviations:** an old pin (see the status table); not part of the Downstream matrix. Has no `config.toml` and does not use `Component.Layout`. No issue tracks these yet.

## Not part of the family

These repositories belong to the organisation but share no code with the hub.

| Repo | What it is | Why it is outside |
|---|---|---|
| **bricklayer** | Haskell pipeline that generates the brick-style logo assets | No repository references it; its output reaches the family only as the image files committed in the hub's `public/logo`. |
| **service-map-tiles** | Builds the basemap style and tiles served at tiles.palikkaharrastajat.fi | A runtime service for service-map; own toolchain. |
| **brickbot** | Rust Discord bot that follows feeds and OPML files and syncs events from PocketBase | Consumes published data at runtime (PocketBase; which feeds it follows is deployment configuration); no shared code. |
| **emmet** | Python CLI that synchronises member data from Excel to Keycloak | The association secretary's tool; affects the family only through Keycloak accounts. |
| **bylaws** | The association's bylaws (TeX) | Documents, not software. |

## Keeping this page current

- The pull request template asks whether this page needs an update when a
  repository's dependency on the hub, or its runtime services, change.
- The status table is generated; do not edit it by hand.
- When a repository starts or stops pinning the hub, update the lists at the
  top of `script/family-status.sh` and its section here.

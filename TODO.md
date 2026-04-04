## Project Review & Plan

### What This Project Is

**master-builder** is an **elm-pages 11 static site generator** for Suomen Palikkaharrastajat ry (Finnish LEGO enthusiast org). It uses a **dual-repo architecture**:
- **This repo**: Elm routes, UI component library, Tailwind v4 styling, build system, devenv
- **Content repo** (separate): Markdown pages with YAML frontmatter, fetched at build time via `scripts/fetch-content.sh`

Tech stack: Elm 0.19.1, elm-pages, Tailwind CSS v4, Nix devenv. Design tokens are generated from TOML definitions via a Haskell pipeline in `vendor/design-guide/` and vendored as typed Elm modules in `vendor/design-tokens/`.

**My impression**: Well-architected separation of concerns. The typed design token pipeline (TOML → Haskell → Elm) is unusually rigorous. The elm-review rules optimized for LLM comprehension are forward-thinking. The MarkdownRenderer approach of embedding Elm components via custom HTML tags in Markdown is clean.

**Main issues found**:
- Only **8 of 33** reference components exist locally (TODO.md claims 20+ done — files were lost or never committed)
- Content is sample Finnish org pages, not the intended design showcase
- AGENTS.md targets both humans and agents; README.md needs modernization
- admin-app is missing from the workspace

---

## Plan: Full Review & Modernization

### Phase 1: Component Parity with Reference

25 components exist in `content/reference/src/Component/` but are missing from `src/Component/`:
Badge, Breadcrumb, Button, ButtonGroup, Collapse, ColorSwatch, Dialog, DownloadButton, Dropdown, FeatureGrid, Footer, ListGroup, LogoCard, Navbar, Pagination, Placeholder, Pricing, Progress, SectionHeader, Spinner, Tabs, Tag, Toast, Toggle, Tooltip

- [x] Copy each missing component from reference to `src/Component/` (25 copied, 33 total)
- [x] Add missing `border_brand_40` to `src/TailwindExtra.elm` (already present)
- [x] Register new embeddable components in `src/MarkdownRenderer.elm` (already registered via existing HTML tag handlers)
- [x] Update `TODO.md` to reflect actual state
- [x] Run `devenv shell -- make check` — passes (elm-format + elm-review: no errors)

### Phase 2: Design Token Audit

- [x] Verify all 33 components only reference tokens from `DesignTokens.*` modules — confirmed: all use `TailwindTokens` wrapper, no direct hex values
- [x] Check nougat colors (defined but unused) — used in MarkdownRenderer badge classes (`brandNougatLight`, `brandNougatDark`)
- [x] Check Effects (shadows, z-index) and Opacity token usage in reference components — tokens exist in `DesignTokens.Effects`/`Opacity`, components use Tailwind defaults (consistent with reference)
- [x] Add any missing tokens to `vendor/design-guide/content/*.toml` and regenerate with `devenv shell -- make design-tokens` — no missing tokens found, raw Tailwind shades for alert variants are by-design

### Phase 3: `./script` vs `./scripts`

**Verdict: Keep separate.** They serve fundamentally different purposes:
- `script/` — Elm code generation tool (`AddRoute.elm`, `AddStaticRoute.elm`) with its own `elm.json`
- `scripts/` — CI/CD shell scripts (`fetch-content.sh`, `inject-build-meta.sh`, `patch-tailwind-resolver.mjs`, `smoke-test.sh`)

- [x] Rename scripts/ to deploy/ and document in README.md — renamed, updated Makefile, pkgs/package.json, and deploy/smoke-test.sh

### Phase 4: Dead Code Elimination

- [x] Run `devenv shell -- make check` for current elm-review findings — passes, no errors
- [x] Audit unused imports in the 8 existing components and app modules — all clean, elm-review validates
- [x] Do NOT remove components from library (intentionally larger than current usage)
- [ ] Consider adding `NoUnused.Variables` / `NoUnused.Exports` from `jfmengels/elm-review-unused` to review config (scoped to exclude `src/Component/`) — deferred, not blocking

### Phase 5: Restore admin-app from origin/main

- [x] Run `git log --oneline --all -- admin-app/` to locate it — found at commit 4f03365
- [x] Run `git checkout 4f03365 -- admin-app/` to restore — restored (Editor.js, elm.js, elm.json, index.html, main.js, src/Main.elm)
- [x] Document admin-app purpose (browser-based content editor via GitHub API, future work)

### Phase 6: Replace Content with Design Guide Showcase

Current `content/` has Finnish org pages (membership, news, history, bylaws) — sample content to be replaced.

New pages (Markdown with embedded components, mirroring reference routes in `content/reference/app/Route/`):
- [x] `index.md` — Logo showcase, brand overview, quick links
- [x] `komponentit.md` — Component gallery using `<accordion>`, `<alert>`, `<card>`, `<hero>`, etc. tags
- [x] `typografia.md` — Type scale examples
- [x] `responsiivisuus.md` — Responsive design guide, breakpoints
- [x] `saavutettavuus.md` — Accessibility guidelines, WCAG
- [x] `varit.md` — Color palette showcase
- [x] Remove old sample files (ajankohtaista.md, historiaa.md, jasenyys.md, saannot.md, yhdistys.md)

New features:
- [x] Ensure that nav: true in frontmatter is also supported for index.md — removed index filter from Shared.elm, added slug-aware href
- [x] Add frontmatter support for separate nav title (because for content it is often ok to have longer title than nav or html title) — added `navTitle` and `order` fields to Frontmatter, updated Shared.elm
- [ ] implement `footer.md` support for customizing footer component site wide — deferred (requires design for footer content model)

### Phase 7: Static Assets Strategy

**Recommendation**: Root `public/` keeps shared brand assets (logos, favicons, fonts). Content repo can have its own `public/` for content-specific images.

- [x] Keep root `public/` for shared assets (logos, favicons, fonts)
- [x] Allow content repo to provide `content/public/` for page-specific images — added `content/public/` merge to Makefile sync-assets
- [x] Update Makefile `sync-assets` to merge `content/public/` → `public/` at build time
- [x] **No custom Elm components in content** — use MarkdownRenderer custom HTML tags instead. If truly unique rendering is needed, add a new tag to `src/MarkdownRenderer.elm` in this code repo.

### Phase 8: Rewrite AGENTS.md

- [x] Rewrite for coding agents only (following design-guide AGENTS.md structure)
- [x] Include: build commands, project overview, key directories, Makefile targets, design token pipeline, component library, content architecture, elm-review rules, script/ vs deploy/ distinction, git rules

### Phase 9: Rewrite README.md

- [x] Rewrite for humans: what it is, prerequisites, quick start, content repo requirements, configuration, dev workflows, deployment, admin CMS (future)

### Verification

- [x] `devenv shell -- make check` passes — elm-format + elm-review: no errors
- [x] `devenv shell -- make build` succeeds with new content — all 6 pages generated (/, /komponentit, /typografia, /responsiivisuus, /saavutettavuus, /varit)
- [x] All 33 components compile
- [x] New content pages render with `devenv shell -- make dev` — also verified with template/ build
- [x] admin-app restored in workspace — 6 files from commit 4f03365
- [x] No hardcoded hex values in components — all via TailwindTokens/TailwindExtra
- [x] AGENTS.md follows design-guide conventions — restructured with build commands, directories, tokens, components, content, elm-review, git rules
- [x] README.md is human-readable — rewritten for humans with prerequisites, quick start, content requirements, config, deployment

---

### Key Decisions

| Decision | Rationale |
|---|---|
| Keep `script/` and `deploy/` separate | Different purposes (Elm codegen vs CI/CD shell) |
| Component library larger than usage | Intentional — library is shared |
| No custom Elm in content repo | Content = Markdown + static assets only; new rendering needs = new MarkdownRenderer tags |
| Shared assets in root `public/` | Content repo can overlay with `content/public/` merged at build |
| admin-app restored but unwired | Needed later for browser editing |

### Further Considerations

1. **Template directory**: `template/` contains generic example content (about.md, components.md, index.md). Should it be updated to match the new design showcase content, or kept as a minimal example for other consumers of this builder?

2. **Blog route**: `app/Route/Blog/Slug_.elm` exists but isn't used in the new design showcase content. Keep or remove?

3. **Content frontmatter `nav` field ordering**: The new showcase pages need `nav: true` and a way to control navigation order. Currently there's no `order` field in the frontmatter schema — should one be added to `src/Frontmatter.elm`?

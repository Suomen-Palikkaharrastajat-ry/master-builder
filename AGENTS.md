# Agent Guidelines

## Design System

All design and component work must follow the official Suomen Palikkaharrastajat ry design guide.

**Agent CSS reference:** Fetch `https://logo.palikkaharrastajat.fi/brand.css` for the latest canonical `@theme`, `@utility type-*`, `@font-face`, reduced-motion rule, and component classes. Tailwind v4 requires `@theme` in the locally-processed file — copy the content into `style.css`.

**Human-readable:** https://logo.palikkaharrastajat.fi/
**Machine-readable (JSON-LD):** https://logo.palikkaharrastajat.fi/design-guide/index.jsonld

### Color Tokens

Use the semantic Tailwind classes defined in `style.css` — never hardcode hex values:

| Semantic class | Value | Usage |
|---|---|---|
| `text-text-primary` / `bg-brand` | `#05131D` | Primary text, dark backgrounds |
| `text-text-on-dark` / `text-white` | `#FFFFFF` | Text on dark surfaces |
| `text-text-muted` | `#6B7280` | Secondary labels, descriptions |
| `text-text-subtle` | `#9CA3AF` | Placeholder, captions |
| `bg-bg-page` | `#FFFFFF` | Page background |
| `bg-bg-subtle` | `#F9FAFB` | Card/panel backgrounds |
| `bg-bg-accent` / `bg-brand-yellow` | `#FAC80A` | Accent/CTA backgrounds |
| `border-border-default` | `#E5E7EB` | Default borders, dividers |
| `border-border-brand` | `#05131D` | Brand-coloured borders |
| `text-brand-red` | `#C91A09` | Error/danger states |
| `bg-brand-nougat-light` | `#F6D7B3` | Warm accent (light) |
| `bg-brand-nougat` | `#D09168` | Warm accent (mid) |
| `bg-brand-nougat-dark` | `#AD6140` | Warm accent (dark) |

All colour usage must pass WCAG AA contrast at minimum.

### Typography

Font: **Outfit variable** (weights 100–900), self-hosted from `public/fonts/`. Never substitute.

Use the named `type-*` utility classes defined in `style.css`. Never use raw Tailwind size/weight combinations.

| Class | Size | Weight | Notes |
|---|---|---|---|
| `type-display` | 3rem | 700 | Hero headlines only |
| `type-h1` | 1.875rem | 700 | One per page |
| `type-h2` | 1.5rem | 700 | Section headings |
| `type-h3` | 1.25rem | 600 | Sub-section headings |
| `type-h4` | 1.125rem | 600 | Card / widget headings |
| `type-body` | 1rem | 400 | Default body copy |
| `type-body-small` | 0.875rem | 500 | UI controls, labels |
| `type-caption` | 0.875rem | 400 | Metadata, footnotes |
| `type-mono` | 0.875rem | 400 | Code snippets (monospace) |
| `type-overline` | 0.75rem | 600 uppercase | Category labels |

### Spacing

4px base unit. Use Tailwind's default spacing scale (`p-1` = 4px, `p-2` = 8px, etc.).

### Motion

| Token | Value | Use |
|---|---|---|
| `duration-fast` | 150ms | Hover states, focus rings |
| `duration-base` | 300ms | Cards, menus, accordions |
| `duration-slow` | 500ms | Page transitions |
| `ease-standard` | `cubic-bezier(0.4, 0, 0.2, 1)` | Default |
| `ease-decelerate` | `cubic-bezier(0, 0, 0.2, 1)` | Elements entering |
| `ease-accelerate` | `cubic-bezier(0.4, 0, 1, 1)` | Elements leaving |

Always wrap animations with `prefers-reduced-motion` support (already in `style.css`).

### Logos

Self-hosted — serve logo files from `public/` (already copied). Use SVG first; WebP with PNG fallback for raster contexts.

- **On dark background** (e.g. brand nav): `horizontal-full-dark`
  `https://logo.palikkaharrastajat.fi/logo/horizontal/svg/horizontal-full-dark.svg`
- **On light background**: `horizontal-full`
  `https://logo.palikkaharrastajat.fi/logo/horizontal/svg/horizontal-full.svg`
- **Square mark**: `square-basic`
  `https://logo.palikkaharrastajat.fi/logo/square/svg/square-basic.svg`

Minimum clear space: 25% of logo width on all sides. Minimum digital width: 80px (square) or 200px (horizontal). Never distort, recolour, or add shadows.

### Layout

- Max content width: `max-w-5xl` (1024px)
- Horizontal padding: `px-4` (16px) on all screens
- Full wrapper: `max-w-5xl mx-auto px-4`
- Mobile-first: base styles for mobile, `sm:` / `md:` / `lg:` for overrides
- Minimum touch target: 44×44px

### Running Elm commands

Always prefix Elm CLI commands with `devenv shell --`:

```
devenv shell -- elm make ...
devenv shell -- elm-pages build
devenv shell -- elm-json install <package>
```

### Components

All 32 UI components come from the **design-guide** repository, available as a git submodule at `vendor/design-guide/`. The `vendor/design-guide/src` path is already in `elm.json` source-directories, so components are imported directly as `Component.*`:

```elm
import Component.Button as Button
import Component.Card as Card
import Component.Alert as Alert
```

**Submodule management:**
```bash
# After cloning pages:
git submodule update --init

# To pull latest design-guide changes:
git submodule update --remote vendor/design-guide
```

**Focus ring convention:** Use `focus-visible:ring-2 focus-visible:ring-brand` on all interactive elements (keyboard-only; no ring on mouse click). Do NOT use `focus:ring-*`.

**All 32 components available:** Alert, Accordion, Badge, Breadcrumb, Button, ButtonGroup, Card, CloseButton, Collapse, ColorSwatch, Dialog, DownloadButton, Dropdown, FeatureGrid, Footer, Hero, ListGroup, LogoCard, Navbar, Pagination, Placeholder, Pricing, Progress, SectionHeader, Spinner, Stats, Tabs, Tag, Timeline, Toast, Toggle, Tooltip.

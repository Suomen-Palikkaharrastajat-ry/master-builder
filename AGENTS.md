# Agent Guidelines

## Design System

All design and component work must follow the official Suomen Palikkaharrastajat ry design guide:

**Source:** https://logo.palikkaharrastajat.fi/design-guide/index.jsonld

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
| `bg-bg-accent` / `bg-brand-yellow` | `#F2CD37` | Accent/CTA backgrounds |
| `border-border-default` | `#E5E7EB` | Default borders, dividers |
| `border-border-brand` | `#05131D` | Brand-coloured borders |
| `text-brand-red` | `#C91A09` | Error/danger states |
| `bg-brand-nougat-light` | `#F6D7B3` | Warm accent (light) |
| `bg-brand-nougat` | `#D09168` | Warm accent (mid) |
| `bg-brand-nougat-dark` | `#AD6140` | Warm accent (dark) |

All colour usage must pass WCAG AA contrast at minimum.

### Typography

Font: **Outfit variable** (weights 100–900), loaded from `logo.palikkaharrastajat.fi`. Never substitute.

| Role | Size | Weight | Tailwind |
|---|---|---|---|
| Display | 48px | 700 | `text-5xl font-bold` |
| Heading 1 | 30px | 700 | `text-3xl font-bold` |
| Heading 2 | 24px | 700 | `text-2xl font-bold` |
| Heading 3 | 20px | 600 | `text-xl font-semibold` |
| Body | 16px | 400 | `text-base` |
| Body Small | 14px | 500 | `text-sm font-medium` |
| Caption | 14px | 400 | `text-sm` |
| Mono | 14px | 400 | `font-mono text-sm` |
| Overline | 12px | 600 | `text-xs font-semibold uppercase` |

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

Serve from `logo.palikkaharrastajat.fi`. Use SVG first; WebP with PNG fallback for raster contexts.

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

The design guide defines 24 reusable components (`src/Component/`). Prefer these patterns:

- **Button primary**: `bg-brand-yellow text-brand hover:bg-brand hover:text-brand-yellow`
- **Button secondary**: `bg-bg-page border border-brand/40 hover:bg-brand/5 text-brand`
- **Card**: `bg-bg-page border border-border-default rounded-xl shadow-sm p-6`
- **Input**: `border border-border-default rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-brand-yellow`

# TODO

## Design guide conformance — https://logo.palikkaharrastajat.fi/

### Colors (`style.css`)
- [x] Fix `--color-brand-yellow` from `#F2CD37` to `#FAC80A` to match the design guide palette

### Button component (`src/Component/Button.elm`)
- [x] Change base class `font-medium` to `font-semibold` (design guide specifies `font-semibold` for all button variants)
- [x] Replace `focus:outline-none focus:ring-2 focus:ring-offset-2` with `focus-visible:ring-2 focus-visible:ring-offset-2` — keyboard-only focus rings (design guide note: "use focus-visible: not focus:")
- [x] Primary variant hover: change `hover:bg-brand hover:text-brand-yellow` → `hover:opacity-90`
- [x] Secondary variant border: change `border-brand/40` → `border-gray-300` and hover: `hover:bg-brand/5` → `hover:bg-gray-50`
- [x] Ghost variant hover: change `hover:bg-brand/5` → `hover:bg-gray-100`
- [x] Add `loading : Bool` prop to `Config` type with spinner rendering
- [x] Add `aria-pressed` support for toggle/filter button usage (noted in JSON-LD spec)

### Module naming
- [x] Rename component directory `src/Components/` → `src/Component/` and update all module names from `Components.*` → `Component.*` to match JSON-LD `sourceDir: "src/Component/"`

### Navigation & accessibility (`app/Shared.elm`)
- [x] Add a skip-to-content link as the first element in the page (visually hidden via `sr-only`, revealed on focus) pointing to `#main-content`
- [x] Add `id="main-content"` to the `<main>` element
- [x] Add `aria-expanded` attribute to the mobile hamburger button reflecting `model.showMenu`
- [x] Add `focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2` to desktop nav links
- [x] Add `focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2` to mobile nav links

### Missing components (JSON-LD component catalogue)
- [x] Implement `Component.Breadcrumb` — navigation breadcrumb trail; props: `items : List { label : String, href : Maybe String }`
- [x] Implement `Component.ButtonGroup` — horizontally grouped buttons sharing a border; props: `buttons : List (Html msg)`
- [x] Implement `Component.CloseButton` — accessible dismiss button; props: `onClick : msg, label : String`
- [x] Implement `Component.Collapse` — single collapsible section via `<details>`; props: `summary : Html msg, body : List (Html msg), open : Bool`
- [x] Implement `Component.Dialog` — modal dialog; props: `title : String, body : List (Html msg), footer : Maybe (Html msg), isOpen : Bool, onClose : msg`
- [x] Implement `Component.DownloadButton` — styled download link; props: `label : String, href : String`
- [x] Implement `Component.Dropdown` — disclosure dropdown via `<details>`/`<summary>`; props: `trigger : Html msg, items : List (Html msg)`
- [x] Implement `Component.ListGroup` — vertical list with optional active states and badges; props: `items : List (Html msg)`
- [x] Implement `Component.Pagination` — page navigation; props: `currentPage : Int, totalPages : Int, onPageClick : Int -> msg`
- [x] Implement `Component.Placeholder` — animated loading skeleton; props: `items : List (Html msg)`
- [x] Implement `Component.Progress` — horizontal progress bar with `role="progressbar"`, `aria-valuenow`, `aria-valuemax`; props: `value : Int, max : Int, label : Maybe String, color : Color`
- [x] Implement `Component.SectionHeader` — section heading with optional description; props: `title : String, description : Maybe String`
- [x] Implement `Component.Spinner` — loading spinner with `role="status"` and visually-hidden label; props: `size : Size, label : String`
- [x] Implement `Component.Tabs` — stateless tab strip with `role="tablist"`, `aria-controls`, `aria-labelledby`; props: `tabs : List String, activeIndex : Int, onTabClick : Int -> msg`
- [x] Implement `Component.Toast` — notification toast (Default, Success, Warning, Danger); props: `title : String, body : String, variant : Variant, onClose : Maybe msg`
- [x] Implement `Component.Tag` — removable inline chip; props: `label : String, onRemove : Maybe msg`
- [x] Implement `Component.Toggle` — accessible on/off switch with `role="switch"`, `aria-checked`; props: `id : String, label : String, checked : Bool, onToggle : Bool -> msg, disabled : Bool`
- [x] Implement `Component.Tooltip` — hover/focus tooltip; props: `content : String, children : List (Html msg)`

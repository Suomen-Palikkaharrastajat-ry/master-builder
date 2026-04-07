---
title: "Component Showcase"
description: "All available component tags for use in Markdown content."
slug: components
published: true
---

# Component Showcase

Every component registered in `MarkdownRenderer.elm` is demonstrated below. Use these HTML tags inside any Markdown file to render rich UI components.

---

## Callout / Alert

Use `<callout type="…">` for attention-grabbing notices. The `type` attribute accepts `info`, `success`, `warning`, or `error`.

<tab-group name="callout">

<preview>

<callout type="info">

This is an **info** callout. Use it for helpful background information or tips.

</callout>

<callout type="success">

This is a **success** callout. Use it to confirm that something worked as expected.

</callout>

<callout type="warning">

This is a **warning** callout. Use it to highlight something the reader should be careful about.

</callout>

<callout type="error">

This is an **error** callout. Use it to call out a known problem or breaking change.

</callout>

</preview>

<example>

```html
&lt;callout type="info"&gt;Your info message here.&lt;/callout&gt;

&lt;callout type="success"&gt;Your success message here.&lt;/callout&gt;

&lt;callout type="warning"&gt;Your warning message here.&lt;/callout&gt;

&lt;callout type="error"&gt;Your error message here.&lt;/callout&gt;
```

</example>

</tab-group>

---

## Hero Section

Use `<hero title="…" subtitle="…">` to render a large centred hero. Place `<button-link href="…" variant="…" label="…"/>` tags inside as the call-to-action slot.

<tab-group name="hero">

<preview>

<hero title="Your headline goes here" subtitle="A supporting sentence that gives the reader more context about what this page or product is about.">

<button-link href="#" variant="primary" label="Get Started"/>
<button-link href="#" variant="secondary" label="Learn More"/>

</hero>

</preview>

<example>

```html
&lt;hero title="Your headline" subtitle="Supporting sentence here."&gt;

&lt;button-link href="#" variant="primary" label="Get Started"/&gt;
&lt;button-link href="#" variant="secondary" label="Learn More"/&gt;

&lt;/hero&gt;
```

</example>

</tab-group>

---

## Button Link

Use `<button-link href="…" variant="…" label="…"/>` to render a styled anchor. The `variant` attribute accepts `primary`, `secondary`, or `ghost` (default is `primary`).

<tab-group name="button-link">

<preview>

<button-link href="#" variant="primary" label="Primary"/>
<button-link href="#" variant="secondary" label="Secondary"/>
<button-link href="#" variant="ghost" label="Ghost"/>

</preview>

<example>

```html
&lt;button-link href="/path" variant="primary" label="Primary"/&gt;
&lt;button-link href="/path" variant="secondary" label="Secondary"/&gt;
&lt;button-link href="/path" variant="ghost" label="Ghost"/&gt;
```

</example>

</tab-group>

---

## Feature Grid

Use `<feature-grid columns="2|3">` to wrap `<feature>` items in a responsive grid. The optional `columns` attribute accepts `2`, `3`, or `4` (default is `3`). The `icon` attribute accepts a Feather icon name (`zap`, `check`, `globe`, `edit`, `layers`, `git-branch`, `rss`, `calendar`, `shield`, `lock`, `code`, `cpu`, `package`, `trending-up`, etc.). The optional `href` attribute wraps the feature in a link.

<tab-group name="feature-grid">

<preview>

<feature-grid columns="3">

<feature title="Fast builds" icon="zap" href="/docs/builds">

elm-pages pre-renders every page at build time. No server-side work at request time.

</feature>

<feature title="Type safety" icon="check" href="/docs/type-safety">

Elm's compiler catches mistakes before they reach production. Refactor with confidence.

</feature>

<feature title="SEO ready" icon="globe">

Every page ships with configurable meta tags and structured data out of the box.

</feature>

<feature title="Markdown-first" icon="edit">

Author content in plain Markdown and drop in components where you need them.

</feature>

<feature title="Tailwind CSS" icon="layers">

Style everything with utility classes. No custom CSS files to maintain.

</feature>

<feature title="Git-based CMS" icon="git-branch">

Content lives alongside your code. Commit, review, and deploy with standard git workflows.

</feature>

</feature-grid>

</preview>

<example>

```html
&lt;feature-grid columns="3"&gt;

&lt;feature title="Fast builds" icon="zap" href="/docs/builds"&gt;
Description of the feature goes here.
&lt;/feature&gt;

&lt;feature title="Type safety" icon="check"&gt;
Another feature description. No href — renders as a plain div.
&lt;/feature&gt;

&lt;/feature-grid&gt;
```

</example>

</tab-group>

---

## Pricing Table

Use `<pricing-table>` to wrap `<pricing-tier>` cards in a grid. Each tier has required `name` and `price` attributes and an optional `period`.

<tab-group name="pricing">

<preview>

<pricing-table>

<pricing-tier name="Free" price="$0" period="month">

- 1 site
- 10 pages
- Community support
- Git deploy

</pricing-tier>

<pricing-tier name="Pro" price="$12" period="month">

- Unlimited sites
- Unlimited pages
- Priority support
- Custom domain
- Analytics

</pricing-tier>

<pricing-tier name="Team" price="$49" period="month">

- Everything in Pro
- 5 team members
- SSO / SAML
- SLA guarantee
- Dedicated support

</pricing-tier>

</pricing-table>

</preview>

<example>

```html
&lt;pricing-table&gt;

&lt;pricing-tier name="Free" price="$0" period="month"&gt;
- Feature one
- Feature two
&lt;/pricing-tier&gt;

&lt;pricing-tier name="Pro" price="$12" period="month"&gt;
- Everything in Free
- More features
&lt;/pricing-tier&gt;

&lt;/pricing-table&gt;
```

</example>

</tab-group>

---

## Card

Use `<card title="…">` to wrap content in a bordered card. The `title` attribute is optional and renders a header.

<tab-group name="card">

<preview>

<card title="Getting Started">

Everything you need to launch your first elm-pages site in under five minutes. Clone the starter, run `make dev`, and start writing Markdown.

</card>

<card>

A card without a title is just a clean content container — useful for callouts, tips, or any isolated block of text.

</card>

</preview>

<example>

```html
&lt;card title="Getting Started"&gt;
Card body content goes here.
&lt;/card&gt;

&lt;card&gt;
A card without a title.
&lt;/card&gt;
```

</example>

</tab-group>

---

## Badge

Use `<badge color="…" label="…"/>` inline to label content. The `color` attribute accepts `gray`, `blue`, `green`, `yellow`, `red`, `purple`, or `indigo`.

<tab-group name="badge">

<preview>

<badge color="indigo" label="New"/> <badge color="green" label="Stable"/> <badge color="yellow" label="Beta"/> <badge color="red" label="Deprecated"/> <badge color="gray" label="Draft"/>

</preview>

<example>

```html
&lt;badge color="indigo" label="New"/&gt;
&lt;badge color="green" label="Stable"/&gt;
&lt;badge color="yellow" label="Beta"/&gt;
&lt;badge color="red" label="Deprecated"/&gt;
&lt;badge color="gray" label="Draft"/&gt;
```

</example>

</tab-group>

---

## Accordion

Use `<accordion>` to wrap `<accordion-item summary="…">` elements. Each item uses the native `<details>` element — no JavaScript required.

<tab-group name="accordion">

<preview>

<accordion>

<accordion-item summary="What is elm-pages?">

elm-pages is a framework for building statically generated sites and web apps with Elm. It handles routing, data fetching, and SEO so you can focus on your content and UI.

</accordion-item>

<accordion-item summary="Do I need to know Elm to use this site?">

Not to read it! But if you want to add new component types or modify the layout, a basic understanding of Elm will help. The component library is designed to be extended incrementally.

</accordion-item>

<accordion-item summary="How do I add a new page?">

Create a new Markdown file in the `content/` directory with a frontmatter block (`title`, `description`, `slug`, `published`). elm-pages picks it up automatically on the next build.

</accordion-item>

<accordion-item summary="Can I use custom components in Markdown?">

Yes — that's exactly what this page demonstrates. Components are registered in `src/MarkdownRenderer.elm` as custom HTML tags, then used directly in any `.md` file.

</accordion-item>

</accordion>

</preview>

<example>

```html
&lt;accordion&gt;

&lt;accordion-item summary="Question one?"&gt;
Answer to the first question.
&lt;/accordion-item&gt;

&lt;accordion-item summary="Question two?"&gt;
Answer to the second question.
&lt;/accordion-item&gt;

&lt;/accordion&gt;
```

</example>

</tab-group>

---

## Stat Grid

Use `<stat-grid>` to wrap `<stat>` items. Each stat requires `label` and `value` attributes; `change` is optional and shown in green.

<tab-group name="stat-grid">

<preview>

<stat-grid>

<stat label="Total Pages Published" value="24" change="+3 this month"></stat>

<stat label="Avg. Build Time" value="8.4s"></stat>

<stat label="Lighthouse Score" value="100" change="↑ 2pts"></stat>

<stat label="Components Available" value="12" change="+6 new"></stat>

</stat-grid>

</preview>

<example>

```html
&lt;stat-grid&gt;

&lt;stat label="Total Pages" value="24" change="+3 this month"&gt;&lt;/stat&gt;
&lt;stat label="Build Time" value="8.4s"&gt;&lt;/stat&gt;
&lt;stat label="Lighthouse Score" value="100"&gt;&lt;/stat&gt;

&lt;/stat-grid&gt;
```

</example>

</tab-group>

---

## Timeline

Use `<timeline>` to wrap `<timeline-item date="…" title="…">` elements. Ideal for changelogs, roadmaps, or project histories. The optional `icon` attribute accepts a Feather icon name (`calendar`, `check`, `clock`, `flag`, `star`, `zap`, etc.).

<tab-group name="timeline">

<preview>

<timeline>

<timeline-item date="March 2026" title="Component library complete">

Added Accordion, Stat Grid, Timeline, Card, and Badge components. All components are usable directly from Markdown via custom HTML tags.

</timeline-item>

<timeline-item date="February 2026" title="Tailwind CSS v4 + Admin polish">

Migrated to Tailwind v4 with the Vite plugin. Fixed the commit button bug and redesigned the admin layout with utility classes.

</timeline-item>

<timeline-item date="January 2026" title="In-browser authoring launched">

Shipped the full 10-phase implementation: GitHub OAuth, CodeMirror editor, draft auto-save, one-click commit, and build-status detection.

</timeline-item>

</timeline>

</preview>

<example>

```html
&lt;timeline&gt;

&lt;timeline-item date="March 2026" title="Milestone title" icon="check"&gt;
Description of what happened.
&lt;/timeline-item&gt;

&lt;timeline-item date="January 2026" title="Earlier milestone"&gt;
Another description.
&lt;/timeline-item&gt;

&lt;/timeline&gt;
```

</example>

</tab-group>

---

## Section Header

Use `<section-header title="…">` to render a prominent centred section heading. Use `<section-subheader title="…">` for a smaller variant suited to sub-sections. Both accept an optional `description`.

<tab-group name="section-header">

<preview>

<section-header title="Meet our components" description="A curated set of UI building blocks you can drop into any Markdown page."/>

<section-subheader title="Getting started" description="Everything you need is already wired up — just start writing tags."/>

</preview>

<example>

```html
&lt;section-header title="Section title" description="Optional supporting description."/&gt;

&lt;section-subheader title="Sub-section title" description="Optional description."/&gt;
```

</example>

</tab-group>

---

## Toast

Use `<toast title="…">` to render an inline notification banner. The `variant` attribute accepts `default`, `success`, `warning`, or `danger`. Use `body` for a supporting sentence.

<tab-group name="toast">

<preview>

<toast title="Changes saved" body="Your draft has been committed to the repository." variant="default"/>

<toast title="Published successfully" body="The page is now live and indexed." variant="success"/>

<toast title="Review required" body="One or more fields need attention before publishing." variant="warning"/>

<toast title="Publish failed" body="The build encountered an error. Check the logs for details." variant="danger"/>

</preview>

<example>

```html
&lt;toast title="Changes saved" body="Supporting detail here." variant="default"/&gt;
&lt;toast title="Success" body="Action completed." variant="success"/&gt;
&lt;toast title="Warning" body="Please review." variant="warning"/&gt;
&lt;toast title="Error" body="Something went wrong." variant="danger"/&gt;
```

</example>

</tab-group>

---

## Tag

Use `<tag label="…"/>` to render an inline chip. Tags are useful for labelling content with topics, categories, or keywords.

<tab-group name="tag">

<preview>

<p><tag label="elm-pages"/> <tag label="Tailwind CSS"/> <tag label="Markdown"/> <tag label="Open Source"/></p>

</preview>

<example>

```html
&lt;tag label="elm-pages"/&gt;
&lt;tag label="Tailwind CSS"/&gt;
&lt;tag label="Open Source"/&gt;
```

</example>

</tab-group>

---

## Spinner

Use `<spinner/>` to render a loading indicator. The `size` attribute accepts `small`, `medium` (default), or `large`. Use `label` for an accessible description.

<tab-group name="spinner">

<preview>

Small: <spinner size="small" label="Loading…"/>

Medium: <spinner size="medium" label="Loading…"/>

Large: <spinner size="large" label="Loading…"/>

</preview>

<example>

```html
&lt;spinner size="small" label="Loading…"/&gt;
&lt;spinner size="medium" label="Loading…"/&gt;
&lt;spinner size="large" label="Loading…"/&gt;
```

</example>

</tab-group>

---

## Progress Bar

Use `<progress-bar value="…" max="…">` to render a progress indicator. `value` and `max` are integers (default `0` and `100`). The optional `label` appears above the bar. The `color` attribute accepts `brand` (default), `success`, `warning`, `danger`, or `info`.

<tab-group name="progress-bar">

<preview>

<progress-bar value="40" max="100" label="Upload progress" color="brand"/>

<progress-bar value="80" max="100" label="Storage used" color="success"/>

<progress-bar value="60" max="100" label="Build queue" color="warning"/>

<progress-bar value="25" max="100" label="Error rate" color="danger"/>

<progress-bar value="55" max="100" label="Cache hit rate" color="info"/>

</preview>

<example>

```html
&lt;progress-bar value="75" max="100" label="Upload progress" color="brand"/&gt;
&lt;progress-bar value="80" max="100" label="Storage used" color="success"/&gt;
&lt;progress-bar value="60" max="100" label="Queue depth" color="warning"/&gt;
```

</example>

</tab-group>

---

## Info Panel

Use `<info-panel>` to render a tinted panel for contextual notes. The `color` attribute accepts `amber` (default), `blue`, `green`, or `red`. The optional `title` renders as a bold heading.

<tab-group name="info-panel">

<preview>

<info-panel color="amber" title="Before you begin">

Make sure you have committed all unsaved changes. Deploying with uncommitted files may produce unexpected results.

</info-panel>

<info-panel color="blue" title="Did you know?">

You can nest any standard Markdown inside an info panel — including **bold**, `code spans`, and lists.

</info-panel>

<info-panel color="green" title="All systems operational">

The deployment pipeline is healthy. Builds are completing in under 10 seconds.

</info-panel>

<info-panel color="red" title="Action required">

Your API token expires in 3 days. Rotate it in the settings panel to avoid service interruption.

</info-panel>

</preview>

<example>

```html
&lt;info-panel color="amber" title="Before you begin"&gt;
Important context for the reader.
&lt;/info-panel&gt;

&lt;info-panel color="blue"&gt;
A note without a title.
&lt;/info-panel&gt;
```

</example>

</tab-group>

---

## Image + Text

Use `<with-image src="…">` to place an image beside a block of content in a two-column layout. The `side` attribute controls which side the image appears on — `right` (default) or `left`. Use `alt` for an accessible description.

<tab-group name="with-image">

<preview>

<with-image src="/logo-blue.svg" alt="Logo on a light background" side="right">

### Image on the right

Pair an image with descriptive copy to create rich editorial layouts without writing a single line of CSS. The grid collapses to a single column on small screens.

</with-image>

<with-image src="/logo-blue.svg" alt="Logo on a light background" side="left">

### Image on the left

Flip the image to the left by setting `side="left"`. Alternate the layout across sections to create visual rhythm on long-form pages.

</with-image>

</preview>

<example>

```html
&lt;with-image src="/images/screenshot.png" alt="Screenshot" side="right"&gt;

### Your heading

Your description text goes here.

&lt;/with-image&gt;
```

</example>

</tab-group>

---

## Asset Gallery

Use `<asset-gallery source="…">` to render a gallery of downloadable logo assets. The `source` attribute accepts `logos-square`, `logos-square-full`, or `logos-horizontal`. Optional `title` and `description` appear above the grid.

<tab-group name="asset-gallery">

<preview>

<asset-gallery source="logos-square" title="Square logos" description="Compact square variants for avatars, favicons, and app icons."/>

</preview>

<example>

```html
&lt;asset-gallery source="logos-square" title="Square logos" description="Optional description."/&gt;

&lt;asset-gallery source="logos-square-full"/&gt;

&lt;asset-gallery source="logos-horizontal" title="Horizontal logos"/&gt;
```

</example>

</tab-group>

---

## Color Grid

Use `<color-grid source="…">` to render a palette of colour swatches. The `source` attribute accepts `brand`, `skin-tones`, or `rainbow`. Optional `title` and `description` appear above the grid.

<tab-group name="color-grid">

<preview>

<color-grid source="brand" title="Brand colours" description="The primary palette used across all logo variants and UI components."/>

</preview>

<example>

```html
&lt;color-grid source="brand" title="Brand colours" description="Optional description."/&gt;

&lt;color-grid source="skin-tones" title="Skin tones"/&gt;

&lt;color-grid source="rainbow" title="Rainbow palette"/&gt;
```

</example>

</tab-group>

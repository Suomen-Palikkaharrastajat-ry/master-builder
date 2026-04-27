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

Create a new Markdown file in the `content/` directory with a frontmatter block (`title`, `description`, `published`). elm-pages picks it up automatically on the next build, using the filename as the slug.

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

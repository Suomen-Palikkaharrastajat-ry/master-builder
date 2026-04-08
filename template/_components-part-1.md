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

Use `<feature-grid columns="2|3">` to wrap `<feature>` items in a responsive grid. The optional `columns` attribute accepts `2`, `3`, or `4` (default is `3`). The `icon` attribute accepts a Feather icon name (`zap`, `check`, `globe`, `edit`, `layers`, `git-branch`, `rss`, `calendar`, `shield`, `lock`, `code`, `cpu`, `package`, `trending-up`, `info`, `alert-triangle`, `settings`, `user`, `server`, `terminal`, etc.). The optional `href` attribute wraps the feature in a link — linked features gain a hover background and keyboard focus ring automatically.

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


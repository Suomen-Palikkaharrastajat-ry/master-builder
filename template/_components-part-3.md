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

Use `<with-image src="…">` to place an image beside a block of content in a two-column layout. The `side` attribute controls which side the image appears on — `right` (default) or `left`. Use `alt` for an accessible description. The optional `caption` attribute renders a centred caption below the image. The optional `maxwidth` attribute constrains the component width — accepts `lg`, `2xl`, `3xl`, or `4xl`.

<tab-group name="with-image">

<preview>

<with-image src="/logo/square/svg/square-smile.svg" alt="Square smile logo" side="right">

### Image on the right

Pair an image with descriptive copy to create rich editorial layouts without writing a single line of CSS. The grid collapses to a single column on small screens.

</with-image>

<with-image src="/logo/square/svg/square-smile.svg" alt="Square smile logo" side="left" caption="Square smile logo variant." maxwidth="3xl">

### Image on the left, with caption and max-width

Use `caption` to add a label below the image. Use `maxwidth` to stop the layout from stretching to full container width — useful for portrait images or tighter editorial compositions.

</with-image>

</preview>

<example>

```html
&lt;with-image src="/images/screenshot.png" alt="Screenshot" side="right"&gt;

### Your heading

Your description text goes here.

&lt;/with-image&gt;

&lt;with-image src="/images/photo.jpg" alt="Photo" side="left"
  caption="Optional caption below the image."
  maxwidth="3xl"&gt;

### Constrained width

Content here.

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

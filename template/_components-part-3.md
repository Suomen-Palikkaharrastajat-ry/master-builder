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

Use `<info-panel>` to render a tinted panel for contextual notes. The `color` attribute accepts `amber` (default), `blue`, `green`, or `red`. The optional `title` renders as a bold heading. The optional `icon` attribute accepts a Feather icon name and renders it alongside the title.

<tab-group name="info-panel">

<preview>

<info-panel color="amber" title="Before you begin" icon="alert-triangle">

Make sure you have committed all unsaved changes. Deploying with uncommitted files may produce unexpected results.

</info-panel>

<info-panel color="blue" title="Did you know?" icon="info">

You can nest any standard Markdown inside an info panel — including **bold**, `code spans`, and lists.

</info-panel>

<info-panel color="green" title="All systems operational" icon="check-circle">

The deployment pipeline is healthy. Builds are completing in under 10 seconds.

</info-panel>

<info-panel color="red" title="Action required" icon="x-circle">

Your API token expires in 3 days. Rotate it in the settings panel to avoid service interruption.

</info-panel>

</preview>

<example>

```html
&lt;info-panel color="amber" title="Before you begin" icon="alert-triangle"&gt;
Important context for the reader.
&lt;/info-panel&gt;

&lt;info-panel color="blue" title="Did you know?" icon="info"&gt;
A note with an icon and title.
&lt;/info-panel&gt;

&lt;info-panel color="green"&gt;
A panel without a title or icon.
&lt;/info-panel&gt;
```

</example>

</tab-group>

---

## Image + Text

Write Tailwind classes inside `{…}` in the image alt text to style the `<figure>` wrapper. Use `not-prose` to escape the prose container, `md:float-right` or `md:float-left` to float the image alongside following text on medium+ screens, and any other Tailwind utilities you need. Add a caption via the Markdown image title field: `![...](src "caption text")`. Use `<clear>` to reset the float before the next section.

<tab-group name="float-image">

<preview>

![{not-prose mb-4 md:float-right md:ml-6} Square smile logo](/logo/square/svg/square-smile.svg)

### Image on the right

Pair an image with descriptive copy to create rich editorial layouts. On small screens the image stacks above the text. Use `md:float-left md:mr-6` to swap sides.

<clear>

![{not-prose mb-4 md:float-left md:mr-6 max-w-xs} Square smile logo](/logo/square/svg/square-smile.svg "Square smile logo variant.")

### Image on the left, with caption and max-width

Use a Markdown title to add a caption below the image. Any Tailwind utility works — `max-w-xs`, `max-w-sm`, `w-48`, `rounded-xl`, etc.

<clear>

</preview>

<example>

```markdown
![{not-prose mb-4 md:float-right md:ml-6} Alt text](/images/screenshot.png)

### Your heading

Your description text goes here.

<clear>

![{not-prose mb-4 md:float-left md:mr-6 max-w-xs} Alt text](/images/photo.jpg "Optional caption")

### Constrained width

Content here.

<clear>
```

</example>

</tab-group>

---

## Gallery

Use `<gallery source="…">` to render a gallery of downloadable logo assets. The `source` attribute accepts `logos-square`, `logos-square-full`, or `logos-horizontal`. Optional `title` and `description` appear above the grid.

<tab-group name="gallery">

<preview>

<gallery source="logos-square" title="Square logos" description="Compact square variants for avatars, favicons, and app icons."/>

<gallery source="logos-square-full" title="Full square logos" description="Square variants with the full wordmark."/>

<gallery source="logos-horizontal" title="Horizontal logos" description="Wide variants for headers and banners."/>

</preview>

<example>

```html
&lt;gallery source="logos-square" title="Square logos" description="Optional description."/&gt;

&lt;gallery source="logos-square-full" title="Full square logos"/&gt;

&lt;gallery source="logos-horizontal" title="Horizontal logos"/&gt;
```

</example>

</tab-group>

---

## Color Grid

Use `<color-grid source="…">` to render a palette of colour swatches. The `source` attribute accepts `brand`, `skin-tones`, or `rainbow`. Optional `title` and `description` appear above the grid.

<tab-group name="color-grid">

<preview>

<color-grid source="brand" title="Brand colours" description="The primary palette used across all logo variants and UI components."/>

<color-grid source="skin-tones" title="Skin tones" description="Inclusive skin tone palette for illustrated characters."/>

<color-grid source="rainbow" title="Rainbow palette" description="Vibrant full-spectrum colours used in decorative contexts."/>

</preview>

<example>

```html
&lt;color-grid source="brand" title="Brand colours" description="Optional description."/&gt;

&lt;color-grid source="skin-tones" title="Skin tones"/&gt;

&lt;color-grid source="rainbow" title="Rainbow palette"/&gt;
```

</example>

</tab-group>

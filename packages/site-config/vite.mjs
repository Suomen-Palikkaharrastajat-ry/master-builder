// Vite plugin that makes an app's config.toml the single source of its
// document head, web manifest and runtime settings.
//
//   import siteConfig from './packages/site-config/vite.mjs'
//   export default defineConfig({ plugins: [siteConfig(), ...] })
//
// - index.html gets its <html lang>, <title>, SEO, social, PWA and icon tags.
// - site.webmanifest is generated (the path is [pwa] manifest_path).
// - `import siteConfig from 'virtual:site-config'` gives the resolved
//   configuration of every language, to pass to Elm as a flag.

import { resolve as resolvePath } from 'node:path'
import { load } from './site-config.mjs'

const VIRTUAL_ID = 'virtual:site-config'
const RESOLVED_ID = '\0' + VIRTUAL_ID

const absolute = (site, path) => (/^https?:\/\//.test(path) ? path : site.url.replace(/\/+$/, '') + path)
const yesNo = (flag) => (flag ? 'yes' : 'no')
// Vite escapes attribute values but writes a tag's children as they are.
const escapeHtml = (text) => text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

/** The document title: the site title, followed by the organisation when it differs. */
export function documentTitle(config) {
  const { site, metadata } = config
  return metadata.author && metadata.author !== site.title ? `${site.title} — ${metadata.author}` : site.title
}

/**
 * The <head> tags of a language's configuration, as Vite tag descriptors.
 * `others` are the site's configurations in its other languages, for the
 * alternate-language links.
 */
export function headTags(config, others = []) {
  const { site, metadata, icons, pwa } = config
  const title = documentTitle(config)
  const meta = (name, content) => ({ tag: 'meta', attrs: { name, content } })
  const property = (name, content) => ({ tag: 'meta', attrs: { property: name, content } })
  const link = (attrs) => ({ tag: 'link', attrs })
  const png = (size, href) => link({ rel: 'icon', type: 'image/png', sizes: `${size}x${size}`, href })
  const apple = (size, href) => link({ rel: 'apple-touch-icon', sizes: `${size}x${size}`, href })
  const image = absolute(site, metadata.default_social_image)
  return [
    { tag: 'title', children: escapeHtml(title) },
    meta('description', site.description),
    meta('robots', metadata.robots),
    ...(metadata.author ? [meta('author', metadata.author)] : []),
    link({ rel: 'canonical', href: site.url }),
    property('og:title', title),
    property('og:description', site.description),
    property('og:type', 'website'),
    property('og:url', site.url),
    property('og:image', image),
    ...(metadata.default_social_image_width
      ? [
          property('og:image:width', String(metadata.default_social_image_width)),
          property('og:image:height', String(metadata.default_social_image_height)),
        ]
      : []),
    property('og:image:alt', metadata.default_social_image_alt),
    property('og:site_name', site.title),
    property('og:locale', metadata.locale),
    ...others.map((other) => property('og:locale:alternate', other.metadata.locale)),
    ...(others.length > 0
      ? [config, ...others].map((c) => link({ rel: 'alternate', hreflang: c.lang, href: `${site.url}?lang=${c.lang}` }))
      : []),
    meta('twitter:card', metadata.twitter_card),
    ...(metadata.twitter_site ? [meta('twitter:site', metadata.twitter_site)] : []),
    meta('twitter:title', title),
    meta('twitter:description', site.description),
    meta('twitter:image', image),
    meta('theme-color', metadata.theme_color),
    meta('color-scheme', metadata.color_scheme),
    meta('format-detection', metadata.format_detection),
    meta('apple-mobile-web-app-capable', yesNo(pwa.apple_mobile_web_app_capable)),
    meta('apple-mobile-web-app-status-bar-style', pwa.apple_mobile_web_app_status_bar_style),
    meta('apple-mobile-web-app-title', pwa.apple_mobile_web_app_title),
    meta('mobile-web-app-capable', yesNo(pwa.mobile_web_app_capable)),
    meta('application-name', pwa.application_name),
    link({ rel: 'manifest', href: pwa.manifest_path }),
    link({ rel: 'icon', href: icons.favicon_ico, sizes: 'any' }),
    link({ rel: 'icon', type: 'image/svg+xml', href: icons.favicon_svg }),
    png(16, icons.favicon_16),
    png(32, icons.favicon_32),
    png(48, icons.favicon_48),
    png(64, icons.favicon_64),
    apple(120, icons.apple_touch_icon_120),
    apple(152, icons.apple_touch_icon_152),
    apple(167, icons.apple_touch_icon_167),
    apple(icons.apple_touch_icon_size, icons.apple_touch_icon),
    apple(192, icons.apple_touch_icon_192),
    apple(512, icons.apple_touch_icon_512),
    png(192, icons.android_chrome_192),
    png(512, icons.android_chrome_512),
  ].map((tag) => ({ ...tag, injectTo: 'head' }))
}

/** The web app manifest of a language's configuration. */
export function webManifest(config) {
  const { pwa, lang } = config
  const icon = (src, purpose) => ({ src, sizes: src === pwa.icons.icon_192 ? '192x192' : '512x512', type: 'image/png', purpose })
  return {
    name: pwa.application_name,
    short_name: pwa.short_name,
    description: pwa.description,
    lang,
    start_url: pwa.start_url,
    ...(pwa.scope ? { scope: pwa.scope } : {}),
    display: pwa.display,
    ...(pwa.orientation ? { orientation: pwa.orientation } : {}),
    background_color: pwa.background_color,
    theme_color: pwa.theme_color,
    icons: [icon(pwa.icons.icon_192, 'any'), icon(pwa.icons.icon_512, 'any'), icon(pwa.icons.maskable_icon, 'maskable')],
  }
}

/**
 * @param {{ config?: string }} options `config` is the path of config.toml,
 *   relative to the Vite root (default: one level above it).
 */
export default function siteConfig(options = {}) {
  let configPath
  let resolved
  const read = () => {
    resolved = load(configPath)
    return resolved
  }
  const defaultConfig = () => resolved.configs[resolved.default]
  const manifestJson = () => JSON.stringify(webManifest(defaultConfig()), null, 2)

  return {
    name: 'palikkaharrastajat-site-config',

    configResolved(viteConfig) {
      configPath = resolvePath(viteConfig.root, options.config ?? '../config.toml')
      read()
    },

    resolveId(id) {
      return id === VIRTUAL_ID ? RESOLVED_ID : null
    },

    load(id) {
      if (id !== RESOLVED_ID) return null
      this.addWatchFile(configPath)
      return `export default ${JSON.stringify(resolved)}`
    },

    transformIndexHtml(html) {
      const config = defaultConfig()
      return {
        html: html.replace(/<html\b[^>]*>/i, `<html lang="${config.lang}">`),
        tags: headTags(
          config,
          resolved.languages.filter((lang) => lang !== config.lang).map((lang) => resolved.configs[lang]),
        ),
      }
    },

    configureServer(server) {
      server.watcher.add(configPath)
      server.watcher.on('change', (file) => {
        if (resolvePath(file) !== configPath) return
        try {
          read()
        } catch (error) {
          server.config.logger.error(error.message)
          return
        }
        const module = server.moduleGraph.getModuleById(RESOLVED_ID)
        if (module) server.moduleGraph.invalidateModule(module)
        server.ws.send({ type: 'full-reload' })
      })
      server.middlewares.use((request, response, next) => {
        if (request.url?.split('?')[0] !== defaultConfig().pwa.manifest_path) return next()
        response.setHeader('Content-Type', 'application/manifest+json')
        response.end(manifestJson())
      })
    },

    generateBundle() {
      this.emitFile({
        type: 'asset',
        fileName: defaultConfig().pwa.manifest_path.replace(/^\/+/, ''),
        source: manifestJson(),
      })
    },
  }
}

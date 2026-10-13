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

import { headTags, webManifest } from './head.mjs'

export { documentTitle, headTags, webManifest } from './head.mjs'

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

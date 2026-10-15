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
// - The family's icons, social image and logos are served from the hub's
//   public/ directory, so apps do not keep copies. A file the app has in its
//   own public/ directory wins.

import { cpSync, createReadStream, existsSync, readdirSync, statSync } from 'node:fs'
import { dirname, extname, join, resolve as resolvePath } from 'node:path'
import { fileURLToPath } from 'node:url'
import { load, showHidden } from './site-config.mjs'

const VIRTUAL_ID = 'virtual:site-config'
const RESOLVED_ID = '\0' + VIRTUAL_ID

import { headTags, webManifest } from './head.mjs'

export { documentTitle, headTags, webManifest } from './head.mjs'

// The hub's public/ directory, and which of its entries every site shares:
// favicons and app icons, the social image, and the logo set.
const SHARED_DIR = resolvePath(dirname(fileURLToPath(import.meta.url)), '../../public')
const SHARED = /^(favicon[^/]*|icon-[^/]*|apple-touch-icon[^/]*|og-image\.[a-z]+|logo)$/
const MIME = {
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.webp': 'image/webp',
  '.ico': 'image/x-icon',
  '.gif': 'image/gif',
  '.jpg': 'image/jpeg',
}

/** The shared entries (files and directories) of the hub's public/ directory. */
export function sharedEntries(dir = SHARED_DIR) {
  return existsSync(dir) ? readdirSync(dir).filter((name) => SHARED.test(name)) : []
}

/**
 * @param {{ config?: string, sharedAssets?: boolean }} options `config` is the
 *   path of config.toml, relative to the Vite root (default: one level above
 *   it). `sharedAssets: false` turns the family's shared icons and logos off.
 */
export default function siteConfig(options = {}) {
  let configPath
  let resolved
  let outDir
  let serving = false
  const shared = options.sharedAssets === false ? [] : sharedEntries()
  const read = () => {
    // The dev server shows hidden languages, so they can be previewed; a build
    // leaves them out.
    resolved = serving ? showHidden(load(configPath)) : load(configPath)
    return resolved
  }
  const defaultConfig = () => resolved.configs[resolved.default]
  const manifestJson = () => JSON.stringify(webManifest(defaultConfig()), null, 2)

  return {
    name: 'palikkaharrastajat-site-config',

    configResolved(viteConfig) {
      configPath = resolvePath(viteConfig.root, options.config ?? '../config.toml')
      outDir = resolvePath(viteConfig.root, viteConfig.build.outDir)
      serving = viteConfig.command === 'serve'
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
        const path = decodeURIComponent(request.url?.split('?')[0] ?? '')
        if (path === defaultConfig().pwa.manifest_path) {
          response.setHeader('Content-Type', 'application/manifest+json')
          response.end(manifestJson())
          return
        }
        // Shared assets, unless the app has the file itself (Vite serves that).
        const [first, ...rest] = path.split('/').filter(Boolean)
        const file = first && shared.includes(first) && !rest.includes('..') ? join(SHARED_DIR, first, ...rest) : null
        const own = file && join(server.config.publicDir || '', first, ...rest)
        if (!file || existsSync(own) || !existsSync(file) || !statSync(file).isFile()) return next()
        response.setHeader('Content-Type', MIME[extname(file)] ?? 'application/octet-stream')
        createReadStream(file).pipe(response)
      })
    },

    generateBundle() {
      this.emitFile({
        type: 'asset',
        fileName: defaultConfig().pwa.manifest_path.replace(/^\/+/, ''),
        source: manifestJson(),
      })
    },

    // After Vite has copied the app's own public/ files: add the shared ones
    // it does not have.
    closeBundle() {
      if (!outDir || !existsSync(outDir)) return
      for (const entry of shared) {
        cpSync(join(SHARED_DIR, entry), join(outDir, entry), { recursive: true, force: false, errorOnExist: false })
      }
    },
  }
}

import assert from 'node:assert/strict'
import { EventEmitter } from 'node:events'
import { existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { test } from 'node:test'
import siteConfig, { sharedEntries } from './vite.mjs'

// A throw-away app: config.toml one level above the Vite root, its own
// public/ directory with one file that shadows a shared one, and an outDir.
function app() {
  const dir = mkdtempSync(join(tmpdir(), 'site-config-vite-'))
  const root = join(dir, 'elm-app')
  mkdirSync(join(root, 'public'), { recursive: true })
  mkdirSync(join(dir, 'dist'))
  writeFileSync(join(dir, 'config.toml'), '[site]\nurl = "https://x.example"\ntitle = "X"\ndescription = "D"\n')
  writeFileSync(join(root, 'public', 'favicon.svg'), 'own favicon')
  const plugin = siteConfig()
  plugin.configResolved({ root, build: { outDir: '../dist' } })
  return { dir, root, plugin }
}

// Runs the plugin's dev middleware for one request.
function request(plugin, root, url) {
  let middleware
  const server = {
    config: { publicDir: join(root, 'public'), logger: { error() {} } },
    watcher: { add() {}, on() {} },
    moduleGraph: { getModuleById() {} },
    ws: { send() {} },
    middlewares: { use: (fn) => (middleware = fn) },
  }
  plugin.configureServer(server)
  return new Promise((resolve) => {
    const response = new EventEmitter()
    const result = { headers: {}, body: null, next: false }
    response.setHeader = (name, value) => (result.headers[name] = value)
    response.end = (body) => resolve({ ...result, body: body ?? '' })
    response.write = () => true
    response.on('pipe', () => resolve({ ...result, body: 'stream' }))
    middleware({ url }, response, () => resolve({ ...result, next: true }))
  })
}

test('the hub shares its icons, social image, logos and fonts, and nothing else', () => {
  const shared = sharedEntries()
  for (const name of ['favicon.svg', 'favicon.ico', 'icon-192.png', 'apple-touch-icon.png', 'og-image.png', 'logo', 'fonts']) {
    assert.ok(shared.includes(name), `${name} should be shared`)
  }
  for (const name of ['vendor', 'site-config.json', 'robots.txt']) {
    assert.equal(shared.includes(name), false, `${name} should not be shared`)
  }
})

test('the dev server serves the manifest and shared files the app does not have', async () => {
  const { root, plugin } = app()
  const manifest = await request(plugin, root, '/site.webmanifest')
  assert.equal(manifest.headers['Content-Type'], 'application/manifest+json')
  assert.equal(JSON.parse(manifest.body).name, 'X')

  const icon = await request(plugin, root, '/icon-192.png?v=1')
  assert.equal(icon.headers['Content-Type'], 'image/png')
  assert.equal(icon.next, false)

  const logo = await request(plugin, root, '/logo/square/svg/square-smile.svg')
  assert.equal(logo.headers['Content-Type'], 'image/svg+xml')

  const font = await request(plugin, root, '/fonts/Outfit-VariableFont_wght.woff2')
  assert.equal(font.headers['Content-Type'], 'font/woff2')
  assert.equal(font.next, false)

  const css = await request(plugin, root, '/fonts/outfit.css')
  assert.equal(css.headers['Content-Type'], 'text/css; charset=utf-8')
  assert.equal(css.next, false)

  const licence = await request(plugin, root, '/fonts/OFL.txt')
  assert.equal(licence.headers['Content-Type'], 'text/plain; charset=utf-8')
  assert.equal(licence.next, false)
})

test("the dev server leaves an app's own font file to Vite", async () => {
  const { root, plugin } = app()
  mkdirSync(join(root, 'public', 'fonts'))
  writeFileSync(join(root, 'public', 'fonts', 'outfit.css'), 'own css')
  assert.equal((await request(plugin, root, '/fonts/outfit.css')).next, true)
  assert.equal((await request(plugin, root, '/fonts/OFL.txt')).next, false)
})

test("the dev server leaves the app's own files, other paths and traversal to Vite", async () => {
  const { root, plugin } = app()
  for (const url of ['/favicon.svg', '/main.js', '/fonts/missing.woff2', '/fonts/../package.json', '/logo/../../package.json', '/logo/missing.svg', '/logo']) {
    assert.equal((await request(plugin, root, url)).next, true, url)
  }
})

test("the build adds the shared files without replacing the app's own", () => {
  const { dir, plugin } = app()
  // Vite has copied the app's public/ files by the time closeBundle runs.
  writeFileSync(join(dir, 'dist', 'favicon.svg'), 'own favicon')
  plugin.closeBundle()
  assert.equal(readFileSync(join(dir, 'dist', 'favicon.svg'), 'utf8'), 'own favicon')
  assert.ok(existsSync(join(dir, 'dist', 'icon-192.png')))
  assert.ok(existsSync(join(dir, 'dist', 'logo', 'square', 'svg', 'square-smile.svg')))
  for (const name of ['Outfit-VariableFont_wght.woff2', 'Outfit-VariableFont_wght.ttf', 'OFL.txt', 'outfit.css']) {
    assert.ok(existsSync(join(dir, 'dist', 'fonts', name)), `dist/fonts/${name}`)
  }
})

test("the build does not replace the app's own font file", () => {
  const { dir, plugin } = app()
  mkdirSync(join(dir, 'dist', 'fonts'))
  writeFileSync(join(dir, 'dist', 'fonts', 'outfit.css'), 'own css')
  plugin.closeBundle()
  assert.equal(readFileSync(join(dir, 'dist', 'fonts', 'outfit.css'), 'utf8'), 'own css')
})

test('shared assets can be turned off', () => {
  const dir = mkdtempSync(join(tmpdir(), 'site-config-vite-'))
  mkdirSync(join(dir, 'elm-app'))
  mkdirSync(join(dir, 'dist'))
  writeFileSync(join(dir, 'config.toml'), '[site]\nurl = "https://x.example"\ntitle = "X"\ndescription = "D"\n')
  const plugin = siteConfig({ sharedAssets: false })
  plugin.configResolved({ root: join(dir, 'elm-app'), build: { outDir: '../dist' } })
  plugin.closeBundle()
  assert.equal(existsSync(join(dir, 'dist', 'icon-192.png')), false)
})

test('the dev server shows hidden languages and the build leaves them out', async () => {
  const dir = mkdtempSync(join(tmpdir(), 'site-config-vite-'))
  mkdirSync(join(dir, 'elm-app'))
  writeFileSync(
    join(dir, 'config.toml'),
    '[i18n]\ndefault = "fi"\nlanguages = ["fi", "en"]\nhidden = ["en"]\n' +
      '[site]\nurl = "https://x.example"\ntitle = "X"\ndescription = "D"\n[site.en]\ntitle = "X"\ndescription = "D"\n',
  )
  const languages = (command) => {
    const plugin = siteConfig({ sharedAssets: false })
    plugin.configResolved({ root: join(dir, 'elm-app'), build: { outDir: '../dist' }, command })
    const module = plugin.load.call({ addWatchFile() {} }, '\0virtual:site-config').replace(/^export default /, '')
    const alternates = plugin.transformIndexHtml('<html>').tags.filter((t) => t.attrs?.property === 'og:locale:alternate')
    return { languages: JSON.parse(module).languages, alternates: alternates.length }
  }
  assert.deepEqual(languages('build'), { languages: ['fi'], alternates: 0 })
  assert.deepEqual(languages('serve'), { languages: ['fi', 'en'], alternates: 1 })
})

import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { test } from 'node:test'
import { headTags } from './head.mjs'
import { FAMILY_PATH, resolve } from './site-config.mjs'
import { parse } from './vendor/smol-toml/index.js'

const siteConfig = resolve(
  parse(readFileSync(new URL('./fixtures/bilingual.toml', import.meta.url), 'utf8')),
  parse(readFileSync(FAMILY_PATH, 'utf8')),
  { year: 2026 },
)

// A fresh copy of the module per test: it remembers the request it has read.
let copy = 0
const load = () => import(`./browser.mjs?copy=${copy++}`)

// The few browser objects the helpers touch.
function browser(address, stored = {}, { storageWorks = true } = {}) {
  const state = { url: address, storage: { ...stored }, lang: 'fi', meta: [] }
  globalThis.window = {
    location: {
      get href() {
        return state.url
      },
    },
    history: { state: null, replaceState: (_state, _title, url) => (state.url = String(url)) },
    localStorage: {
      getItem: (key) => {
        if (!storageWorks) throw new Error('blocked')
        return state.storage[key] ?? null
      },
      setItem: (key, value) => {
        if (!storageWorks) throw new Error('blocked')
        state.storage[key] = value
      },
    },
  }
  globalThis.document = {
    documentElement: {
      set lang(value) {
        state.lang = value
      },
    },
    head: {
      querySelectorAll: (selector) => state.meta.filter((m) => m.selector === selector),
    },
  }
  return state
}

test('a request in the address is used, remembered and removed from the address', async () => {
  const state = browser('https://x.example/?a=1&lang=en#/events')
  const { requestedLang, pickLang } = await load()
  assert.equal(requestedLang(siteConfig), 'en')
  assert.equal(state.storage.lang, 'en')
  assert.equal(state.url, 'https://x.example/?a=1#/events')
  assert.equal(pickLang(siteConfig), 'en', 'a second read gives the same answer')
})

test('an earlier choice is used when the address has none', async () => {
  browser('https://x.example/', { lang: 'en' })
  const { pickLang } = await load()
  assert.equal(pickLang(siteConfig), 'en')
})

test('a language the site does not declare is ignored and does not replace the choice', async () => {
  const state = browser('https://x.example/?lang=sv', { lang: 'en' })
  const { requestedLang } = await load()
  assert.equal(requestedLang(siteConfig), 'en')
  assert.equal(state.storage.lang, 'en')
  assert.equal(state.url, 'https://x.example/')
})

test('without a request the site default is shown', async () => {
  browser('https://x.example/')
  const { requestedLang, pickLang } = await load()
  assert.equal(requestedLang(siteConfig), null)
  assert.equal(pickLang(siteConfig), 'fi')
})

test('blocked storage does not break a request in the address', async () => {
  browser('https://x.example/?lang=en', {}, { storageWorks: false })
  const { requestedLang, pickLang } = await load()
  assert.equal(requestedLang(siteConfig), 'en')
  assert.equal(pickLang(siteConfig), 'en')
})

test('appSettings gives the [app] table of a language', async () => {
  browser('https://x.example/')
  const { appSettings } = await load()
  assert.equal(appSettings(siteConfig, 'en').pocketbase_url, 'https://data.palikkaharrastajat.fi')
})

test('showLanguage sets the document language and rewrites the head tags', async () => {
  const state = browser('https://x.example/')
  // The static page: the Finnish head, as the Vite plugin wrote it.
  state.meta = headTags(siteConfig.configs.fi, [siteConfig.configs.en])
    .filter((tag) => tag.tag === 'meta')
    .map((tag) => ({
      selector: tag.attrs.name ? `meta[name="${tag.attrs.name}"]` : `meta[property="${tag.attrs.property}"]`,
      content: tag.attrs.content,
      setAttribute(_name, value) {
        this.content = value
      },
    }))
  const content = (selector) => state.meta.find((m) => m.selector === selector).content
  const { showLanguage } = await load()
  showLanguage(siteConfig, 'en')
  assert.equal(state.lang, 'en')
  assert.equal(content('meta[name="description"]'), 'Event calendar of Suomen Palikkaharrastajat ry')
  assert.equal(content('meta[property="og:locale"]'), 'en_GB')
  assert.equal(content('meta[property="og:locale:alternate"]'), 'fi_FI')
  assert.equal(content('meta[property="og:title"]'), 'Brick Calendar — Suomen Palikkaharrastajat ry')
})

import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { test } from 'node:test'
import { FAMILY_PATH, load, resolve, SiteConfigError } from './site-config.mjs'
import { parse } from './vendor/smol-toml/index.js'

const family = parse(readFileSync(FAMILY_PATH, 'utf8'))
const site = (extra = '') =>
  parse(`
[site]
url = "https://kalenteri.palikkaharrastajat.fi"
title = "Palikkakalenteri"
description = "Tapahtumakalenteri"
${extra}`)

const problems = (toml, fam = family) => {
  try {
    resolve(parse(toml), fam, { year: 2026 })
  } catch (error) {
    assert.ok(error instanceof SiteConfigError, String(error))
    return error.problems
  }
  return []
}

test('a file without [i18n] is a Finnish-only site', () => {
  const resolved = resolve(site(), family, { year: 2026 })
  assert.equal(resolved.default, 'fi')
  assert.deepEqual(resolved.languages, ['fi'])
  assert.deepEqual(Object.keys(resolved.configs), ['fi'])
  assert.equal(resolved.configs.fi.lang, 'fi')
})

test('family defaults fill everything a site leaves out', () => {
  const { fi } = resolve(site(), family, { year: 2031 }).configs
  assert.equal(fi.footer.site_label, 'Palikkaharrastajat')
  assert.equal(fi.footer.copyright, '© 2031 Suomen Palikkaharrastajat ry')
  assert.equal(fi.branding.logo_square, '/logo/square/svg/square-smile.svg')
  assert.equal(fi.pwa.application_name, 'Palikkakalenteri')
  assert.equal(fi.pwa.description, 'Tapahtumakalenteri')
  assert.equal(fi.icons.favicon_16, '/favicon-16x16.png')
})

test('family footer links are canonical and never link to the site itself', () => {
  const { fi } = resolve(site(), family, { year: 2026 }).configs
  assert.deepEqual(
    fi.footer.links.map((l) => l.label),
    ['Kotisivut', 'Palikkakartta', 'Palikkalinkit', 'Palikkaoppaat', 'Jäsenfoorumi', 'Jäsenkortti', 'Jäsenmaksu', 'Tietosuoja'],
  )
})

test('the canonical family link list is pinned', () => {
  assert.deepEqual(family.footer.links, [
    { label: 'Kotisivut', href: 'https://palikkaharrastajat.fi' },
    { label: 'Palikkakalenteri', href: 'https://kalenteri.palikkaharrastajat.fi' },
    { label: 'Palikkakartta', href: 'https://kartta.palikkaharrastajat.fi' },
    { label: 'Palikkalinkit', href: 'https://linkit.palikkaharrastajat.fi' },
    { label: 'Palikkaoppaat', href: 'https://oppaat.palikkaharrastajat.fi' },
    { label: 'Jäsenfoorumi', href: 'https://forum.palikkaharrastajat.fi' },
    { label: 'Jäsenkortti', href: 'https://kortti.palikkaharrastajat.fi' },
    { label: 'Jäsenmaksu', href: 'https://maksut.palikkaharrastajat.fi' },
    { label: 'Tietosuoja', href: 'https://palikkaharrastajat.fi/tietosuoja' },
  ])
})

test("a site's own footer links replace the family list unfiltered", () => {
  const own = site(`
[footer]
links = [{ label = "Oma", href = "https://kalenteri.palikkaharrastajat.fi" }]`)
  const { fi } = resolve(own, family, { year: 2026 }).configs
  assert.deepEqual(fi.footer.links, [{ label: 'Oma', href: 'https://kalenteri.palikkaharrastajat.fi' }])
})

test('another language is resolved from its sub-tables and the family translation', () => {
  const resolved = resolve(
    site(`
[i18n]
default = "fi"
languages = ["fi", "en"]
[site.en]
title = "Brick Calendar"
description = "Event calendar"
[app]
pocketbase_url = "https://data.palikkaharrastajat.fi"
[app.strings]
motto = "Rakennetaan"
[app.en.strings]
motto = "Let's build"`),
    family,
    { year: 2026 },
  )
  const { fi, en } = resolved.configs
  assert.equal(en.site.title, 'Brick Calendar')
  assert.equal(en.site.url, fi.site.url)
  assert.equal(en.metadata.locale, 'en_GB')
  assert.equal(en.footer.disclaimer[0], 'LEGO® is a registered trademark of the LEGO Group.')
  assert.deepEqual(
    en.footer.links.map((l) => l.href),
    fi.footer.links.map((l) => l.href),
  )
  assert.equal(en.footer.links[0].label, 'Homepage')
  assert.equal(fi.app.strings.motto, 'Rakennetaan')
  assert.equal(en.app.strings.motto, "Let's build")
  assert.equal(en.app.pocketbase_url, 'https://data.palikkaharrastajat.fi')
})

const bilingual = `
[i18n]
default = "fi"
languages = ["fi", "en"]
[site]
url = "https://x.example"
title = "Otsikko"
description = "Kuvaus"
`

test('no silent fallback: text set for the default language must be translated', () => {
  assert.deepEqual(problems(bilingual + '[site.en]\ntitle = "Title"\n'), [
    'config.toml: [site.en] description is missing (set in [site] for "fi")',
  ])
})

test('the default language has no sub-table of its own', () => {
  assert.match(problems('[site]\nurl="u"\ntitle="t"\ndescription="d"\n[site.fi]\ntitle = "x"\n')[0], /is the default language/)
})

test('a language table must be declared in [i18n] languages', () => {
  assert.match(problems('[site]\nurl="u"\ntitle="t"\ndescription="d"\n[site.en]\ntitle = "x"\n')[0], /"en" is not listed/)
})

test('language-neutral keys are rejected inside a language table', () => {
  const found = problems(bilingual + '[site.en]\ntitle = "T"\ndescription = "D"\nurl = "https://y.example"\n')
  assert.deepEqual(found, ['config.toml: [site.en] url is language-neutral; put it in [site]'])
})

test('unknown sections, keys and wrong types are rejected', () => {
  const found = problems('[site]\nurl="u"\ntitle="t"\ndescription="d"\nsubtitle="s"\n[navbar]\nsticky="yes"\n[sidebar]\nx=1\n')
  assert.deepEqual(found, [
    'config.toml: unknown section [sidebar]',
    'config.toml: unknown key [site] subtitle',
    'config.toml: [navbar] sticky must be of type bool',
  ])
})

test('required text is reported per language', () => {
  assert.deepEqual(problems('[site]\nurl="u"\n'), [
    '[site] title is missing for language "fi"',
    '[site] description is missing for language "fi"',
  ])
})

test('translated link lists must keep the same targets in the same order', () => {
  const found = problems(
    bilingual +
      `[site.en]
title = "T"
description = "D"
[footer]
links = [{ label = "A", href = "https://a.example" }, { label = "B", href = "https://b.example" }]
[footer.en]
links = [{ label = "B", href = "https://b.example" }, { label = "A", href = "https://a.example" }]
`,
  )
  assert.deepEqual(found, ['[footer.en] links must have the same targets, in the same order, as [footer] links'])
})

test('navbar variant is one of the known layouts', () => {
  assert.match(problems('[site]\nurl="u"\ntitle="t"\ndescription="d"\n[navbar]\nvariant="wide"\n')[0], /variant must be one of/)
})

test('the template config resolves', () => {
  const resolved = load(new URL('../../template/config.toml', import.meta.url).pathname, { year: 2026 })
  assert.equal(resolved.configs.fi.site.title, 'Suomen Palikkaharrastajat ry')
  assert.equal(resolved.configs.fi.footer.links.length, 5)
})

// ── Vite plugin output ───────────────────────────────────────────────────────

import { documentTitle, headTags, webManifest } from './vite.mjs'

const calendar = resolve(site(), family, { year: 2026 }).configs.fi

test('document title names the site and the organisation', () => {
  assert.equal(documentTitle(calendar), 'Palikkakalenteri — Suomen Palikkaharrastajat ry')
})

test('head tags come from the configuration', () => {
  const tags = headTags(calendar)
  const find = (predicate) => tags.find(predicate)?.attrs
  assert.equal(find((t) => t.attrs?.rel === 'canonical').href, 'https://kalenteri.palikkaharrastajat.fi')
  assert.equal(find((t) => t.attrs?.property === 'og:image').content, 'https://kalenteri.palikkaharrastajat.fi/og-image.png')
  assert.equal(find((t) => t.attrs?.name === 'theme-color').content, '#05131D')
  assert.equal(find((t) => t.attrs?.sizes === '16x16').href, '/favicon-16x16.png')
  assert.equal(find((t) => t.attrs?.rel === 'manifest').href, '/site.webmanifest')
})

test('web manifest comes from the configuration', () => {
  const manifest = webManifest(calendar)
  assert.equal(manifest.name, 'Palikkakalenteri')
  assert.equal(manifest.lang, 'fi')
  assert.deepEqual(
    manifest.icons.map((i) => [i.sizes, i.purpose]),
    [
      ['192x192', 'any'],
      ['512x512', 'any'],
      ['512x512', 'maskable'],
    ],
  )
})

// ── Nested tables and [app] ──────────────────────────────────────────────────

test('a site overrides one value of a nested table without losing the rest', () => {
  const { fi } = resolve(site('[pwa.icons]\nicon_192 = "/own-192.png"\n'), family, { year: 2026 }).configs
  assert.deepEqual(fi.pwa.icons, { icon_192: '/own-192.png', icon_512: '/icon-512.png', maskable_icon: '/icon-maskable.png' })
})

test('[app] language tables follow the same rules as the other sections', () => {
  assert.match(problems('[site]\nurl="u"\ntitle="t"\ndescription="d"\n[app.fi]\nx = "1"\n')[0], /\[app\.fi\] is the default language/)
  assert.match(problems('[site]\nurl="u"\ntitle="t"\ndescription="d"\n[app.en]\nx = "1"\n')[0], /\[app\.en\] but "en" is not listed/)
})

test('a table translated in [app.<lang>] must be translated completely', () => {
  const found = problems(
    bilingual +
      `[site.en]
title = "T"
description = "D"
[app.strings]
open = "Avaa"
close = "Sulje"
[app.en.strings]
open = "Open"
`,
  )
  assert.deepEqual(found, ['config.toml: [app.en.strings] close is missing (set in [app.strings] for "fi")'])
})

test('a language keeps the language-neutral [app] values', () => {
  const { en } = resolve(
    parse(bilingual + '[site.en]\ntitle = "T"\ndescription = "D"\n[app]\nurl = "https://x"\n[app.strings]\na = "A"\n[app.en.strings]\na = "B"\n'),
    family,
    { year: 2026 },
  ).configs
  assert.deepEqual(en.app, { url: 'https://x', strings: { a: 'B' } })
})

test('only languages the shared code knows can be declared', () => {
  assert.match(problems('[i18n]\ndefault = "fi"\nlanguages = ["fi", "sv"]\n[site]\nurl="u"\ntitle="t"\ndescription="d"\n')[0], /language "sv" is not supported/)
})

test('required text may not be empty', () => {
  assert.deepEqual(problems('[site]\nurl="u"\ntitle=""\ndescription="d"\n'), ['[site] title is empty for language "fi"'])
})

test('a bilingual head links its languages and the title is escaped', () => {
  const resolved = resolve(parse(bilingual.replace('"Otsikko"', '"A & B"') + '[site.en]\ntitle = "T"\ndescription = "D"\n'), family, { year: 2026 })
  const tags = headTags(resolved.configs.fi, [resolved.configs.en])
  assert.equal(tags.find((t) => t.tag === 'title').children, 'A &amp; B — Suomen Palikkaharrastajat ry')
  assert.deepEqual(
    tags.filter((t) => t.attrs?.rel === 'alternate').map((t) => [t.attrs.hreflang, t.attrs.href]),
    [
      ['fi', 'https://x.example?lang=fi'],
      ['en', 'https://x.example?lang=en'],
    ],
  )
  assert.equal(tags.find((t) => t.attrs?.property === 'og:locale:alternate').attrs.content, 'en_GB')
})

test('manifest scope and orientation are optional', () => {
  assert.equal('scope' in webManifest(calendar), false)
  const { fi } = resolve(site('[pwa]\nscope = "/"\norientation = "portrait"\n'), family, { year: 2026 }).configs
  assert.equal(webManifest(fi).scope, '/')
  assert.equal(webManifest(fi).orientation, 'portrait')
})

test('every field the Elm decoder needs is required of the family defaults', () => {
  const bare = { metadata: { locale: 'fi_FI' }, footer: { logo: '/l.svg', site_label: 'L', copyright: 'C', links: [] } }
  const found = problems('[site]\nurl="u"\ntitle="t"\ndescription="d"\n', bare)
  assert.ok(found.includes('[icons] favicon_ico is missing for language "fi"'), found.join('\n'))
  assert.ok(found.includes('[admin] enabled is missing for language "fi"'))
  assert.ok(found.includes('[navbar] show_desktop_search is missing for language "fi"'))
  assert.ok(found.includes('[pwa.icons] icon_192 is missing'))
  assert.equal(found.some((p) => p.includes('twitter_site') || p.includes('[pwa] scope')), false)
})

// ── Malformed files ──────────────────────────────────────────────────────────

const minimal = '[site]\nurl="u"\ntitle="t"\ndescription="d"\n'

test('a broken [i18n] is reported, not crashed on', () => {
  assert.deepEqual(problems('[i18n]\ndefault = "en"\nlanguages = ["fi"]\n' + minimal), [
    'config.toml: [i18n] default "en" is not listed in languages',
  ])
  assert.match(problems('[i18n]\nlanguages = []\n' + minimal)[0], /non-empty list/)
  assert.match(problems('[i18n]\ndefault = 3\n' + minimal)[0], /languages must be a non-empty list|default 3 is not listed/)
})

test('a section that is not a table is rejected', () => {
  assert.deepEqual(problems('footer = 3\napp = "x"\ni18n = true\n' + minimal), [
    'config.toml: [footer] must be a table',
    'config.toml: [app] must be a table',
    'config.toml: [i18n] must be a table',
  ])
})

test('[app] text lives in its text tables, complete for every language', () => {
  const translated = '[site.en]\ntitle = "T"\ndescription = "D"\n'
  assert.deepEqual(problems(bilingual + translated + '[app.strings]\nrefresh = "Päivitä"\n'), [
    'config.toml: [app.en.strings] is missing (text is set in [app.strings] for "fi")',
  ])
  assert.deepEqual(problems(bilingual + translated + '[app]\nlabel = "Päivitä"\n[app.en]\nlabel = "Refresh"\n'), [
    'config.toml: [app.en] label: only [app.en.strings] and [app.en.statics] can be set per language; text belongs in [app.strings]',
  ])
  assert.deepEqual(
    problems(bilingual + translated + '[app.strings]\na = "A"\nlist = ["x"]\n[app.en.strings]\na = "B"\nlist = "x"\nextra = "E"\n'),
    [
      'config.toml: [app.en.strings] list must be a list like in [app.strings]',
      'config.toml: [app.en.strings] extra is not in [app.strings]',
    ],
  )
})

test('links must be set for every language or for none', () => {
  const found = problems(
    bilingual +
      '[site.en]\ntitle = "T"\ndescription = "D"\n[footer.en]\nlinks = [{ label = "Homepage", href = "https://palikkaharrastajat.fi" }]\n',
  )
  assert.deepEqual(found, ['config.toml: links are set in [footer.en] but not in [footer]; set them for every language or for none'])
})

test('links need a label and a target and nothing else', () => {
  assert.match(problems(minimal + '[footer]\nlinks = [{ label = "", href = "https://a.example" }]\n')[0], /\[footer\] links must be of type links/)
  assert.match(problems(minimal + '[footer]\nlinks = [{ label = "A", href = "https://a.example", extra = 1 }]\n')[0], /must be of type links/)
})

test('[pwa.icons] is checked like the other tables', () => {
  assert.deepEqual(problems(minimal + '[pwa.icons]\nicon_192 = 5\nicon_1024 = "/x.png"\n'), [
    '[pwa.icons] icon_192 must be of type string',
    'unknown key [pwa.icons] icon_1024',
  ])
})

test('a single string is accepted where a list of strings is expected', () => {
  const { fi } = resolve(site('[footer]\ndisclaimer = "Yksi rivi"\n'), family, { year: 2026 }).configs
  assert.deepEqual(fi.footer.disclaimer, ['Yksi rivi'])
})

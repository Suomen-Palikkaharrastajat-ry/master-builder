#!/usr/bin/env node
// Writes a Haskell module holding a site's resolved configuration, so the
// static generators (feeds, iCal, HTML exports) use the same config.toml as
// the app instead of repeating its URL, title and text.
//
// usage: gen-haskell.mjs --config <config.toml> --out <SiteConfig.hs> [--check]
//
// The module exposes the site's languages as `Lang`, its language-neutral
// values as plain strings, its translatable values as `Lang -> String`, and
// every string (or list of strings) in `[app]` and `[app.statics]` under a
// camelCase name (`[app.statics] add_to_calendar` → `staticsAddToCalendar`).
// Month and weekday names come from the hub's locales.json, the same table
// the Elm `Locale` is tested against.
// `--check` fails when the file is out of date instead of writing it.
import { existsSync, readFileSync, writeFileSync } from 'node:fs'
import { basename, relative, resolve } from 'node:path'
import { allLanguages, load, SiteConfigError } from './site-config.mjs'

// A configuration problem is the user's to fix: print it, not a stack trace.
function loadOrExit(path, options) {
  try {
    return load(path, options)
  } catch (error) {
    if (!(error instanceof SiteConfigError)) throw error
    console.error(`${path}: ${error.message}`)
    process.exit(1)
  }
}

const locales = JSON.parse(readFileSync(new URL('./locales.json', import.meta.url), 'utf8'))

const option = (name) => {
  const index = process.argv.indexOf(name)
  return index === -1 ? null : resolve(process.argv[index + 1])
}
const configPath = option('--config')
const target = option('--out')
if (!configPath || !target) {
  console.error('usage: gen-haskell.mjs --config <config.toml> --out <SiteConfig.hs> [--check]')
  process.exit(2)
}

const resolved = loadOrExit(configPath)
const langs = allLanguages(resolved)
const con = (lang) => lang[0].toUpperCase() + lang.slice(1)
const camel = (prefix, key) =>
  prefix + key.replace(/(^|_)([a-z0-9])/g, (_, __, c) => c.toUpperCase())
const hs = (value) =>
  '"' +
  [...String(value)]
    .map((ch) => {
      const code = ch.codePointAt(0)
      if (ch === '"' || ch === '\\') return '\\' + ch
      return code < 32 || code > 126 ? `\\${code}\\&` : ch
    })
    .join('') +
  '"'
const hsValue = (value) => (Array.isArray(value) ? `[${value.map(hs).join(', ')}]` : hs(value))
const isText = (value) => typeof value === 'string' || (Array.isArray(value) && value.every((x) => typeof x === 'string'))

const definitions = []
const problems = []
// snake_case with single underscores, so two keys cannot map to one name.
const KEY = /^[a-z][a-z0-9]*(_[a-z0-9]+)*$/
// Lists the generators index by position must have a fixed length.
const shape = (value) => (Array.isArray(value) ? 'list' : 'string')
const constant = (name, doc, value) =>
  definitions.push({ name, text: `-- | ${doc}\n${name} :: String\n${name} = ${hs(value)}` })
const perLang = (name, doc, get) => {
  if (definitions.some((d) => d.name === name)) {
    problems.push(`two keys map to the Haskell name ${name}`)
    return
  }
  const sample = get(resolved.configs[resolved.default])
  for (const lang of langs) {
    const value = get(resolved.configs[lang])
    if (!isText(value) || shape(value) !== shape(sample)) {
      problems.push(`${name}: the value for "${lang}" is not a ${shape(sample)} like the one for "${resolved.default}"`)
      return
    }
  }
  const type = Array.isArray(sample) ? '[String]' : 'String'
  const clauses = langs.map((lang) => `${name} ${con(lang)} = ${hsValue(get(resolved.configs[lang]))}`)
  definitions.push({ name, text: `-- | ${doc}\n${name} :: Lang -> ${type}\n${clauses.join('\n')}` })
}

definitions.push({
  name: 'langCode',
  text: `-- | The two-letter code of a language.\nlangCode :: Lang -> String\n${langs.map((lang) => `langCode ${con(lang)} = ${hs(lang)}`).join('\n')}`,
})
constant('siteUrl', '@[site] url@, without a trailing slash.', resolved.configs[resolved.default].site.url.replace(/\/+$/, ''))
perLang('siteTitle', '@[site] title@.', (c) => c.site.title)
perLang('siteDescription', '@[site] description@.', (c) => c.site.description)
perLang('author', '@[metadata] author@: the organisation behind the site.', (c) => c.metadata.author ?? '')

for (const lang of langs) {
  if (!locales[lang]) problems.push(`locales.json has no names for "${lang}"`)
}
if (problems.length === 0) {
  perLang('monthNames', 'Month names, January first.', (c) => locales[c.lang].months)
  perLang('weekdayAbbrs', 'Weekday abbreviations, Monday first.', (c) => locales[c.lang].weekdays)
}

const app = resolved.configs[resolved.default].app
const addTable = (table, prefix, where, get) => {
  for (const [key, value] of Object.entries(table)) {
    if (!isText(value)) continue
    if (!KEY.test(key)) {
      problems.push(`${where} ${key}: keys used by the generators must match ${KEY}`)
      continue
    }
    perLang(camel(prefix, key), `@${where} ${key}@.`, (c) => get(c)?.[key])
  }
}
addTable(app, 'app', '[app]', (c) => c.app)
addTable(app.statics ?? {}, 'statics', '[app.statics]', (c) => c.app.statics)

if (problems.length > 0) {
  console.error(`${relative(process.cwd(), configPath)} cannot be turned into a Haskell module:`)
  for (const problem of problems) console.error('  - ' + problem)
  process.exit(1)
}

const source = `{- | The site's resolved configuration.

Generated by packages/site-config/gen-haskell.mjs from ${basename(configPath)}. Do not edit;
change ${basename(configPath)} and regenerate.

i18n-exempt: generated from ${basename(configPath)}, where the text lives.
-}
module SiteConfig (
    Lang (..),
    defaultLang,
${definitions.map((d) => `    ${d.name},`).join('\n')}
) where

-- | The languages the site declares in @[i18n] languages@, hidden ones included.
data Lang = ${langs.map(con).join(' | ')}
    deriving (Eq, Show)

-- | @[i18n] default@: the language static files are generated in.
defaultLang :: Lang
defaultLang = ${con(resolved.default)}

${definitions.map((d) => d.text).join('\n\n')}
`

if (process.argv.includes('--check')) {
  if (!existsSync(target) || readFileSync(target, 'utf8') !== source) {
    console.error(`${relative(process.cwd(), target)} is out of date; regenerate it with gen-haskell.mjs`)
    process.exit(1)
  }
} else {
  writeFileSync(target, source)
}

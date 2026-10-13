// Loads a site's config.toml, layers it on the family defaults and resolves
// one complete configuration per language.
//
// Text in the default language sits directly in a section ([site] title);
// another language's text sits in a sub-table named after it ([site.en] title).
// Language-neutral keys (URLs, paths, colours, flags) only ever sit directly
// in the section. See docs/site-config.md.

import { readFileSync } from 'node:fs'
import { dirname, resolve as resolvePath } from 'node:path'
import { fileURLToPath } from 'node:url'
import { parse } from './vendor/smol-toml/index.js'

export const FAMILY_PATH = resolvePath(dirname(fileURLToPath(import.meta.url)), 'family.toml')

export class SiteConfigError extends Error {
  constructor(problems) {
    super('Invalid site configuration:\n' + problems.map((p) => '  - ' + p).join('\n'))
    this.name = 'SiteConfigError'
    this.problems = problems
  }
}

// Each key is either language-neutral or translatable, never both.
// Types: string, bool, int, strings (list of strings), links (list of
// { label, href }), table (nested, language-neutral).
export const SCHEMA = {
  site: {
    neutral: { url: 'string' },
    translatable: { title: 'string', description: 'string' },
  },
  metadata: {
    neutral: {
      robots: 'string',
      theme_color: 'string',
      color_scheme: 'string',
      format_detection: 'string',
      default_social_image: 'string',
      default_social_image_width: 'int',
      default_social_image_height: 'int',
      twitter_card: 'string',
      twitter_site: 'string',
    },
    translatable: { author: 'string', locale: 'string', default_social_image_alt: 'string' },
  },
  icons: {
    neutral: {
      favicon_ico: 'string',
      favicon_svg: 'string',
      favicon_16: 'string',
      favicon_32: 'string',
      favicon_48: 'string',
      favicon_64: 'string',
      apple_touch_icon_120: 'string',
      apple_touch_icon_152: 'string',
      apple_touch_icon_167: 'string',
      apple_touch_icon: 'string',
      apple_touch_icon_size: 'int',
      apple_touch_icon_192: 'string',
      apple_touch_icon_512: 'string',
      android_chrome_192: 'string',
      android_chrome_512: 'string',
    },
    translatable: {},
  },
  pwa: {
    neutral: {
      manifest_path: 'string',
      start_url: 'string',
      display: 'string',
      scope: 'string',
      orientation: 'string',
      background_color: 'string',
      theme_color: 'string',
      mobile_web_app_capable: 'bool',
      apple_mobile_web_app_capable: 'bool',
      apple_mobile_web_app_status_bar_style: 'string',
      icons: 'table',
    },
    translatable: {
      application_name: 'string',
      short_name: 'string',
      description: 'string',
      apple_mobile_web_app_title: 'string',
    },
  },
  branding: {
    neutral: {
      logo_light: 'string',
      logo_light_mobile: 'string',
      logo_dark: 'string',
      logo_dark_mobile: 'string',
      logo_square: 'string',
    },
    translatable: { logo_alt: 'string' },
  },
  navbar: {
    neutral: { sticky: 'bool', variant: 'string', show_desktop_search: 'bool' },
    translatable: { links: 'links' },
  },
  admin: {
    neutral: {
      enabled: 'bool',
      path: 'string',
      content_owner: 'string',
      content_repo: 'string',
      content_branch: 'string',
      content_path: 'string',
    },
    translatable: {},
  },
  footer: {
    neutral: { logo: 'string' },
    translatable: { site_label: 'string', copyright: 'string', disclaimer: 'strings', links: 'links' },
  },
}

// Keys a configuration may lack. Every other key of the schema must be there
// for each language once the family defaults are applied, because the Elm
// decoder (SiteSettings.elm) has no fallbacks.
const OPTIONAL = {
  metadata: ['author', 'twitter_site', 'default_social_image_width', 'default_social_image_height', 'default_social_image_alt'],
  pwa: ['scope', 'orientation', 'application_name', 'short_name', 'description', 'apple_mobile_web_app_title'],
  branding: ['logo_light_mobile', 'logo_dark_mobile'],
  navbar: ['links'],
  footer: ['disclaimer'],
}
const REQUIRED = Object.fromEntries(
  Object.entries(SCHEMA).map(([section, { neutral, translatable }]) => [
    section,
    [...Object.keys(neutral), ...Object.keys(translatable)].filter((key) => !(OPTIONAL[section] ?? []).includes(key)),
  ]),
)
const REQUIRED_PWA_ICONS = ['icon_192', 'icon_512', 'maskable_icon']
// Required values that must also say something; an empty admin path is fine,
// an empty site title is not.
const NON_EMPTY = {
  site: ['url', 'title', 'description'],
  metadata: ['locale'],
  branding: ['logo_light', 'logo_dark', 'logo_square', 'logo_alt'],
  footer: ['logo', 'site_label', 'copyright'],
}

const NAVBAR_VARIANTS = ['standard', 'compact', 'app']
const LANG_RE = /^[a-z]{2}$/

// The languages the shared Elm code knows (Lang.elm, UiStrings.elm, Locale.elm).
// A language has to be added there before a site can declare it.
export const SUPPORTED_LANGUAGES = ['fi', 'en']

const isTable = (v) => v !== null && typeof v === 'object' && !Array.isArray(v)

const TYPE_CHECKS = {
  string: (v) => typeof v === 'string',
  bool: (v) => typeof v === 'boolean',
  int: (v) => Number.isInteger(v),
  // A single string is accepted for a list of strings (one disclaimer line);
  // splitSection turns it into a list.
  strings: (v) => typeof v === 'string' || (Array.isArray(v) && v.every((x) => typeof x === 'string')),
  links: (v) =>
    Array.isArray(v) &&
    v.every(
      (x) =>
        isTable(x) &&
        Object.keys(x).every((key) => key === 'label' || key === 'href') &&
        typeof x.label === 'string' &&
        x.label.trim() !== '' &&
        typeof x.href === 'string' &&
        x.href.trim() !== '',
    ),
  table: isTable,
}

// Reads [i18n]. On any problem it reports it and carries on as a Finnish-only
// site, so the rest of the file is still checked and no later step trips over
// a language that does not exist.
function readI18n(raw, name, problems) {
  const fallback = { default: 'fi', languages: ['fi'] }
  const i18n = raw.i18n ?? {}
  if (!isTable(i18n)) return fallback // reported with the other sections
  const before = problems.length
  const def = i18n.default ?? 'fi'
  const languages = i18n.languages ?? [def]
  for (const key of Object.keys(i18n)) {
    if (key !== 'default' && key !== 'languages') problems.push(`${name}: unknown key [i18n] ${key}`)
  }
  if (
    !Array.isArray(languages) ||
    languages.length === 0 ||
    languages.some((l) => typeof l !== 'string' || !LANG_RE.test(l))
  ) {
    problems.push(`${name}: [i18n] languages must be a non-empty list of two-letter language codes`)
    return fallback
  }
  if (typeof def !== 'string' || !languages.includes(def)) {
    problems.push(`${name}: [i18n] default ${JSON.stringify(def)} is not listed in languages`)
  }
  if (new Set(languages).size !== languages.length) problems.push(`${name}: [i18n] languages has duplicates`)
  for (const lang of languages) {
    if (!SUPPORTED_LANGUAGES.includes(lang)) {
      problems.push(`${name}: [i18n] language "${lang}" is not supported (supported: ${SUPPORTED_LANGUAGES.join(', ')})`)
    }
  }
  return problems.length > before ? fallback : { default: def, languages }
}

// Splits one raw section into { neutral, byLang: { <lang>: translatable } },
// reporting every key that sits on the wrong side.
function splitSection(raw, section, i18n, name, problems) {
  const schema = SCHEMA[section]
  const out = { neutral: {}, byLang: Object.fromEntries(i18n.languages.map((l) => [l, {}])) }
  const check = (key, value, where, kind) => {
    if (!TYPE_CHECKS[kind](value)) problems.push(`${name}: ${where} ${key} must be of type ${kind}`)
  }
  const normal = (value, kind) => (kind === 'strings' && typeof value === 'string' ? [value] : value)
  for (const [key, value] of Object.entries(raw ?? {})) {
    if (key in schema.neutral) {
      check(key, value, `[${section}]`, schema.neutral[key])
      out.neutral[key] = value
    } else if (key in schema.translatable) {
      check(key, value, `[${section}]`, schema.translatable[key])
      out.byLang[i18n.default][key] = normal(value, schema.translatable[key])
    } else if (LANG_RE.test(key) && isTable(value)) {
      if (key === i18n.default) {
        problems.push(
          `${name}: [${section}.${key}] is the default language; put its text directly in [${section}]`,
        )
      } else if (!i18n.languages.includes(key)) {
        problems.push(`${name}: [${section}.${key}] but "${key}" is not listed in [i18n] languages`)
      } else {
        for (const [k, v] of Object.entries(value)) {
          if (k in schema.translatable) {
            check(k, v, `[${section}.${key}]`, schema.translatable[k])
            out.byLang[key][k] = normal(v, schema.translatable[k])
          } else if (k in schema.neutral) {
            problems.push(`${name}: [${section}.${key}] ${k} is language-neutral; put it in [${section}]`)
          } else {
            problems.push(`${name}: unknown key [${section}.${key}] ${k}`)
          }
        }
      }
    } else {
      problems.push(`${name}: unknown key [${section}] ${key}`)
    }
  }
  return out
}

// Merges tables key by key, so a site or a language overrides single values
// of a nested table ([pwa.icons], [app.strings]) without losing the rest.
function deepMerge(...tables) {
  const out = {}
  for (const table of tables) {
    for (const [key, value] of Object.entries(table ?? {})) {
      out[key] = isTable(value) && isTable(out[key]) ? deepMerge(out[key], value) : value
    }
  }
  return out
}

// The tables of [app] that hold text. Everything else in [app] is
// language-neutral (URLs, numbers, flags, other tables).
export const APP_TEXT_TABLES = ['strings', 'statics']

const shapeOf = (value) => (Array.isArray(value) ? 'list' : isTable(value) ? 'table' : typeof value)

// [app] belongs to the app. Language-neutral settings sit directly in it; text
// sits in [app.strings] (for the app) and [app.statics] (for its generators),
// with the other languages in [app.<lang>.strings] and [app.<lang>.statics].
// As elsewhere there is no silent fallback: each language gives every key.
function splitApp(raw, i18n, problems) {
  const out = { neutral: {}, byLang: Object.fromEntries(i18n.languages.map((l) => [l, {}])) }
  for (const [key, value] of Object.entries(raw ?? {})) {
    if (!(LANG_RE.test(key) && isTable(value))) {
      out.neutral[key] = value
    } else if (key === i18n.default) {
      problems.push(`config.toml: [app.${key}] is the default language; put its text directly in [app.strings]`)
    } else if (!i18n.languages.includes(key)) {
      problems.push(`config.toml: [app.${key}] but "${key}" is not listed in [i18n] languages (two-letter table names in [app] are language tables)`)
    } else {
      for (const [name, table] of Object.entries(value)) {
        if (APP_TEXT_TABLES.includes(name) && isTable(table)) out.byLang[key][name] = table
        else {
          problems.push(
            `config.toml: [app.${key}] ${name}: only ${APP_TEXT_TABLES.map((t) => `[app.${key}.${t}]`).join(' and ')} can be set per language; text belongs in [app.strings]`,
          )
        }
      }
    }
  }
  for (const name of APP_TEXT_TABLES) {
    const base = out.neutral[name]
    if (base !== undefined && !isTable(base)) problems.push(`config.toml: [app] ${name} must be a table`)
    for (const lang of i18n.languages) {
      if (lang === i18n.default) continue
      const translated = out.byLang[lang][name]
      if (!isTable(base)) {
        if (translated) problems.push(`config.toml: [app.${lang}.${name}] has no [app.${name}] to translate`)
        continue
      }
      if (!translated) {
        problems.push(`config.toml: [app.${lang}.${name}] is missing (text is set in [app.${name}] for "${i18n.default}")`)
        continue
      }
      for (const [key, value] of Object.entries(base)) {
        if (!(key in translated)) {
          problems.push(`config.toml: [app.${lang}.${name}] ${key} is missing (set in [app.${name}] for "${i18n.default}")`)
        } else if (shapeOf(translated[key]) !== shapeOf(value)) {
          problems.push(`config.toml: [app.${lang}.${name}] ${key} must be a ${shapeOf(value)} like in [app.${name}]`)
        }
      }
      for (const key of Object.keys(translated)) {
        if (!(key in base)) problems.push(`config.toml: [app.${lang}.${name}] ${key} is not in [app.${name}]`)
      }
    }
  }
  return out
}

const sameUrl = (a, b) => a.replace(/\/+$/, '') === b.replace(/\/+$/, '')

/**
 * Resolves raw (parsed) site and family TOML into one configuration per
 * language: { default, languages, configs: { <lang>: config } }.
 * Throws SiteConfigError listing every problem found.
 */
export function resolve(siteRaw, familyRaw = {}, options = {}) {
  const year = options.year ?? new Date().getFullYear()
  const problems = []

  // Every top-level key is a section, and every section is a table. A value of
  // another kind is reported and then treated as absent.
  const tablesOf = (raw, name) => {
    const tables = {}
    for (const [key, value] of Object.entries(raw)) {
      if (!(key in SCHEMA) && key !== 'i18n' && key !== 'app') problems.push(`${name}: unknown section [${key}]`)
      else if (!isTable(value)) problems.push(`${name}: [${key}] must be a table`)
      else tables[key] = value
    }
    return tables
  }
  siteRaw = tablesOf(siteRaw, 'config.toml')
  familyRaw = tablesOf(familyRaw, 'family.toml')
  const i18n = readI18n(siteRaw, 'config.toml', problems)
  const familyI18n = readI18n(familyRaw, 'family.toml', problems)

  const sections = {}
  for (const section of Object.keys(SCHEMA)) {
    sections[section] = {
      site: splitSection(siteRaw[section], section, i18n, 'config.toml', problems),
      family: splitSection(familyRaw[section], section, familyI18n, 'family.toml', problems),
    }
  }
  const app = splitApp(siteRaw.app, i18n, problems)

  const configs = {}
  for (const lang of i18n.languages) {
    const config = { lang, languages: i18n.languages }
    const untranslated = new Set()
    for (const section of Object.keys(SCHEMA)) {
      const { site, family } = sections[section]
      config[section] = deepMerge(family.neutral, family.byLang[lang], site.neutral, site.byLang[lang])
      // No silent fallback: text the site sets in its default language must
      // be set for every other language too.
      if (lang !== i18n.default) {
        for (const key of Object.keys(site.byLang[i18n.default])) {
          if (!(key in site.byLang[lang])) {
            untranslated.add(`${section}.${key}`)
            problems.push(`config.toml: [${section}.${lang}] ${key} is missing (set in [${section}] for "${i18n.default}")`)
          }
        }
      }
    }
    config.app = deepMerge(app.neutral, app.byLang[lang])

    const { site, pwa, footer } = config
    pwa.application_name ??= site.title
    pwa.short_name ??= site.title
    pwa.apple_mobile_web_app_title ??= pwa.short_name
    pwa.description ??= site.description
    // The social image shows the site by name unless the site says otherwise.
    config.metadata.default_social_image_alt ??=
      config.metadata.author && config.metadata.author !== site.title
        ? `${site.title} — ${config.metadata.author}`
        : site.title
    if (typeof footer.copyright === 'string') footer.copyright = footer.copyright.replaceAll('{year}', String(year))
    footer.disclaimer ??= []
    config.navbar.links ??= []
    // Family links are canonical; a site never links to itself.
    if (!('links' in sections.footer.site.byLang[lang]) && Array.isArray(footer.links) && typeof site.url === 'string') {
      footer.links = footer.links.filter((link) => !sameUrl(link.href, site.url))
    }

    for (const [section, keys] of Object.entries(REQUIRED)) {
      for (const key of keys) {
        const value = config[section][key]
        if (value === undefined && !untranslated.has(`${section}.${key}`)) {
          problems.push(`[${section}] ${key} is missing for language "${lang}"`)
        } else if (typeof value === 'string' && value.trim() === '' && (NON_EMPTY[section] ?? []).includes(key)) {
          problems.push(`[${section}] ${key} is empty for language "${lang}"`)
        }
      }
    }
    for (const key of REQUIRED_PWA_ICONS) {
      const icon = config.pwa.icons?.[key]
      if (icon === undefined) problems.push(`[pwa.icons] ${key} is missing`)
      else if (typeof icon !== 'string') problems.push(`[pwa.icons] ${key} must be of type string`)
    }
    for (const key of Object.keys(config.pwa.icons ?? {})) {
      if (!REQUIRED_PWA_ICONS.includes(key)) problems.push(`unknown key [pwa.icons] ${key}`)
    }
    if (config.navbar.variant !== undefined && !NAVBAR_VARIANTS.includes(config.navbar.variant)) {
      problems.push(`[navbar] variant must be one of ${NAVBAR_VARIANTS.join(', ')}`)
    }
    configs[lang] = config
  }

  // Translated link lists must point at the same targets, in the same order.
  const hrefs = (links) => (Array.isArray(links) ? links.map((l) => l.href).join('\n') : '')
  const base = configs[i18n.default] ?? Object.values(configs)[0]
  for (const lang of i18n.languages) {
    for (const section of ['footer', 'navbar']) {
      if (!base || lang === i18n.default) continue
      const setHere = 'links' in sections[section].site.byLang[lang]
      const setForDefault = 'links' in sections[section].site.byLang[i18n.default]
      if (setHere !== setForDefault) {
        problems.push(
          `config.toml: links are set in ${setHere ? `[${section}.${lang}]` : `[${section}]`} but not in ${setHere ? `[${section}]` : `[${section}.${lang}]`}; set them for every language or for none`,
        )
      } else if (hrefs(configs[lang][section].links) !== hrefs(base[section].links)) {
        problems.push(`[${section}.${lang}] links must have the same targets, in the same order, as [${section}] links`)
      }
    }
  }

  if (problems.length > 0) throw new SiteConfigError([...new Set(problems)])
  return { default: i18n.default, languages: i18n.languages, configs }
}

/** Reads and resolves a site's config.toml against the family defaults. */
export function load(configPath, options = {}) {
  const read = (path) => parse(readFileSync(path, 'utf8'))
  return resolve(read(configPath), read(options.familyPath ?? FAMILY_PATH), options)
}

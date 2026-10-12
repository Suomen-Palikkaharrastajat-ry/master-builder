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

// Keys every language must end up with once the family defaults are applied.
const REQUIRED = {
  site: ['url', 'title', 'description'],
  metadata: ['locale'],
  branding: ['logo_light', 'logo_dark', 'logo_square', 'logo_alt'],
  navbar: ['sticky', 'variant'],
  footer: ['logo', 'site_label', 'copyright', 'links'],
}

const NAVBAR_VARIANTS = ['standard', 'compact', 'app']
const LANG_RE = /^[a-z]{2}$/

const isTable = (v) => v !== null && typeof v === 'object' && !Array.isArray(v)

const TYPE_CHECKS = {
  string: (v) => typeof v === 'string',
  bool: (v) => typeof v === 'boolean',
  int: (v) => Number.isInteger(v),
  strings: (v) => Array.isArray(v) && v.every((x) => typeof x === 'string'),
  links: (v) =>
    Array.isArray(v) && v.every((x) => isTable(x) && typeof x.label === 'string' && typeof x.href === 'string'),
  table: isTable,
}

function readI18n(raw, name, problems) {
  const i18n = raw.i18n ?? {}
  const def = i18n.default ?? 'fi'
  const languages = i18n.languages ?? [def]
  for (const key of Object.keys(i18n)) {
    if (key !== 'default' && key !== 'languages') problems.push(`${name}: unknown key [i18n] ${key}`)
  }
  if (!Array.isArray(languages) || languages.some((l) => typeof l !== 'string' || !LANG_RE.test(l))) {
    problems.push(`${name}: [i18n] languages must be a list of two-letter language codes`)
    return { default: 'fi', languages: ['fi'] }
  }
  if (typeof def !== 'string' || !languages.includes(def)) {
    problems.push(`${name}: [i18n] default "${def}" is not listed in languages`)
  }
  if (new Set(languages).size !== languages.length) problems.push(`${name}: [i18n] languages has duplicates`)
  return { default: def, languages }
}

// Splits one raw section into { neutral, byLang: { <lang>: translatable } },
// reporting every key that sits on the wrong side.
function splitSection(raw, section, i18n, name, problems) {
  const schema = SCHEMA[section]
  const out = { neutral: {}, byLang: Object.fromEntries(i18n.languages.map((l) => [l, {}])) }
  const check = (key, value, where, kind) => {
    if (!TYPE_CHECKS[kind](value)) problems.push(`${name}: ${where} ${key} must be of type ${kind}`)
  }
  for (const [key, value] of Object.entries(raw ?? {})) {
    if (key in schema.neutral) {
      check(key, value, `[${section}]`, schema.neutral[key])
      out.neutral[key] = value
    } else if (key in schema.translatable) {
      check(key, value, `[${section}]`, schema.translatable[key])
      out.byLang[i18n.default][key] = value
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
            out.byLang[key][k] = v
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

// [app] is free-form: language-neutral keys directly in it, per-language
// overrides in [app.<lang>].
function splitApp(raw, i18n) {
  const out = { neutral: {}, byLang: Object.fromEntries(i18n.languages.map((l) => [l, {}])) }
  for (const [key, value] of Object.entries(raw ?? {})) {
    if (i18n.languages.includes(key) && key !== i18n.default && isTable(value)) out.byLang[key] = value
    else out.neutral[key] = value
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
  const i18n = readI18n(siteRaw, 'config.toml', problems)
  const familyI18n = readI18n(familyRaw, 'family.toml', problems)

  for (const [raw, name] of [
    [siteRaw, 'config.toml'],
    [familyRaw, 'family.toml'],
  ]) {
    for (const key of Object.keys(raw)) {
      if (!(key in SCHEMA) && key !== 'i18n' && key !== 'app') problems.push(`${name}: unknown section [${key}]`)
    }
  }

  const sections = {}
  for (const section of Object.keys(SCHEMA)) {
    sections[section] = {
      site: splitSection(siteRaw[section], section, i18n, 'config.toml', problems),
      family: splitSection(familyRaw[section], section, familyI18n, 'family.toml', problems),
    }
  }
  const app = splitApp(siteRaw.app, i18n)

  const configs = {}
  for (const lang of i18n.languages) {
    const config = { lang }
    const untranslated = new Set()
    for (const section of Object.keys(SCHEMA)) {
      const { site, family } = sections[section]
      config[section] = {
        ...family.neutral,
        ...(family.byLang[lang] ?? {}),
        ...site.neutral,
        ...site.byLang[lang],
      }
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
    config.app = { ...app.neutral, ...app.byLang[lang] }

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
        if (config[section][key] === undefined && !untranslated.has(`${section}.${key}`)) {
          problems.push(`[${section}] ${key} is missing for language "${lang}"`)
        }
      }
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
      if (base && lang !== i18n.default && hrefs(configs[lang][section].links) !== hrefs(base[section].links)) {
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

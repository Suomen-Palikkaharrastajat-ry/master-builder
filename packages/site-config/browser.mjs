// Browser-side helpers for apps that use the shared site configuration.

import { headTags } from './head.mjs'

const STORAGE_KEY = 'lang'

// Read once: the request is removed from the address after the first read.
let requested

/**
 * The language the visitor asked for, if the site declares it: `?lang=` in
 * the address, or an earlier choice. A request in the address is remembered
 * and then removed from it, so the address stays shareable and later
 * navigation does not repeat it. A request for a language the site does not
 * declare is ignored and leaves an earlier choice alone.
 */
export function requestedLang(siteConfig) {
  if (requested !== undefined) return requested
  const declared = (code) => {
    const lang = (code || '').slice(0, 2).toLowerCase()
    return siteConfig.languages.includes(lang) ? lang : null
  }
  const url = new URL(window.location.href)
  const fromUrl = declared(url.searchParams.get('lang'))
  let stored = null
  try {
    if (fromUrl) window.localStorage.setItem(STORAGE_KEY, fromUrl)
    stored = declared(window.localStorage.getItem(STORAGE_KEY))
  } catch {
    // Storage can be unavailable (private mode); the address still works.
  }
  if (url.searchParams.has('lang')) {
    url.searchParams.delete('lang')
    window.history.replaceState(window.history.state, '', url)
  }
  requested = fromUrl || stored
  return requested
}

/** Sets the document language, for assistive technology and hyphenation. */
export function setDocumentLang(lang) {
  document.documentElement.lang = lang
}

/**
 * Shows a language in the document itself: the `lang` attribute and the
 * head's description, social and app-name tags, which the static page carries
 * in the site's default language. The title is left to the app.
 */
export function showLanguage(siteConfig, lang) {
  setDocumentLang(lang)
  const config = siteConfig.configs[lang]
  if (!config) return
  for (const tag of headTags(config)) {
    if (tag.tag !== 'meta') continue
    const [attribute, value] = tag.attrs.name ? ['name', tag.attrs.name] : ['property', tag.attrs.property]
    const element = document.head.querySelector(`meta[${attribute}="${value}"]`)
    if (element) element.setAttribute('content', tag.attrs.content)
  }
}

/**
 * The language to show: the requested one when the site declares it, otherwise
 * the site's default. Mirrors SiteSettings.pickLang in Elm.
 */
export function pickLang(siteConfig) {
  return requestedLang(siteConfig) || siteConfig.default
}

/** The free-form [app] table of a language (the site's default one unless given). */
export function appSettings(siteConfig, lang = siteConfig.default) {
  return siteConfig.configs[lang].app
}

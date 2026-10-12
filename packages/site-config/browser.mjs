// Browser-side helpers for apps that use the shared site configuration.

const STORAGE_KEY = 'lang'

/**
 * The language the visitor asked for, if any: `?lang=` in the address (which
 * is then remembered), or an earlier choice. The app shows it only when the
 * site declares that language (SiteSettings.pickLang).
 */
export function requestedLang() {
  const fromUrl = new URLSearchParams(window.location.search).get('lang')
  try {
    if (fromUrl) window.localStorage.setItem(STORAGE_KEY, fromUrl)
    return fromUrl || window.localStorage.getItem(STORAGE_KEY)
  } catch {
    return fromUrl
  }
}

/** Sets the document language, for assistive technology and hyphenation. */
export function setDocumentLang(lang) {
  document.documentElement.lang = lang
}

/**
 * The language to show: the requested one when the site declares it, otherwise
 * the site's default. Mirrors SiteSettings.pickLang in Elm.
 */
export function pickLang(siteConfig) {
  const requested = (requestedLang() || '').slice(0, 2).toLowerCase()
  return siteConfig.languages.includes(requested) ? requested : siteConfig.default
}

/** The free-form [app] table of a language (the site's default one unless given). */
export function appSettings(siteConfig, lang = siteConfig.default) {
  return siteConfig.configs[lang].app
}

#!/usr/bin/env node
// Fails when display text sits outside a translation module or config.toml.
//
// usage: node check-i18n.mjs <file-or-directory>...
//
// Scans Elm, JavaScript and Haskell sources for string literals containing
// Finnish letters (å, ä, ö) or common Finnish interface words. That does not
// catch every Finnish string, but it catches nearly every sentence and label,
// which is enough to keep text from creeping back into views. Text belongs in a module named I18n, UiStrings, Locale or
// Translations (per language), or in config.toml. A file that legitimately
// holds such text (sample content) opts out with `i18n-exempt: <reason>`.
import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join, relative } from 'node:path'

const EXTENSIONS = /\.(elm|js|mjs|ts|hs)$/
const TRANSLATION_MODULE = /(^|\/)(I18n|UiStrings|Locale|Translations)\.[a-z]+$/
const SKIPPED = /(^|\/)(tests?|node_modules|elm-stuff|dist|dist-newstyle|vendor|fixtures|\.elm-tailwind|\.elm-pages|DesignTokens)(\/|$)|\.test\.[a-z]+$|Test\.elm$|Spec\.hs$/
const FINNISH = /[åäöÅÄÖ]/

// Finnish interface words that have no å, ä or ö. They are only looked for in
// literals that read like text (they contain a space, or are one capitalised
// word), so file names, routes and identifiers such as "kalenteri.ics" pass.
const FINNISH_WORDS = [
  'tapahtuma', 'tapahtumat', 'tapahtumaa', 'tapahtuman', 'kohde', 'kohteet', 'kohdetta', 'kohteen',
  'kirjaudu', 'kirjautunut', 'kirjautuminen', 'kirjaudutaan', 'tallenna', 'tallennettu', 'tallennetaan',
  'poista', 'poistettu', 'muokkaa', 'peruuta', 'peruttu', 'takaisin', 'sulje', 'avaa', 'valikko',
  'haku', 'hae', 'haetaan', 'sivu', 'sivua', 'sivusto', 'sivustolta', 'ladataan', 'virhe', 'viikko',
  'kuukausi', 'kuuta', 'tuotiin', 'tuonti', 'tuodaan', 'kalenteri', 'kalenteriin', 'kartta', 'kartalla',
  'uusi', 'kaikki', 'tila', 'kuva', 'kuvaus', 'nimi', 'sijainti', 'tunniste', 'tyyppi', 'luonnos',
  'julkaistu', 'odottaa', 'edellinen', 'seuraava', 'klo', 'tammikuu', 'helmikuu', 'maaliskuu',
  'huhtikuu', 'toukokuu', 'elokuu', 'syyskuu', 'lokakuu', 'marraskuu', 'joulukuu', 'maanantai',
  'tiistai', 'keskiviikko', 'torstai', 'perjantai', 'lauantai', 'sunnuntai', 'etusivu', 'yhteystiedot',
  'verkkosivu', 'verkkovirhe', 'palvelinvirhe', 'aukioloajat', 'suodattimet', 'ilmoitukset',
]
// A word followed by a file extension ("kalenteri.rss") is a file name, and one
// joined with - or _ ("kartta-pane") is a class or an identifier.
const FINNISH_WORD = new RegExp(`(?<![\\p{L}_-])(${FINNISH_WORDS.join('|')})(?![\\p{L}_-])(?!\\.[a-z])`, 'iu')
const READS_LIKE_TEXT = /\s|^["'`]+[A-ZÅÄÖ][a-zåäö]+["'`]+$/

const looksFinnish = (literal) =>
  FINNISH.test(literal) || (READS_LIKE_TEXT.test(literal) && FINNISH_WORD.test(literal))

function files(path) {
  if (SKIPPED.test(path)) return []
  if (statSync(path).isDirectory()) return readdirSync(path).flatMap((entry) => files(join(path, entry)))
  return EXTENSIONS.test(path) && !TRANSLATION_MODULE.test(path) ? [path] : []
}

// Yields every string literal of a source file as { text, line }, where text
// includes the quotes. A small tokenizer rather than regular expressions, so
// that comment markers inside strings, strings inside comments, multi-line
// strings (Elm """…""", JS template literals) and Haskell primes are all read
// for what they are.
export function literals(source, path) {
  const haskellLike = /\.(elm|hs)$/.test(path)
  const out = []
  let line = 1
  let i = 0
  const at = (text) => source.startsWith(text, i)
  const advance = (count) => {
    for (let k = 0; k < count && i < source.length; k++, i++) if (source[i] === '\n') line++
  }
  const skipUntil = (end) => {
    const stop = source.indexOf(end, i)
    advance((stop === -1 ? source.length : stop + end.length) - i)
  }
  const readString = (quote) => {
    const start = i
    const startLine = line
    advance(quote.length)
    while (i < source.length && !at(quote)) advance(source[i] === '\\' ? 2 : 1)
    advance(quote.length)
    out.push({ text: source.slice(start, i), line: startLine })
  }
  while (i < source.length) {
    if (haskellLike) {
      if (at('{-')) {
        let depth = 0
        do {
          if (at('{-')) {
            depth++
            advance(2)
          } else if (at('-}')) {
            depth--
            advance(2)
          } else advance(1)
        } while (depth > 0 && i < source.length)
      } else if (at('--')) skipUntil('\n')
      else if (at('"""')) readString('"""')
      else if (at('"')) readString('"')
      else if (at("'")) {
        // A character literal ('a', '\n'), or a prime in a Haskell name (x').
        const match = /^'(\\.[^']*|[^'\\])'/.exec(source.slice(i, i + 12))
        advance(match ? match[0].length : 1)
      } else advance(1)
    } else if (at('//')) skipUntil('\n')
    else if (at('/*')) skipUntil('*/')
    else if (at('"') || at("'") || at('`')) readString(source[i])
    else advance(1)
  }
  return out
}

/** The findings of one source file: "path:line: literal". */
export function findingsIn(source, path, displayPath = path) {
  // A file may opt out with a comment saying why: `i18n-exempt: <reason>`.
  if (/i18n-exempt: \S/.test(source)) return []
  return literals(source, path)
    .filter((literal) => looksFinnish(literal.text))
    .map((literal) => `${displayPath}:${literal.line}: ${literal.text.replace(/\s+/g, ' ').slice(0, 120)}`)
}

const isMain = process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href
if (isMain) main()

function main() {
  const targets = process.argv.slice(2)
  if (targets.length === 0) {
    console.error('usage: check-i18n.mjs <file-or-directory>...')
    process.exit(2)
  }
  const findings = targets
    .flatMap(files)
    .flatMap((path) => findingsIn(readFileSync(path, 'utf8'), path, relative(process.cwd(), path)))
  if (findings.length > 0) {
    console.error('i18n: display text outside a translation module or config.toml:')
    for (const finding of findings) console.error('  ' + finding)
    process.exit(1)
  }
  console.log('i18n: no display text outside translation modules')
}

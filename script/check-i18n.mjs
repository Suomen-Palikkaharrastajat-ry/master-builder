#!/usr/bin/env node
// Fails when display text sits outside a translation module or config.toml.
//
// usage: node check-i18n.mjs <file-or-directory>...
//
// Scans Elm, JavaScript and Haskell sources for string literals containing
// Finnish letters (å, ä, ö). That does not catch every Finnish string, but it
// catches nearly every sentence, which is enough to keep text from creeping
// back into views. Text belongs in a module named I18n, UiStrings, Locale or
// Translations (per language), or in config.toml. A file that legitimately
// holds such text (sample content) opts out with `i18n-exempt: <reason>`.
import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join, relative } from 'node:path'

const EXTENSIONS = /\.(elm|js|mjs|ts|hs)$/
const TRANSLATION_MODULE = /(^|\/)(I18n|UiStrings|Locale|Translations)\.[a-z]+$/
const SKIPPED = /(^|\/)(tests?|node_modules|elm-stuff|dist|dist-newstyle|vendor|fixtures|\.elm-tailwind|\.elm-pages|DesignTokens)(\/|$)|\.test\.[a-z]+$|Test\.elm$|Spec\.hs$/
const FINNISH = /[åäöÅÄÖ]/

function files(path) {
  if (SKIPPED.test(path)) return []
  if (statSync(path).isDirectory()) return readdirSync(path).flatMap((entry) => files(join(path, entry)))
  return EXTENSIONS.test(path) && !TRANSLATION_MODULE.test(path) ? [path] : []
}

// Blanks out comments, keeping line numbers intact.
function withoutComments(source, path) {
  const blank = (match) => match.replace(/[^\n]/g, ' ')
  if (/\.(elm|hs)$/.test(path)) {
    return source.replace(/\{-[\s\S]*?-\}/g, blank).replace(/(^|\s)--.*$/gm, blank)
  }
  return source.replace(/\/\*[\s\S]*?\*\//g, blank).replace(/(^|\s)\/\/.*$/gm, blank)
}

const targets = process.argv.slice(2)
if (targets.length === 0) {
  console.error('usage: check-i18n.mjs <file-or-directory>...')
  process.exit(2)
}

const findings = []
for (const path of targets.flatMap(files)) {
  const source = readFileSync(path, 'utf8')
  // A file may opt out with a comment saying why: `i18n-exempt: <reason>`.
  if (/i18n-exempt: \S/.test(source)) continue
  // In Elm and Haskell single quotes are character literals, not text.
  const literals = /\.(elm|hs)$/.test(path)
    ? /"(?:[^"\\]|\\.)*"/g
    : /"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|`(?:[^`\\]|\\.)*`/g
  const lines = withoutComments(source, path).split('\n')
  lines.forEach((line, index) => {
    for (const literal of line.match(literals) ?? []) {
      if (FINNISH.test(literal)) findings.push(`${relative(process.cwd(), path)}:${index + 1}: ${literal}`)
    }
  })
}

if (findings.length > 0) {
  console.error('i18n: display text outside a translation module or config.toml:')
  for (const finding of findings) console.error('  ' + finding)
  process.exit(1)
}
console.log('i18n: no display text outside translation modules')

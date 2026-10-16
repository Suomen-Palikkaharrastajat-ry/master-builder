import assert from 'node:assert/strict'
import { test } from 'node:test'
import { files, findingsIn, literals } from './check-i18n.mjs'

const elm = (source) => findingsIn(source, 'View.elm')
const js = (source) => findingsIn(source, 'main.js')

test('flags literals with Finnish letters, with their line', () => {
  assert.deepEqual(elm('a =\n    "Sivua ei löydy"\n'), ['View.elm:2: "Sivua ei löydy"'])
})

test('flags common Finnish words without å, ä or ö in text-like literals', () => {
  assert.equal(elm('a = " tapahtuma"').length, 1)
  assert.equal(elm('a = "Kalenteri"').length, 1)
  assert.equal(elm('a = "Kirjaudu ulos"').length, 1)
})

test('file names, routes, classes and identifiers are not text', () => {
  assert.deepEqual(elm('a = "kalenteri.ics"\nb = "/kalenteri.atom\\" rel=\\"self\\""\nc = "map kartta-pane"\nd = "kartta_id x"\ne = "kalenteri"'), [])
})

test('a comment marker inside a string does not hide the string', () => {
  assert.equal(elm('a = "Lue lisaa -- tapahtuma on peruttu"').length, 1)
  assert.equal(js("const a = 'https://x // tapahtuma on peruttu'").length, 1)
})

test('text inside comments is ignored', () => {
  assert.deepEqual(elm('-- "Sivua ei löydy"\n{- "Hyvää" {- nested "päivää" -} "vielä" -}\na = 1'), [])
  assert.deepEqual(js('// "Sivua ei löydy"\n/* "Hyvää"\n "päivää" */\nconst a = 1'), [])
})

test('multi-line strings are read', () => {
  assert.deepEqual(elm('a =\n    """\nSivua\nei löydy\n"""'), ['View.elm:2: """ Sivua ei löydy """'])
  assert.equal(js('const a = `rivi\nPäivitä sivu`').length, 1)
})

test('Elm and Haskell character literals and primes are not strings', () => {
  assert.deepEqual(findingsIn("f x' = if c == 'ä' then x' else \"ok\"", 'A.hs'), [])
  assert.deepEqual(literals("a = 'x'\nb = \"y\"", 'A.elm').map((l) => l.text), ['"y"'])
})

test('a file opts out with an i18n-exempt reason', () => {
  assert.deepEqual(elm('-- i18n-exempt: generated feed content\na = "Sivua ei löydy"'), [])
})

test('a path that does not exist yields no files', () => {
  assert.deepEqual(files('no/such/directory'), [])
})

import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { test } from 'node:test'

const script = new URL('./gen-haskell.mjs', import.meta.url).pathname
const dir = mkdtempSync(join(tmpdir(), 'gen-haskell-'))
const run = (name, toml, ...flags) => {
  const config = join(dir, `${name}.toml`)
  const out = join(dir, `${name}.hs`)
  writeFileSync(config, toml)
  const result = spawnSync(process.execPath, [script, '--config', config, '--out', out, ...flags], { encoding: 'utf8' })
  return { ...result, out, read: () => readFileSync(out, 'utf8') }
}
const base = `
[i18n]
default = "fi"
languages = ["fi", "en"]
[site]
url = "https://x.example/"
title = "Kärry \\"A\\" \\\\ B"
description = "Kuvaus"
[site.en]
title = "Cart"
description = "Description"
`

test('writes a module with per-language values, escaped for Haskell', () => {
  const result = run('ok', base + '[app]\npocketbase_url = "https://data.example"\n[app.statics]\nadd_to_calendar = "Lisää"\n[app.en.statics]\nadd_to_calendar = "Add"\n')
  assert.equal(result.status, 0, result.stderr)
  const source = result.read()
  assert.match(source, /data Lang = Fi \| En/)
  assert.match(source, /siteUrl = "https:\/\/x\.example"\n/)
  assert.ok(source.includes('siteTitle Fi = "K\\228\\&rry \\"A\\" \\\\ B"'), source)
  assert.match(source, /staticsAddToCalendar En = "Add"/)
  assert.match(source, /appPocketbaseUrl :: Lang -> String/)
  assert.match(source, /monthNames Fi = \["Tammikuu", /)
  assert.match(source, /weekdayAbbrs En = \["Mon", /)
  assert.match(source, /langCode En = "en"/)
})

test('--check passes for a fresh file and fails for a stale one', () => {
  const toml = base + '[app]\nx = "1"\n'
  assert.equal(run('check', toml).status, 0)
  assert.equal(run('check', toml, '--check').status, 0)
  const stale = run('check', toml.replace('"1"', '"2"'), '--check')
  assert.equal(stale.status, 1)
  assert.match(stale.stderr, /out of date/)
})

test('rejects keys that cannot become distinct Haskell names', () => {
  const bad = run('bad', base + '[app]\n"my-key" = "x"\nfoo_bar = "a"\nfooBar = "b"\n')
  assert.equal(bad.status, 1)
  assert.match(bad.stderr, /my-key: keys used by the generators must match/)
  assert.match(bad.stderr, /fooBar: keys used by the generators must match/)
  const doubled = run('doubled', base + '[app]\nfoo__bar = "b"\n')
  assert.equal(doubled.status, 1)
  assert.match(doubled.stderr, /foo__bar: keys used by the generators must match/)
})

test('rejects a value that is a list in one language and a string in another', () => {
  const mixed = run('mixed', base + '[app.statics]\nnames = ["a", "b"]\n[app.en.statics]\nnames = "a"\n')
  assert.equal(mixed.status, 1)
  assert.match(mixed.stderr, /\[app\.en\.statics\] names must be a list like in \[app\.statics\]/)
})

test('hidden languages are written out too', () => {
  const result = run('hidden', base.replace('languages = ["fi", "en"]', 'languages = ["fi", "en"]\nhidden = ["en"]'))
  assert.equal(result.status, 0, result.stderr)
  const source = result.read()
  assert.match(source, /data Lang = Fi \| En/)
  assert.match(source, /siteTitle En = "Cart"/)
})

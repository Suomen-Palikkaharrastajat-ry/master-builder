#!/usr/bin/env node
// Fails when a shared package builds a Tailwind class at runtime that the
// ui-components safelist does not list. Such classes are invisible to
// Tailwind's scanner, so without the safelist entry they are silently missing
// from every app's production CSS.
import { readFileSync, readdirSync, statSync } from 'node:fs'
import { join } from 'node:path'

const root = new URL('..', import.meta.url).pathname
const css = readFileSync(join(root, 'packages/ui-components/ui-components.css'), 'utf8')

// Helpers in TailwindExtra.elm that concatenate a class name from a Spacing.
const dynamic = [{ call: 'space_y', prefix: 'space-y-' }]

function elmFiles(dir) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name)
    if (statSync(path).isDirectory()) {
      return name === 'elm-stuff' || name === 'tests' ? [] : elmFiles(path)
    }
    return name.endsWith('.elm') ? [path] : []
  })
}

const missing = new Map()
for (const file of elmFiles(join(root, 'packages'))) {
  const source = readFileSync(file, 'utf8')
  for (const { call, prefix } of dynamic) {
    const pattern = new RegExp(`\\b(?:TwEx|TailwindExtra)\\.${call}\\s+Th\\.s([0-9a-z_]+)`, 'g')
    for (const match of source.matchAll(pattern)) {
      const cls = prefix + match[1].replace('_dot_', '.')
      const listed = new RegExp(`(^|[\\s"])${cls.replace('.', '\\.')}([\\s"]|$)`).test(css)
      if (!listed) {
        missing.set(cls, [...(missing.get(cls) ?? []), file.slice(root.length)])
      }
    }
  }
}

if (missing.size > 0) {
  console.error('Classes built at runtime but missing from packages/ui-components/ui-components.css:')
  for (const [cls, files] of missing) {
    console.error(`  ${cls}  (${[...new Set(files)].join(', ')})`)
  }
  process.exit(1)
}
console.log('safelist: every runtime-built class is listed')

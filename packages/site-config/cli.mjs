#!/usr/bin/env node
// Prints a site's resolved configuration as JSON.
// usage: node cli.mjs <config.toml>
import { load, SiteConfigError } from './site-config.mjs'

const path = process.argv[2]
if (!path) {
  console.error('usage: cli.mjs <config.toml>')
  process.exit(2)
}
try {
  console.log(JSON.stringify(load(path), null, 2))
} catch (error) {
  if (!(error instanceof SiteConfigError)) throw error
  console.error(`${path}: ${error.message}`)
  process.exit(1)
}

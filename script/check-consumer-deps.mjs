#!/usr/bin/env node
// Usage: node script/check-consumer-deps.mjs [<app-elm.json>]
//
// For every packages/*/src directory listed in the app's `source-directories`,
// read the sibling packages/*/elm.json and fail if the app's elm.json lacks a
// dependency or pins a version outside the package's declared range.
import { readFileSync, existsSync } from "node:fs";
import { dirname, resolve, basename } from "node:path";

const appFile = resolve(process.argv[2] ?? "elm.json");
if (!existsSync(appFile)) {
  console.error(`Error: File not found: ${appFile}`);
  process.exit(1);
}
const app = JSON.parse(readFileSync(appFile, "utf8"));
const appDir = dirname(appFile);

const parse = (v) => v.split(".").map(Number);
const cmp = (a, b) => {
  for (let i = 0; i < 3; i++) if (a[i] !== b[i]) return a[i] - b[i];
  return 0;
};
// Range format: "1.0.0 <= v < 2.0.0"
const inRange = (version, range) => {
  const m = range.match(/^(\S+) <= v < (\S+)$/);
  if (!m) return false;
  const v = parse(version);
  return cmp(v, parse(m[1])) >= 0 && cmp(v, parse(m[2])) < 0;
};

const appDeps = {
  ...app.dependencies.direct,
  ...app.dependencies.indirect,
};

let failed = false;
for (const dir of app["source-directories"]) {
  const abs = resolve(appDir, dir);
  if (basename(abs) !== "src") continue;
  const pkgJson = resolve(abs, "..", "elm.json");
  if (!existsSync(pkgJson) || !/[\\/]packages[\\/]/.test(pkgJson)) continue;
  const pkg = JSON.parse(readFileSync(pkgJson, "utf8"));
  if (pkg.type !== "package") continue;
  for (const [name, range] of Object.entries(pkg.dependencies)) {
    const have = appDeps[name];
    if (!have) {
      console.error(`${pkg.name}: app is missing dependency ${name} (${range})`);
      failed = true;
    } else if (!inRange(have, range)) {
      console.error(`${pkg.name}: app has ${name} ${have}, outside ${range}`);
      failed = true;
    }
  }
  console.log(`checked ${pkg.name}`);
}
process.exit(failed ? 1 : 0);

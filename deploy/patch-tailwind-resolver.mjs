/**
 * Patch tailwind-resolver bundling bug where the default export references
 * an undefined minified symbol `u1`. We replace it with `h1` (resolveTheme)
 * which is the intended default export.
 *
 * Upstream: https://www.npmjs.com/package/tailwind-resolver (0.3.x)
 * Remove this script once the upstream fix is published.
 */
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const root = join(__dirname, "..");

// Patch all copies (hoisted + nested inside elm-tailwind-classes)
const paths = [
  join(root, "node_modules", "tailwind-resolver", "dist", "index.mjs"),
  join(
    root,
    "node_modules",
    "elm-tailwind-classes",
    "node_modules",
    "tailwind-resolver",
    "dist",
    "index.mjs"
  ),
];

let patched = 0;
for (const p of paths) {
  if (!existsSync(p)) continue;
  const src = readFileSync(p, "utf-8");
  if (!src.includes("u1 as default")) continue;
  writeFileSync(p, src.replace("u1 as default", "h1 as default"));
  patched++;
}

if (patched > 0) {
  console.log(
    `  patched tailwind-resolver default export (${patched} file${patched > 1 ? "s" : ""})`
  );
}

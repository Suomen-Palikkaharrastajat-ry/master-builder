import { existsSync } from "fs";
import { resolve } from "path";
import { pathToFileURL } from "url";

/**
 * Resolves a site's config.toml against the family defaults: one complete
 * configuration per language (see packages/site-config/site-config.mjs).
 *
 * The loader is imported at run time on purpose. elm-pages bundles this file
 * once and reuses the bundle until this file itself changes, so a static
 * import would freeze the loader (and its schema) at whatever it was then.
 */
export async function readSiteConfig(path: string, context: { cwd: string }) {
  let filePath = resolve(context.cwd, path);
  if (!existsSync(filePath) && path.endsWith("config.toml")) {
    const fallback = path.startsWith("content/")
      ? resolve(context.cwd, "template/config.toml")
      : resolve(context.cwd, "content/config.toml");
    if (existsSync(fallback)) {
      filePath = fallback;
    }
  }
  const loader = resolve(context.cwd, "packages/site-config/site-config.mjs");
  const { load } = await import(pathToFileURL(loader).href);
  return load(filePath);
}

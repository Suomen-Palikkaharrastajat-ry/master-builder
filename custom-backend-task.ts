import { readFile } from "fs/promises";
import { existsSync } from "fs";
import { resolve } from "path";
import { parse } from "smol-toml";

export async function readToml(path: string, context: { cwd: string }) {
  let filePath = resolve(context.cwd, path);
  if (!existsSync(filePath) && path.endsWith("config.toml")) {
    const fallback = path.startsWith("content/")
      ? resolve(context.cwd, "template/config.toml")
      : resolve(context.cwd, "content/config.toml");
    if (existsSync(fallback)) {
      filePath = fallback;
    }
  }
  const contents = await readFile(filePath, "utf8");
  return parse(contents);
}

import { readFile } from "fs/promises";
import { resolve } from "path";
import { parse } from "smol-toml";

export async function readToml(path: string, context: { cwd: string }) {
  const filePath = resolve(context.cwd, path);
  const contents = await readFile(filePath, "utf8");
  return parse(contents);
}

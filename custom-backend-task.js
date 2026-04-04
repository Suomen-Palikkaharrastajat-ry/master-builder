import { readFile } from "fs/promises";
import { resolve } from "path";
import { parse } from "./pkgs/node_modules/smol-toml/dist/index.js";

export async function readToml(path, context) {
  const filePath = resolve(context.cwd, path);
  const contents = await readFile(filePath, "utf8");
  return parse(contents);
}

import { defineConfig } from "vite";
import adapter from "elm-pages/adapter/netlify.js";
import tailwindcss from "@tailwindcss/vite";
import elmTailwind from "elm-tailwind-classes/vite";

export default {
  vite: defineConfig({
    plugins: [elmTailwind(), tailwindcss()],
  }),
  adapter,
  headTagsTemplate(context) {
    return `
<meta name="generator" content="elm-pages v${context.cliVersion}" />
`;
  },
  preloadTagForFile(file) {
    // add preload directives for JS assets and font assets, etc., skip for CSS files
    // this function will be called with each file that is processed by Vite, including any files in your headTagsTemplate in your config
    return !file.endsWith(".css");
  },
};

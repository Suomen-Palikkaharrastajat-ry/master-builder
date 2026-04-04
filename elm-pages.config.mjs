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
<link rel="icon" href="/favicon.ico" type="image/x-icon" />
<link rel="icon" href="/favicon-32.png" sizes="32x32" type="image/png" />
<link rel="icon" href="/favicon-16.png" sizes="16x16" type="image/png" />
<link rel="apple-touch-icon" href="/apple-touch-icon.png" />
`;
  },
  preloadTagForFile(file) {
    // add preload directives for JS assets and font assets, etc., skip for CSS files
    // this function will be called with each file that is processed by Vite, including any files in your headTagsTemplate in your config
    return !file.endsWith(".css");
  },
};

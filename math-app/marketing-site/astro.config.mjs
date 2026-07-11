// @ts-check
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';

const SITE = 'https://sekklings.com';

// https://astro.build/config
export default defineConfig({
  site: SITE,
  output: 'static',
  trailingSlash: 'never',
  build: {
    inlineStylesheets: 'auto',
  },
  integrations: [
    tailwind({ applyBaseStyles: true }),
    mdx(),
    sitemap({
      entryLimit: 10000,
      // Astro sitemap's i18n config generates hreflang annotations automatically
      // by stripping the locale prefix from each URL. We use English as the only
      // alternative locale (Vietnamese is the default at the root).
      i18n: {
        defaultLocale: 'vi',
        locales: {
          vi: 'vi-VN',
          en: 'en-US',
        },
      },
    }),
  ],
  vite: {
    build: {
      cssCodeSplit: true,
    },
  },
  prefetch: {
    prefetchAll: true,
    defaultStrategy: 'viewport',
  },
  compressHTML: true,
});

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
      i18n: {
        defaultLocale: 'vi',
        locales: {
          vi: 'vi-VN',
          en: 'en-US',
        },
      },
      serialize(item) {
        item.lastmod = item.lastmod ?? new Date().toISOString();
        return item;
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

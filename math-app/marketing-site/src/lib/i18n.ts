// i18n + URL helpers for HocVui marketing site.
// Vietnamese is the default (no /vi prefix). English lives at /en/.

export const DEFAULT_LOCALE = 'vi';
export const SUPPORTED_LOCALES = ['vi', 'en'];

export const SITE = 'https://sekklings.com';

export type Locale = 'vi' | 'en';

export interface I18nEntry {
  vi: string;
  en: string;
}

/**
 * Resolve the alternate URL for a given page.
 * Handles both directions: input may have /en prefix or not.
 */
export function alternateUrl(path: string, target: Locale): string {
  let p = path.replace(/^\//, '');

  if (p === 'en' || p.startsWith('en/')) {
    p = p.slice(3);
  }

  if (target === 'vi') {
    return p === '' ? `${SITE}/` : `${SITE}/${p}`;
  }
  return p === '' ? `${SITE}/en` : `${SITE}/en/${p}`;
}

export function localeFromPath(pathname: string): Locale {
  if (pathname.startsWith('/en/') || pathname === '/en') return 'en';
  return 'vi';
}

export const t = (entry: I18nEntry, locale: Locale) => entry[locale];

/**
 * Metadata bag for SEO surface. All pages pass one of these to <BaseLayout>.
 */
export interface SEOProps {
  title: string;
  description: string;
  /** Path relative to site root, no locale prefix. e.g. '/lessons' */
  path: string;
  /** OG image filename relative to /brand/ (e.g. 'og-image-vi.png'). Default uses locale. */
  ogImage?: string;
  /** Override default 'website' */
  ogType?: 'website' | 'article' | 'product';
  /** Set true for the Flutter app shell pages to prevent indexing */
  noindex?: boolean;
  /** JSON-LD blocks to inject on the page (e.g. Article, SoftwareApplication). */
  jsonLd?: object[];
  /** Date published (for articles) */
  publishedTime?: string;
  /** Date modified (for articles) */
  modifiedTime?: string;
}

export const SITE_NAME = 'HocVui';
export const SITE_TAGLINE_VI = 'Toán vui cho bé 5–7 tuổi';
export const SITE_TAGLINE_EN = 'Fun math for kids 5–7';
export const SITE_DESCRIPTION_VI = 'HocVui — ứng dụng học toán tiếng Việt và tiếng Anh cho bé 5–7 tuổi. Hơn 6,000 bài học, 4 phong cách học tập, hoàn toàn miễn phí.';
export const SITE_DESCRIPTION_EN = 'HocVui — bilingual math app for kids 5–7. 6,000+ lessons, 4 learning personas, free forever.';
export const TWITTER_HANDLE = '@hocvui';

import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';
import { SITE, SITE_DESCRIPTION_VI, SITE_NAME } from '../../lib/i18n';

export async function GET(context) {
  const posts = (await getCollection('blog'))
    .filter((p) => !p.data.draft)
    .sort((a, b) => new Date(b.data.publishedTime).getTime() - new Date(a.data.publishedTime).getTime());

  return rss({
    title: `${SITE_NAME} — Blog`,
    description: SITE_DESCRIPTION_VI,
    site: context.site ?? SITE,
    items: posts.map((p) => ({
      title: p.data.title,
      description: p.data.description,
      pubDate: new Date(p.data.publishedTime),
      link: `/blog/${p.id}/`,
      categories: p.data.tags,
    })),
    customData: `<language>vi-VN</language>`,
    stylesheet: '/rss/styles.xsl',
  });
}

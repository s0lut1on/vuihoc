import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';
import { SITE, SITE_DESCRIPTION_EN, SITE_NAME } from '../../../lib/i18n';

export async function GET(context) {
  const posts = (await getCollection('blog-en'))
    .filter((p) => !p.data.draft)
    .sort((a, b) => new Date(b.data.publishedTime).getTime() - new Date(a.data.publishedTime).getTime());

  return rss({
    title: `${SITE_NAME} — Blog`,
    description: SITE_DESCRIPTION_EN,
    site: context.site ?? SITE,
    items: posts.map((p) => ({
      title: p.data.title,
      description: p.data.description,
      pubDate: new Date(p.data.publishedTime),
      link: `/en/blog/${p.id}/`,
      categories: p.data.tags,
    })),
    customData: `<language>en-US</language>`,
    stylesheet: '/rss/styles.xsl',
  });
}

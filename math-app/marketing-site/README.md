# HocVui Marketing Site (sekklings.com)

A bilingual static marketing site that lives at the root of sekklings.com. The Flutter app has been moved to `/app/`.

## What's here

- **240 SEO-optimized HTML pages** (vi + en, landing + lessons catalog + personas + pricing + parents + about + privacy + terms + 404)
- **Branded assets** (favicon, OG images, manifest)
- **Sitemap + robots.txt** with hreflang annotations
- **JSON-LD** structured data (Organization, WebSite, SoftwareApplication, FAQPage, Course, BreadcrumbList)

## Pages (sample)

| URL | Purpose |
|---|---|
| `/` | Vietnamese landing |
| `/en` | English landing |
| `/lessons` | All subjects × grades catalog |
| `/lessons/numbers/3` | Grade 3 Numbers lessons |
| `/personas` | 4 learning personas |
| `/pricing` | Free vs Premium |
| `/parents` | Parent FAQ |
| `/about` | About + contact |
| `/app` | Splash → Flutter web |
| `/sitemap-index.xml` | Google sitemap |
| `/robots.txt` | Crawler policy |
| `/manifest.webmanifest` | PWA manifest |

## Dev

```bash
npm install
npm run dev                # localhost:4321
npm run build              # static → dist/
npm run preview            # serve dist/
```

The `prebuild` step auto-fetches lesson catalog from the live content-service. To skip it: `SKIP_FETCH=1 npm run build`.

## Deploy to VPS

The site builds to `dist/` (5.6 MB, 240 HTML files). Deploy by syncing `dist/` to the VPS, then running the marketing-site container.

### One-time VPS setup (in `math-app/`)

1. **Edit `docker-compose.yml`** to update the `flutter-web` router (move from `Host(\`localhost\`)` to `Host(\`sekklings.com\`) && PathPrefix(\`/app\`)`).

2. **Add the marketing-site service** to your compose file (or layer the overlay at `math-app/docker-compose.marketing.yml` on top).

3. **Bring up the new container**:
   ```bash
   docker compose -f docker-compose.yml -f docker-compose.marketing.yml up -d marketing-site
   ```

### Per-deploy

```bash
# On your laptop:
cd marketing-site
npm ci
npm run build

# rsync dist/ to VPS
rsync -avz --delete dist/ ${VPS_USER}@${VPS_HOST}:/var/www/marketing/

# On VPS: restart the marketing-site container to pick up new files
ssh ${VPS_USER}@${VPS_HOST} "cd math-app && docker compose -f docker-compose.yml -f docker-compose.marketing.yml restart marketing-site"
```

For CI: wrap the above in a `make deploy-marketing` target that uses your existing `make deploy-vps` ssh-agent setup.

## Required Traefik changes

The current `docker-compose.yml` has `flutter-web` on `Host(\`localhost\`)`. You must:

1. Change to `Host(\`${DOMAIN}\`) && PathPrefix(\`/app\`)` (with a higher priority).
2. Add a `marketing-site` service that catches all other paths.
3. Apply the same in `docker-compose.prod.yml` and `docker-compose.ghcr.yml`.

The overlay file `math-app/docker-compose.marketing.yml` does this for dev (`Host(\`localhost\`)`). For prod, edit those base files directly, or create `docker-compose.prod.marketing.yml` with `${DOMAIN}`.

## SEO checklist

- [x] `<title>` and `<meta description>` on every page
- [x] OpenGraph + Twitter card
- [x] `<link rel="canonical">` per page
- [x] `<link rel="alternate" hreflang>` vi/en/x-default
- [x] JSON-LD: Organization, WebSite, SoftwareApplication, FAQPage, Course, BreadcrumbList
- [x] `theme-color`, `manifest.webmanifest`, `apple-touch-icon`
- [x] Critical CSS inlined
- [x] `<html lang="vi">` / `<html lang="en">` correct
- [x] `robots.txt` with AI-bot blocks
- [x] Sitemap with hreflang
- [x] `noindex` on the Flutter app shell (it duplicates content)
- [x] Canonical on Flutter app shell points to marketing site
- [x] OG image 1200×630
- [x] Bilingual content
- [x] Mobile-responsive (Tailwind)

## Pending (Phase 3+)

- [ ] Blog content (8–10 vi posts, 3–4 en posts) — high-volume Vietnamese keywords
- [ ] Per-subject landing pages with course previews
- [ ] Real OG images with course screenshots
- [ ] Plausible/Umami analytics
- [ ] Google Search Console + Bing Webmaster submit
- [ ] Cloudflare cache rules
- [ ] Vietnamese keyword validation (let me know if you want me to do this)

## File map

```
marketing-site/
├── astro.config.mjs            # Astro config + sitemap i18n
├── tailwind.config.mjs         # Brand palette (mirrors Flutter AppColors)
├── tsconfig.json
├── package.json
├── nginx.conf                  # For marketing-site container
├── public/
│   ├── brand/                  # Favicon, OG images, icons (auto-generated)
│   ├── manifest.webmanifest
│   ├── robots.txt
│   └── .well-known/security.txt
├── scripts/
│   ├── gen_brand_assets.py     # Regenerate brand assets (OG, favicon, etc.)
│   └── fetch_lessons.py        # Fetch curriculum → src/data/*.json
├── src/
│   ├── data/                   # Generated: subjects.json, lessons.json
│   ├── lib/
│   │   ├── i18n.ts             # Site URL helpers
│   │   ├── nav.ts              # i18n nav strings
│   │   └── multilingual-sitemap.js  # (unused — kept for reference)
│   ├── components/
│   │   ├── Header.astro
│   │   └── Footer.astro
│   ├── layouts/
│   │   └── BaseLayout.astro    # Full <head> SEO surface
│   └── pages/
│       ├── index.astro         # VI landing
│       ├── en/index.astro      # EN landing
│       ├── lessons/
│       │   ├── index.astro
│       │   └── [subject]/
│       │       ├── index.astro
│       │       └── [grade].astro
│       ├── personas/index.astro
│       ├── pricing.astro
│       ├── parents.astro
│       ├── about.astro
│       ├── privacy.astro
│       ├── terms.astro
│       ├── app.astro
│       └── 404.astro
└── dist/                       # Build output (gitignored)
```

## Re-running after VPS changes

The marketing-site container serves from `/var/www/marketing/` (mounted as a Docker volume). After `rsync`, just restart the container to clear any in-memory cache:

```bash
ssh $VPS "docker compose -f docker-compose.yml -f docker-compose.marketing.yml restart marketing-site"
```

Nginx doesn't cache anything by default, so a restart is mostly cosmetic.

## License

MIT

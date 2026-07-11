# HocVui SEO Operations

Operational runbook for the marketing site at sekklings.com.

## Live state

| Component | URL | Status |
|---|---|---|
| Marketing site (root) | `https://sekklings.com/` | 240+ HTML pages, vi+en, sitemap |
| Flutter app | `https://sekklings.com/app/` | /app/ prefix, stripprefix middleware |
| Umami analytics | `https://sekklings.com/umami/` | self-hosted, cookie-free |
| Blog | `https://sekklings.com/blog/` | vi blog, EN blog, RSS |
| Newsletter | `https://sekklings.com/newsletter` | Buttondown embed (configurable) |
| Sitemap | `https://sekklings.com/sitemap-index.xml` | auto-generated, hreflang |
| Robots | `https://sekklings.com/robots.txt` | blocks /app/, AI bots blocked |

## Containers

| Service | Container | Port |
|---|---|---|
| Traefik | `math-app-traefik-1` | 80, 443 (via Cloudflare) |
| Marketing | `math-app-marketing-site-1` | 80 (internal) |
| Umami | `math-app-umami-1` | 3000 (internal) |
| Umami DB | `math-app-umami-db-1` | 5432 (internal) |
| Flutter web | `math-app-flutter-web-1` | 80 (internal) |
| 7 backend services | `math-app-{auth,user,content,...}-service-1` | 3000 (internal) |
| PostgreSQL × 8 | `math-app-*-db-1` | 5432 (internal) |

All routed through Traefik. The `Host(sekklings.com)` rule sends:
- `/app/*` → flutter-web (priority 50, with `/app` prefix stripped)
- `/umami/*` → umami (priority 50, with `/umami` prefix stripped)
- `/api/*` → backend services (priority 100)
- everything else → marketing-site (priority 10)

www.sekklings.com redirects to apex (sekklings.com).

## Daily operations

### Check site health

```bash
ssh root@194.233.94.167 "docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'marketing|umami|flutter-web|traefik'"
```

All should show "Up X hours/days".

### Check Umami is receiving events

Visit `https://sekklings.com/` in a real browser. Then check:
- `https://sekklings.com/umami/` → login (admin / the password you set)
- Dashboard → Real-time → should show your visit within 30s

### Smoke test all routes

```bash
for path in / /lessons /lessons/numbers/3 /lessons/algebra/7 /blog /newsletter /en /en/lessons /en/blog; do
  curl -sS -o /dev/null -w "$path: HTTP %{http_code} | size: %{size_download}\n" \
    "https://sekklings.com$path"
done
```

All should be HTTP 200 or 301 (Astro's trailing-slash redirect).

### View Traefik logs

```bash
ssh root@194.233.94.167 "tail -f /var/log/traefik/access.log"
```

Or Traefik dashboard:
```bash
# From local, via SSH tunnel:
ssh -L 8083:127.0.0.1:8083 root@194.233.94.167
# Then open http://localhost:8083 in your browser
```

## Weekly operations

### Cloudflare cache

If you deploy changes, Cloudflare edge cache may still serve the old version. Three options:

1. **Wait**: Default cache TTL is 2 hours. Most changes propagate within 4 hours.
2. **Manual purge**: Cloudflare dashboard → sekklings.com → Caching → Purge Everything.
3. **API purge** (recommended): Set `CLOUDFLARE_TOKEN` and `CLOUDFLARE_ZONE` in `.env.deploy`, then:
   ```bash
   CLOUDFLARE_TOKEN=xxx CLOUDFLARE_ZONE=yyy ./scripts/purge-cloudflare.sh
   ```

### Check Google Search Console

1. Go to https://search.google.com/search-console/
2. Select `https://sekklings.com/` (verify DNS first time via TXT record)
3. **Sitemaps** → submit `https://sekklings.com/sitemap-index.xml`
4. **URL Inspection** → test a few URLs: `/`, `/lessons/numbers/3`, `/blog/bai-tap-toan-lop-1/`
5. **Coverage** → check for errors weekly

### Check Bing Webmaster Tools

1. Go to https://www.bing.com/webmasters
2. Add site (verify via BingWebmaster auth file or DNS)
3. Submit `https://sekklings.com/sitemap-index.xml`

### Review Umami weekly

- Top pages by views
- Top referrers (Google, Facebook, direct)
- Bounce rate by page
- Custom events: `newsletter_signup`

## Deploy new content

### Blog post

1. Drop MDX file in `marketing-site/src/content/blog/<slug>.md`
2. (Optional) Drop hero image in `marketing-site/public/blog/hero-<slug>.png` (1200×630)
3. Run `cd marketing-site && npm run build` to verify
4. Run `./scripts/deploy-marketing.sh` (or `make deploy-vps` for full deploy)
5. After deploy, submit URL in GSC for faster indexing

### Course content update (new lessons added in CMS)

When a teacher adds new lessons to the content-service:

```bash
cd math-app/marketing-site
npm run fetch:lessons   # refreshes data from API
npm run build
./scripts/deploy-marketing.sh
```

The new lesson counts flow through to all 92 (subject, grade) pages automatically.

## SEO settings that need one-time setup

### Google Search Console

- [ ] Verify domain (DNS TXT)
- [ ] Submit `https://sekklings.com/sitemap-index.xml`
- [ ] Set target country: Vietnam
- [ ] Enable URL Inspection for `/`, `/lessons/numbers/3`, `/blog/bai-tap-toan-lop-1/`

### Bing Webmaster Tools

- [ ] Add site
- [ ] Submit `https://sekklings.com/sitemap-index.xml`

### Cloudflare

- [ ] Caching → Tiered Cache: Enabled
- [ ] Caching → Browser Cache TTL: Honor origin (we set this in nginx)
- [ ] Caching → Crawler Hints: Enabled
- [ ] DNS → Enable proxy (orange cloud) for sekklings.com
- [ ] SSL/TLS → Full (strict)
- [ ] Always Online: Enabled
- [ ] Auto Minify: HTML, CSS, JS
- [ ] Brotli: Enabled
- [ ] Early Hints: Enabled

### Umami

- [x] Container running
- [x] Website created (id: 2153c8a8-f486-4b72-9284-332c036d1c16)
- [x] Tracking script in BaseLayout + Flutter index.html
- [x] Admin password changed from default
- [ ] (Optional) Set up shareable dashboard URL for marketing team

### Buttondown (newsletter)

- [ ] Sign up at https://buttondown.com
- [ ] Create newsletter "HocVui Tips for Parents"
- [ ] Set `PUBLIC_BUTTONDOWN_USER` in `marketing-site/.env` to your Buttondown username
- [ ] Rebuild + deploy
- [ ] Test signup form

## Monitoring alerts to set up

Recommended alerts (use whichever monitor you have — UptimeRobot, Betterstack, etc.):

| Endpoint | Expected | Alert if |
|---|---|---|
| `https://sekklings.com/` | 200 | not 200, or response > 3s |
| `https://sekklings.com/app/` | 200 | not 200 |
| `https://sekklings.com/api/content/health` | 200 (117B JSON) | not 200 |
| `https://sekklings.com/umami/api/heartbeat` | 200 (11B JSON) | not 200 |
| `https://sekklings.com/sitemap-index.xml` | 200 (text/xml) | not 200 |
| `https://sekklings.com/og-lessons/og-numbers-grade-3.png` | 200 (34KB image) | not 200 |

Set checks every 5 min. Alert on 2 consecutive failures.

## Local Umami admin access (via SSH tunnel)

```bash
ssh -L 8083:127.0.0.1:8083 root@194.233.94.167
# Browse to http://localhost:8083/umami/ (Traefik routes it)
# Login: admin / (your password)
```

## Credentials cheat sheet

| Service | Where stored |
|---|---|
| VPS root SSH | `~/.ssh/vps-deploy` + ssh-agent |
| VPS .env | `/root/math-app/math-app/.env` |
| Umami admin | `/tmp/umami-creds.txt` (chmod 600, on laptop) |
| Umami DB | `/root/math-app/math-app/.env` (`UMAMI_DB_PASS`) |
| Buttondown | Set when you sign up |
| GSC | Google account |
| Bing | Microsoft account |
| Cloudflare | Cloudflare account |

## When things go wrong

### Marketing site shows old content (cached)

1. Wait 2-4 hours for Cloudflare cache to expire
2. Or run `./scripts/purge-cloudflare.sh`
3. Or purge manually: Cloudflare dashboard → Caching → Purge Everything

### Umami shows 0 events

1. Check script tag is present: `curl -s https://sekklings.com/ | grep umami`
2. Check umami container health: `docker ps | grep umami`
3. Check umami DB: `docker exec math-app-umami-db-1 pg_isready -U umami -d umami`
4. Open DevTools Network tab, visit page, look for `script.js` request to `/umami/script.js`

### Flutter app is broken

1. Check container: `docker ps | grep flutter-web`
2. Restart: `cd /root/math-app/math-app && docker compose -f docker-compose.prod.yml restart flutter-web`
3. If persistent, rebuild: `docker compose up -d --no-deps --force-recreate --build flutter-web`

### 500 errors

1. Check Traefik logs: `ssh root@194.233.94.167 "docker logs math-app-traefik-1 --tail 50"`
2. Check service logs: `docker logs math-app-marketing-site-1 --tail 50` (or other service)
3. Check for OOM: `docker stats --no-stream`

## Future work (deferred)

- [ ] Vietnamese keyword research (validate the 13 keywords in PLAN_HOCVUI_SEO.md)
- [ ] User writes 8-10 blog posts (per docs/WRITING_BLOG.md)
- [ ] Per-subject landing pages with course previews (currently uses aggregated catalog)
- [ ] Newsletter migration to real Buttondown account
- [ ] A/B test OG images (Phase 4 used synthetic; Phase 2.1 of PLAN used real screenshots)
- [ ] Lighthouse 100/100 on the landing page
- [ ] Vietnamese keyboard switching (cSpell, IME)
- [ ] More sample blog posts in `src/content/blog-en/`

## License

MIT

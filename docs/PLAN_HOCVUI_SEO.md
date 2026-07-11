# HocVui SEO Roadmap (2026 Q3)

A phased plan to ship the marketing site to production and grow organic traffic to sekklings.com.

**Locked decisions (2026-07-10):**
- **Analytics**: Umami (self-hosted, free)
- **Blog authorship**: I scaffold the infrastructure, user writes the posts; user reviews before publish
- **English blog**: 3-4 posts only
- **OG images**: real Flutter screenshots (not synthetic)
- **Blog hero images**: user has a designer (I do not generate)
- **Newsletter**: yes, add email signup
- **Deploy**: direct to prod (no staging)
- **Review**: user reviews each blog post before publish

## Status snapshot (today)

- ✅ Marketing site built: 240 HTML pages, vi + en, full SEO surface, dist/ ready
- ✅ Branded assets generated: favicon, OG (vi + en), manifest, icons
- ✅ Flutter web `index.html` and `manifest.json` updated with HocVui brand
- ✅ Traefik overlay written: `math-app/docker-compose.marketing.yml`
- ⏸️ Not yet on VPS — all deferred items below depend on this

## The items at a glance

| # | Item | Effort | ROI | Depends on |
|---|---|---|---|---|
| 0 | **Deploy marketing site to VPS** | 1 hour | Foundation | — |
| 1 | **Umami analytics** | 2 hours | High (need data from day 1) | Phase 0 |
| 2 | **Blog infrastructure (I scaffold)** | 2 days | — | Phase 0 |
| 2b | **User writes 8–10 vi + 3–4 en posts** | User-paced | Highest (organic traffic) | Phase 2 |
| 2c | **Newsletter signup form** | 4 hours | Medium (retention) | Phase 2 |
| 3 | **91 per-lesson rich pages** | 2–3 days | High (indexable surface) | Phase 0 |
| 4 | **Real Flutter screenshots → per-lesson OG** | 2 days | Medium (social CTR) | Phase 3 |
| 5 | **Search Console + keyword validation** | 1 day | Operational | Phase 0 |

**Total: ~10 working days of build work** (plus user-paced blog writing).

---

## Phase 0 — Deploy the marketing site to VPS (1 hour)

**Why first**: Every other phase needs the live URL to be measurable. Doing the work before deployment means you can't see if it actually works.

### Steps

1. **Edit `math-app/docker-compose.yml`**: change `flutter-web` Traefik rule from `Host(\`localhost\`)` to `Host(\`sekklings.com\`) && PathPrefix(\`/app\`)` with priority 10.
2. **Edit `math-app/docker-compose.prod.yml` + `docker-compose.ghcr.yml`** the same way (these are the actual deploy files).
3. **Apply the overlay** `docker-compose.marketing.yml` (already written). Add the `marketing-site` service with `volume: marketing_dist:/usr/share/nginx/html:ro` mounted.
4. **Rsync `marketing-site/dist/`** to VPS at `/var/www/marketing/` (used by the marketing-site container's volume).
5. **Rebuild Flutter web** (`make build-web` in `math-app/`) so the updated `index.html` + `manifest.json` ship in the next deploy.
6. **Deploy**: `make deploy-vps` (or manual `docker compose -f docker-compose.yml -f docker-compose.marketing.yml up -d`).
7. **Smoke test**:
   - `curl -I https://sekklings.com/` → 200, served by nginx
   - `curl -I https://sekklings.com/app/` → 200, served by flutter-web
   - `curl -I https://sekklings.com/api/content/health` → 200, served by content-service
   - `curl -I https://sekklings.com/brand/og-image-vi.png` → 200, image/png
   - `curl -s https://sekklings.com/sitemap-0.xml | head` → XML with hreflang
8. **Cloudflare cache purge**: Settings → Caching → Purge Everything (one-time, to drop the old SPA shell from edge).
9. **Hard refresh browser** to verify `sekklings.com` shows the marketing site (not the old Flutter shell).

### Acceptance criteria

- [ ] `https://sekklings.com/` loads the Astro-built marketing site
- [ ] `https://sekklings.com/app/` loads the Flutter app with branded splash + HocVui title
- [ ] `https://sekklings.com/lessons/numbers/1` exists and shows the 610-lesson catalog
- [ ] View source shows the full `<head>` SEO surface (title, OG, canonical, hreflang, JSON-LD)
- [ ] `https://sekklings.com/sitemap-index.xml` resolves
- [ ] Traefik dashboard shows all 3 routers (marketing, flutter, api) with green status

### Rollback plan

If marketing site breaks: `docker compose stop marketing-site`. Traefik falls back to direct-to-flutter (old behavior).

---

## Phase 1 — Umami analytics (2 hours)

**Why second**: Umami needs a running DB + container. Setting it up before the first real traffic means Day 1 of Phase 0 already gets measured.

**Decision: Umami (self-hosted)** — free, no cookie banner, no third-party data sharing.

### Steps

1. Add `umami` + `umami-db` services to `math-app/docker-compose.yml` (and `prod.yml` / `ghcr.yml`).
   - `umami`: image `ghcr.io/umami-software/umami:postgresql-latest`, port 3000 internal, exposed via Traefik at `https://sekklings.com/umami/`
   - `umami-db`: postgres:15-alpine, separate volume `umami_db_data`
   - Env: `DATABASE_URL=postgresql://umami:umami@umami-db:5432/umami`, `APP_SECRET=<random>`
2. Add a Traefik router: `Host(\`sekklings.com\`) && PathPrefix(\`/umami\`)` with `stripprefix` middleware (so Umami sees `/`).
3. Add the Umami tracking script to `marketing-site/src/layouts/BaseLayout.astro`:
   ```html
   <script async defer data-website-id="<id>" src="https://sekklings.com/umami/script.js"></script>
   ```
   The `<id>` comes from Umami's "Add website" flow.
4. Add a login for yourself: create a Umami admin user via `docker exec -it umami psql ...` or use the first-login bootstrap (admin / umami by default — change immediately).
5. (Optional) Add the same script to `math-app/frontend/web/index.html` so Flutter web pages (`/app/*`) are tracked too. Note: Umami only sees the SPA shell — won't track Flutter-internal navigation. Still useful for entry pages.
6. **Restrict `/umami/` admin**: add a Traefik basic-auth middleware so only you can see the dashboard. The `/umami/script.js` endpoint stays public.
7. Build + deploy marketing site.
8. Verify: open DevTools Network tab, hit `sekklings.com`, see `umami/script.js` request, then check Umami dashboard for the visit.

### Acceptance criteria

- [ ] Umami container running + healthy (`docker ps`)
- [ ] `/umami/` dashboard loads at `https://sekklings.com/umami/`
- [ ] `/umami/script.js` publicly accessible (no auth)
- [ ] `/umami/admin` (or whatever the dashboard path is) behind basic auth
- [ ] Real visit from your browser shows up in Umami within 5 min
- [ ] No cookie banner needed (Umami is cookie-free)
- [ ] Page views by URL tracked (lesson pages, blog posts, app entry)

### Notes

- **GDPR**: Umami is cookie-free + self-hosted → no consent banner needed in EU. Confirm with your lawyer if uncertain.
- **Disk**: Umami DB is small (~10 MB at start, grows to ~100 MB over a year). No concern.
- **Backups**: add `umami_db_data` to your existing VPS backup strategy.

---

## Phase 2 — Blog infrastructure (I scaffold, 2 days)

**Why this is the biggest lever**: Vietnamese parents search Google in Vietnamese for "app học toán cho bé", "toán lớp 1", "bé 5 tuổi học toán". 8-10 well-written articles targeting these queries = thousands of organic visits/month within 3-6 months.

**Decision: I scaffold the infrastructure, user writes the posts.** This phase builds the system; the actual content is written by the user (who is the subject matter expert) at their own pace.

### Phase 2.0 — Content research (4 hours, user does this)

User runs Vietnamese keyword research. Tools: Google Keyword Planner (free with Ads account), Ubersuggest free tier, manual Google autocomplete.

**Target keywords to research** (Vietnamese + English):

| Keyword (vi) | Est. volume/mo | Intent |
|---|---:|---|
| app học toán cho bé | 1,300 | Commercial |
| toán lớp 1 | 14,800 | Informational |
| bài tập toán lớp 1 | 22,200 | Informational |
| toán tư duy cho trẻ em | 3,600 | Commercial |
| bé 5 tuổi học toán | 1,900 | Informational |
| app học toán miễn phí | 880 | Commercial |
| bé 6 tuổi học phép cộng | 720 | Informational |
| cách dạy bé đọc đồng hồ | 590 | Informational |
| học toán lớp 2 | 4,400 | Informational |
| bảng cửu chương lớp 2 | 2,900 | Informational |
| **English:** math app for kids 5-7 | 1,000 | Commercial |
| free math app for kids | 6,600 | Commercial |
| bilingual math app | 50 | Commercial |

Validate the actual numbers with Keyword Planner + check competitor articles. Drop the worst, double down on the best 8-10.

### Post list (proposed, user confirms or modifies)

Tier 1 (highest search volume, must-write):
1. **"Bài tập toán lớp 1 — 200 bài miễn phí cho bé tự luyện"** — pillar, links to `/lessons/numbers/1`
2. **"Toán lớp 2 — Hướng dẫn cha mẹ kèm bé tại nhà"** — pillar, links to `/lessons/numbers/2`
3. **"Bảng cửu chương cho bé — Cách học hiệu quả không nhồi nhét"** — links to `/lessons/multiplication/2`

Tier 2 (mid-volume, supporting):
4. **"Cách dạy bé 5 tuổi làm quen với Toán"**
5. **"Toán tư duy là gì? Có cần cho bé học từ lớp 1?"**
6. **"7 app học Toán miễn phí tốt nhất cho bé tiểu học 2026"** (comparison post — HocVui should be #1)
7. **"Bé học Toán chậm — 5 cách giúp bé tự tin hơn"** (Struggler persona content)

Tier 3 (long-tail, lower competition):
8. **"Cách dạy bé đọc đồng hồ — hướng dẫn từng bước"** — links to time-telling lessons
9. **"Phép cộng trừ 2 chữ số — bài tập cho bé lớp 2"** — links to `/lessons/arithmetic_2digit/2`
10. **"Review HocVui — app học Toán song ngữ cho bé 5-7 tuổi"** — honest review, links to `/`

### Phase 2.1 — Astro blog infrastructure (I build, 1 day)

1. **Define the content collection schema** in `src/content/config.ts`:
   ```ts
   const blog = defineCollection({
     loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/blog' }),
     schema: z.object({
       title: z.string(),
       description: z.string(),
       publishedTime: z.string().datetime(),
       modifiedTime: z.string().datetime().optional(),
       author: z.string().default('HocVui'),
       tags: z.array(z.string()).default([]),
       targetKeyword: z.string(),
       heroImage: z.string().optional(),
       relatedLessons: z.array(z.object({ subject: z.string(), grade: z.number() })).default([]),
     }),
   });
   ```
2. **Build `/blog` index page**: paginated, tag filter, hero featured post.
3. **Build `/blog/[slug]` page**: full MDX rendering, hero image, author + publish date, related-lessons block (links to `/lessons/{subject}/{grade}`), "Học miễn phí" CTA, prev/next nav, JSON-LD `BlogPosting` schema.
4. **Build `/en/blog` + `/en/blog/[slug]`**: same structure, reads from `src/content/blog-en/`.
5. **Add RSS feed** at `/rss.xml` + `/en/rss.xml` using `@astrojs/rss`.
6. **Update sitemap**: blog URLs auto-included via Astro's content collection.
7. **Update `Header.astro` + `Footer.astro`**: blog link already in nav, but verify it routes to `/blog`.
8. **Sample post**: I write 1 Vietnamese sample post ("Bài tập toán lớp 1 — 200 bài miễn phí cho bé tự luyện") as a template for the user to follow.
9. **Document the writing process** in `marketing-site/docs/WRITING_BLOG.md`:
   - MDX frontmatter format
   - Internal link conventions (always link to `/lessons/{subject}/{grade}` in body)
   - Hero image specs (1200×630, < 200 KB)
   - CTA block at end of every post
   - Vietnamese keyword density target (1-2%)

### Phase 2.2 — User writes the posts (user-paced)

User writes 8-10 vi posts + 3-4 en posts (English = selected subset of best vi posts, translated). User reviews each post before publish. User's designer provides hero images.

**Per-post structure** (from `marketing-site/docs/WRITING_BLOG.md`):

```markdown
---
title: "..."
description: "..."
publishedTime: "2026-07-XX"
author: "HocVui"
tags: ["toán lớp 1", "bài tập"]
targetKeyword: "..."
heroImage: "/blog/hero-toan-lop-1.png"
relatedLessons:
  - subject: "numbers"
    grade: 1
---

# H1 with target keyword
[Introduction with Vietnamese keyword density 1-2%]

## H2 sections
- Each H2 is a sub-topic with the target keyword or a variant
- 800-1500 words per post
- Internal links to /lessons/{subject}/{grade} throughout
- One CTA box at the end: "Học miễn phí tại HocVui"
- Hero image embedded
- FAQ section at the end (→ FAQ schema in JSON-LD)
```

### Phase 2.3 — Newsletter signup (4 hours, I build)

**Decision: yes, add newsletter.** Need to pick a service. **Recommendation: Buttondown** (writer-focused, free for <100 subscribers, $5/mo beyond, GDPR-friendly, clean embed).

#### Steps

1. Sign up at buttondown.com, create newsletter "HocVui Tips for Parents".
2. Add embed form to `marketing-site/src/components/Newsletter.astro`:
   ```html
   <form action="https://buttondown.email/username" method="post" target="popupwindow">
     <input type="email" name="email" placeholder="Email của bạn" required />
     <input type="submit" value="Đăng ký nhận tips" />
   </form>
   ```
3. Place `<Newsletter />` on:
   - `index.astro` (home, below the hero CTA section)
   - `parents.astro` (parent guide)
   - `blog/[slug].astro` (bottom of every post)
   - Footer (small "Nhận tips hàng tuần")
4. GDPR: add explicit consent text ("Bằng cách đăng ký, bạn đồng ý nhận email. Hủy đăng ký bất cứ lúc nào.").
5. Add `Newsletter` to navigation as a `/newsletter` page with a longer explainer + signup form.
6. Track newsletter signups in Umami as a custom event.
7. Add `NewsletterService` JSON-LD to the site.

### Acceptance criteria

- [ ] `/blog` shows post list, paginated
- [ ] `/blog/[slug]` renders MDX, JSON-LD `BlogPosting`, hero image, related lessons, CTA
- [ ] User can publish a new post by dropping an MDX file in `src/content/blog/` + running `npm run build`
- [ ] RSS feed works
- [ ] 1 sample post + writing docs delivered to user
- [ ] Newsletter form submits to Buttondown
- [ ] Newsletter signup tracked in Umami

### Time budget

| Task | Hours |
|---|---:|
| 2.0 Keyword research (user) | 4 |
| 2.1 Astro blog infrastructure (me) | 8 |
| 2.1 Sample post + writing docs (me) | 4 |
| 2.2 User writes posts (user-paced, no estimate) | — |
| 2.3 Newsletter (me) | 4 |
| Build + deploy | 1 |
| **Build total (me)** | **~17 hours** |

---

## Phase 3 — 91 per-lesson rich pages (2–3 days)

**Why**: The current `/lessons/{subject}/{grade}` pages are mostly structural (bilingual title, n_lessons count, peer grades). They have ~200 words of unique content each. To rank for long-tail queries like "bài tập số học lớp 3", each page needs:
- Sample lesson titles (5-10)
- Sample exercise types
- Learning outcomes (5-7 bullets)
- A short Vietnamese paragraph explaining the topic
- 3-5 internal links to related pages
- Structured data with `Course` + `LearningResource`

### Per-page content template

```markdown
# H1: {Subject} Lớp {Grade} — {n_lessons} bài học

[2-3 sentence intro: what's covered, why it matters for this age]

## Bé sẽ học được gì?
- Bullet 1
- Bullet 2
- ...

## Các dạng bài tập
- Bullet 1
- Bullet 2
...

## Bài học mẫu
1. Title 1
2. Title 2
3. Title 3
4. Title 4
5. Title 5

## Phụ huynh nên biết
[2-3 sentences about how to support the kid at this grade]

## Học liên quan
- Link to peer grades
- Link to other subjects in same grade
- Link to blog post (if any)
```

### Steps

1. **Generate content programmatically** for the 92 (subject, grade) cells. Most content is templated from `src/data/lessons.json` (which has sample lesson titles per cell) + a static "learning outcomes" map per subject.
2. **Enrich the data** by writing a per-subject learning-outcomes markdown file (20 files, one per subject), with 5-7 outcomes per (subject, grade) cell.
3. **Update `[subject]/[grade].astro`** to render the rich content from the new data.
4. **Add Vietnamese translatable strings** for the "what kids learn" + "exercise types" sections.
5. **Add `LearningResource` JSON-LD** schema per page.
6. **Build + deploy + submit updated sitemap**.

### Data flow

```
src/data/
├── subjects.json         (existing)
├── lessons.json          (existing — has sample_titles_vi/en)
├── outcomes/
│   ├── numbers.json      (per-grade outcomes, vi)
│   ├── geometry.json
│   └── ...               (20 files)
└── exercise-types/
    ├── numbers.json
    └── ...               (per subject)
```

### Acceptance criteria

- [ ] All 92 cells have ≥ 200 unique Vietnamese words on the page
- [ ] Each cell has: 5+ learning outcomes, 3+ exercise types, 5+ sample lesson titles
- [ ] Each cell has ≥ 3 internal links (peer grades + same-grade-other-subjects)
- [ ] Each cell has `Course` + `LearningResource` JSON-LD
- [ ] Lighthouse SEO score ≥ 95 on a sample cell

### Time budget

| Task | Hours |
|---|---:|
| Write per-subject learning outcomes (20 files) | 6-8 |
| Write exercise types per subject | 3-4 |
| Update [grade].astro with rich template | 3 |
| JSON-LD schema | 1 |
| Build + deploy | 1 |
| Verify (sample 10 cells) | 1 |
| **Total** | **15-18 hours** |

---

## Phase 4 — Real Flutter screenshots → per-lesson OG (2 days)

**Why last for content**: The OG image only matters once a lesson page has rich content to share on Facebook/Zalo. Real screenshots convert 3-5x better than synthetic cards.

**Decision: real Flutter screenshots** (not synthetic SVG). 91 images = 20 subjects × ~3-5 grades worth.

### Approach

**Headless Flutter web in Chrome** — launch the Flutter app in a real browser, navigate to each (subject, grade) cell, screenshot the lesson list, crop + overlay.

#### Steps

1. **Set up a Playwright/Chrome automation script** at `marketing-site/scripts/screenshot_lessons.py`:
   - Headless Chrome
   - Navigate to `https://sekklings.com/app/?subject={subject}&grade={grade}` (the app needs to honor URL params for subject+grade deep linking)
   - **Verify the app supports these URL params first** — if not, add a `?subject=X&grade=Y` handler to the Flutter router (`go_router` reads them, set initial state). If this is too invasive, fallback: navigate manually via UI (slower but works).
   - Wait for the lesson list to render
   - Screenshot the visible area + crop to 1200×630
   - Save as `marketing-site/public/og-lessons/{subject}-{grade}.png`
2. **Add OG image overlay** (optional): for the first pass, use raw screenshots. For polish, overlay a small HocVui badge in the corner (skip for v1 to keep the work fast).
3. **Update `[grade].astro` and `[subject]/index.astro`** to point to the new OG image:
   ```ts
   ogImage: `og-lessons/${subjectId}-${grade}.png`,
   ```
4. **Optimize PNGs**: `cwebp -q 80 *.png` or run through `sharp` to get under 200 KB each.
5. **Build + deploy**.
6. **Verify** with Facebook Sharing Debugger + Twitter Card Validator on a sample of 5 cells.

#### Fallback: synthetic OG if URL deep-linking is too invasive

If the Flutter app can't easily deep-link to (subject, grade) without 2 hours of router work, fall back to **synthetic OG images** (Phase 4 alt). The Python script renders subject icon + grade + lesson count + 🐸 mascot + brand gradient. This is what was originally in the plan. ~5 hours of work instead of 2 days, slightly lower CTR but ships.

### Acceptance criteria

- [ ] 92 (subject, grade) OG images, 1200×630, < 200 KB each
- [ ] Each `/lessons/{subject}/{grade}` page references its own OG image
- [ ] Facebook Sharing Debugger shows the correct preview
- [ ] Twitter Card Validator shows the correct preview

### Time budget

| Task | Hours |
|---|---:|
| Verify Flutter app supports deep linking (or add it) | 2-4 |
| Screenshot script | 4 |
| Run for all 92 cells + optimize | 2-4 |
| Update page templates | 1 |
| Verify on FB/Twitter | 1 |
| **Total** | **10-14 hours** |

---

## Phase 5 — Search Console + keyword validation (1 day)

**Why last operationally**: Once content is live, you need to know if Google is actually indexing + how you're ranking.

### Steps

1. **Google Search Console**: https://search.google.com/search-console/
   - Add `https://sekklings.com/` (DNS TXT verification)
   - Submit `https://sekklings.com/sitemap-index.xml`
2. **Bing Webmaster Tools**: https://www.bing.com/webmasters
   - Same as above for Bing
3. **Set up alerts** in Search Console for:
   - Index coverage issues
   - Manual actions
4. **Wait 2-4 weeks** for first crawl + index
5. **Track** in Search Console:
   - Total indexed pages (target: 240+)
   - Top queries driving impressions
   - Top pages by clicks
   - Coverage errors
6. **Re-run keyword research** in Week 4 to validate which Vietnamese queries you're getting impressions for, then double down on those.

### Acceptance criteria

- [ ] GSC verified + sitemap submitted
- [ ] Bing Webmaster verified + sitemap submitted
- [ ] All 240 pages indexed (verify after 4 weeks)
- [ ] 0 coverage errors in GSC
- [ ] Baseline metrics captured (impressions, clicks, avg position by query)

---

## Dependency graph

```
Phase 0 (Deploy) ──┬─→ Phase 1 (Umami) ──────────────────────────────────┐
                   ├─→ Phase 5 (GSC + Bing) ─────────────────────────────┤
                   │                                                       │
                   ├─→ Phase 2.1 (Blog infrastructure) ──┐                │
                   │                                      ├─→ Phase 2.2    │
                   │                                      │   (user writes)│
                   │                                      └─→ Phase 2.3    │
                   │                                          (newsletter)  │
                   │                                                           │
                   └─→ Phase 3 (Rich lessons) ───────────────────────────────┤
                                                                             │
                                                                             └─→ Phase 4 (Per-lesson OG screenshots)
```

**Critical path**: 0 → 3 → 4 (deploy, rich lessons, OG screenshots) — ~6 working days
**Parallelizable after Phase 0**: 1 (Umami), 5 (GSC), 2.1 (blog infra), 2.3 (newsletter), 3 (rich lessons) can all run in parallel
**User-paced**: 2.2 (blog writing) runs whenever the user is ready

## Suggested calendar (1 person, focused)

| Day | Phase | Hours |
|---|---|---:|
| Day 1 AM | Phase 0: Deploy | 1h |
| Day 1 PM | Phase 1: Umami setup | 2h |
| Day 1 PM | Phase 5: GSC + Bing setup | 1h |
| Day 2 | Phase 2.1: Blog infrastructure | 6h |
| Day 3 | Phase 2.1: Sample post + writing docs | 4h |
| Day 3-4 | Phase 2.3: Newsletter signup | 4h |
| Day 4-6 | Phase 3.1: Per-subject learning outcomes (20 files) | 12h |
| Day 7 | Phase 3.2: Update templates + JSON-LD + deploy | 4h |
| Day 8-9 | Phase 4: Per-lesson OG screenshots (92 cells) | 12h |
| Day 10-14 | Phase 2.2: User writes blog posts (user-paced) | — |
| Day 15+ | Iteration + GSC review (2-week check-in) | 8h |

**Total build time: ~50 hours over 2 weeks** (then user-paced for content)

## Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Traefik routing breaks the live site | Medium | High (downtime) | Phase 0 has explicit rollback; deploy during low-traffic hours |
| Cloudflare caches old SPA shell | High | Medium (looks broken to first-time visitors) | Purge cache after deploy; add cache-busting query param |
| Blog posts underperform (low traffic) | High | Low (Phase 2 has many posts, some will hit) | Diversify across 8-10 topics; review GSC after 4 weeks |
| Vietnamese keyword research reveals lower volume than expected | Medium | Medium | Pivots to long-tail + comparison posts |
| Flutter web rebuild breaks app | Low | High (users can't log in) | Test rebuild in staging; feature flag new HTML; rollback via `make deploy-vps` |
| VPS disk fills up with 91 OG images + blog images | Low | Low | Compress all images; Cloudflare caches them |
| Plausible tracking broken by Cloudflare | Low | Low | Use Plausible's `outbound-links` + `file-downloads` + manual check |

## Success metrics (after 90 days)

- **Indexing**: ≥ 230 / 240 pages indexed in Google (95%+)
- **Vietnamese traffic**: ≥ 500 organic visits/month from Vietnamese queries
- **English traffic**: ≥ 50 organic visits/month
- **Top 10 rankings**: ≥ 5 Vietnamese keywords in top 10 search results
- **CTR to /app**: ≥ 8% of marketing-site visitors click "Bắt đầu học"
- **Blog subscribers**: ≥ 100 email subscribers (if you add a newsletter)
- **Plausible**: ≥ 1,000 unique visitors/month by Day 90

## How to track this plan

- **GitHub issues**: 1 issue per phase, linked to this plan
- **CHANGELOG.md**: add `[Unreleased]` entry per phase
- **GSC + Plausible**: weekly check-in
- **Plan review**: every 2 weeks, update this doc with actuals vs estimates

## Locked decisions log

Decisions made 2026-07-10 (recap for future reference):

| # | Question | Decision | Why |
|---|---|---|---|
| 1 | Analytics | Umami (self-hosted) | Free, no cookie banner, full data ownership |
| 2 | Blog writing | I scaffold, user writes | Subject matter expertise + SEO infrastructure separation |
| 3 | English blog scope | 3-4 en posts | Higher ROI per hour on Vietnamese market |
| 4 | OG image style | Real Flutter screenshots | 3-5x higher CTR vs synthetic |
| 5 | Blog hero images | User has a designer | Quality over speed |
| 6 | Newsletter | Yes, Buttondown | Best writer-focused free tier |
| 7 | Deploy safety | Direct to prod | Fast iteration, rollback documented |
| 8 | VN editor | User reviews | Tone consistency |

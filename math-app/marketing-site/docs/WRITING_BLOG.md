# HocVui Blog — Writing Guide

A reference for writing Vietnamese + English blog posts for sekklings.com.

## TL;DR

1. Pick a keyword from the [Vietnamese keyword list](#vietnamese-keywords) (or your own)
2. Write a 800–1500 word MDX file in `src/content/blog/<slug>.md`
3. Use the frontmatter template below
4. Internal link to 3–5 `/lessons/{subject}/{grade}/` pages
5. End with a "Học miễn phí" CTA
6. Drop the hero image (1200×630) in `public/blog/`
7. `cd marketing-site && npm run build` to verify it builds
8. Run `./scripts/deploy-marketing.sh` (or `make deploy-vps`) to ship

## File format

Drop a new file at: `marketing-site/src/content/blog/<slug>.md`

`<slug>` should be lowercase, hyphenated, no diacritics (e.g. `toan-tu-duy-cho-tre-em`).

### Frontmatter template

```yaml
---
title: "..."                    # ≤ 60 chars, target keyword near the start
description: "..."              # ≤ 160 chars, includes target keyword
publishedTime: "2026-07-XX..."  # ISO 8601
author: "HocVui"                # default 'HocVui'
tags: ["toán lớp 1", "..."]     # 1-5 lowercase tags
targetKeyword: "..."            # exact phrase you're optimizing for
heroImage: "blog/hero-X.png"    # 1200x630 PNG in public/
relatedLessons:                 # 3-5 internal links to lesson cells
  - subject: "numbers"
    grade: 1
  - subject: "arithmetic_2digit"
    grade: 2
---

# H1 with target keyword as the leading phrase

[200-word introduction that mentions the target keyword 2-3 times naturally]

## First H2 subheading

[Body content with short paragraphs, examples, lists. Mention target keyword 1-2x.]

## Second H2 subheading

[Continue. Aim for 800-1500 words total.]

## FAQ (optional)

### Common question 1?
Answer.

### Common question 2?
Answer.

## Conclusion

[2-3 sentence wrap + CTA pointing to /lessons or /app]
```

### Body conventions

- **H1**: One per post, with the target keyword at the start
- **H2**: 3-6 per post, each containing the target keyword OR a semantic variation
- **Paragraphs**: 2-4 sentences max. Break up walls of text.
- **Lists**: Use bullet/numbered lists for scannable content
- **Bold**: Sparingly, for emphasis on key terms
- **Images**: 1-2 per post, descriptive alt text in Vietnamese
- **Internal links**: 3-5 per post, always link to `/lessons/{subject}/{grade}/`
- **External links**: Only to authoritative sources (.gov.vn, .edu, Wikipedia). Add `rel="noopener"`.
- **CTAs**: One "Học miễn phí" CTA at the end, link to `/lessons/...` or `/app`

### Vietnamese keyword density

- Target keyword should appear 1-2% of total word count (e.g., 8-15 times in 1000 words)
- Use semantic variations: "bài tập Toán lớp 1", "luyện Toán lớp 1", "Toán lớp 1 cho bé"
- Mention the keyword in the first 100 words (above the fold for SEO)
- Mention the keyword in the conclusion
- Don't keyword-stuff — Google penalizes that

## Vietnamese keywords to research

These are estimated volumes (Google Keyword Planner, 2026). Validate before committing:

| Keyword | Est. volume/mo | Difficulty | Intent |
|---|---:|---|---|
| bài tập toán lớp 1 | 22,200 | Medium | Info |
| toán lớp 1 | 14,800 | High | Info |
| học toán lớp 2 | 4,400 | Medium | Info |
| toán tư duy cho trẻ em | 3,600 | Medium | Commercial |
| bảng cửu chương lớp 2 | 2,900 | Low | Info |
| bé 5 tuổi học toán | 1,900 | Low | Info |
| app học toán cho bé | 1,300 | High | Commercial |
| app học toán miễn phí | 880 | Medium | Commercial |
| bé 6 tuổi học phép cộng | 720 | Low | Info |
| cách dạy bé đọc đồng hồ | 590 | Low | Info |
| **English:** math app for kids 5-7 | 1,000 | High | Commercial |
| free math app for kids | 6,600 | High | Commercial |
| bilingual math app | 50 | Low | Commercial |

## Proposed post list (8-10 vi + 3-4 en)

| Tier | Slug | Title (VI) | Target keyword |
|---|---|---|---|
| 1 | bai-tap-toan-lop-1 | Bài tập Toán lớp 1 — 200 bài miễn phí | bài tập toán lớp 1 |
| 1 | toan-lop-2-huong-dan | Toán lớp 2 — Hướng dẫn cha mẹ kèm bé tại nhà | toán lớp 2 |
| 1 | bang-cuu-chuong-cho-be | Bảng cửu chương cho bé — Cách học hiệu quả | bảng cửu chương lớp 2 |
| 2 | cach-day-be-5-tuoi-lam-quen-toan | Cách dạy bé 5 tuổi làm quen với Toán | bé 5 tuổi học toán |
| 2 | toan-tu-duy-la-gi | Toán tư duy là gì? | toán tư duy cho trẻ em |
| 2 | 7-app-hoc-toan-mien-phi | 7 app học Toán miễn phí tốt nhất | app học toán miễn phí |
| 2 | be-hoc-toan-cham | Bé học Toán chậm — 5 cách giúp bé tự tin hơn | bé học toán chậm |
| 3 | cach-day-be-doc-dong-ho | Cách dạy bé đọc đồng hồ | cách dạy bé đọc đồng hồ |
| 3 | phep-cong-tru-2-chu-so | Phép cộng trừ 2 chữ số — bài tập lớp 2 | cộng trừ 2 chữ số |
| 3 | review-hocvui | Review HocVui — app học Toán song ngữ | review hocvui |

For English, translate the best 3-4 (recommend: bai-tap-toan-lop-1, toan-tu-duy-la-gi, 7-app-hoc-toan-mien-phi) and save as `src/content/blog-en/<slug>.md`.

## Hero images

- **Size**: 1200×630 px (Facebook/Twitter/LinkedIn standard)
- **Format**: PNG (smaller) or JPG (smaller still)
- **Style**: Branded — pink gradient, 🐸 mascot, big bold title text, subtle decorative shapes
- **File path**: `public/blog/hero-<slug>.png` (referenced as `blog/hero-<slug>.png` in frontmatter)
- **No image?**: The post still works; the `heroImage` is optional and the page renders fine without it

## Internal linking rules

Every post must have **at least 3 internal links** to `/lessons/{subject}/{grade}/` pages. Use these patterns:

```markdown
[Xem bài tập Toán lớp 1](/lessons/numbers/1/)
[Luyện bảng cửu chương](/lessons/multiplication/2/)
[Đồng hồ tương tác](/lessons/time_money/2/)
[Bé 6 tuổi học phép cộng](/lessons/arithmetic_2digit/2/)
```

Valid `(subject, grade)` pairs (top 20 by lesson count):
- `numbers` × 1-12
- `geometry` × 1-12
- `measurement` × 1-12
- `logic` × 1-12
- `algebra` × 2-12
- `trigonometry` × 3-12
- `statistics` × 4-12
- `arithmetic_2digit` × 2
- `arithmetic_3digit` × 3
- `multiplication` × 2-3
- `division` × 3
- `fractions` × 3
- `decimals` × 3
- `perimeter` × 2
- `area` × 3
- `angles` × 3
- `time_money` × 2
- `volume` × 3
- `speed` × 3
- `word_problems` × 2

## Deploy

After dropping a new post in `src/content/blog/`:

```bash
cd math-app
./scripts/deploy-marketing.sh
```

The script builds, rsyncs to VPS, restarts the marketing container. New post URLs:
- `https://sekklings.com/blog/<slug>/`
- `https://sekklings.com/blog/rss.xml`

Within 1-3 days, Google should pick up the new URL via the sitemap.

## Review checklist before publish

- [ ] Title ≤ 60 chars, includes target keyword
- [ ] Description ≤ 160 chars, includes target keyword
- [ ] Body 800-1500 words
- [ ] Target keyword density 1-2%
- [ ] 3-5 internal links to `/lessons/...` (all working, not 404)
- [ ] Hero image 1200×630, < 200 KB
- [ ] Hero image has descriptive alt text in the markdown
- [ ] One CTA at the end linking to /lessons or /app
- [ ] H2 subheadings include semantic variations of the target keyword
- [ ] Optional FAQ section with 2-4 Q&As (Schema.org FAQPage)
- [ ] Build passes: `cd marketing-site && npm run build`
- [ ] Preview in browser, click all links
- [ ] Tone is helpful, not salesy. No AI clichés ("In today's fast-paced world...")
- [ ] Vietnamese is natural — read it aloud to check

## Common mistakes

- ❌ **Title too long**: Google truncates at ~60 chars in search results
- ❌ **Description too long**: Truncated at ~160 chars
- ❌ **No internal links**: Reduces SEO value, increases bounce rate
- ❌ **Keyword stuffing**: 5%+ density = Google penalty
- ❌ **Hero image too big**: 1 MB images slow the page. Aim for < 200 KB
- ❌ **No alt text on hero image**: Missed SEO + a11y
- ❌ **Forgetting the CTA**: Readers don't know what to do next
- ❌ **AI tone**: "Bé yêu của bạn xứng đáng được yêu thương!" → write naturally

## FAQ

### Can I write a post that's only English?

Yes — drop it in `src/content/blog-en/` instead. The Vietnamese blog has its own RSS feed, the English blog has its own.

### How long until Google indexes a new post?

Usually 1-3 days for new posts on a domain with established trust. Use Google Search Console's URL Inspection tool to request indexing immediately.

### Can I schedule a post for the future?

Set `publishedTime` to a future date, and add `draft: true` to the frontmatter. Astro won't include draft posts in production. Remove `draft: true` when ready.

### What about the person who wrote the post? Author bio?

Posts default to "HocVui" as author. If you want a real author name (e.g., "Cô Mai, GV Toán Tiểu học"), add it to the frontmatter `author:` field. The JSON-LD schema picks it up.

## License

All posts are MIT-licensed and free to share. Cite HocVui when reposting.

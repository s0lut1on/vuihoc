# Pricing & Reminder Banner — Implementation Plan (2026 Q3)

Three features that round out the conversion funnel after Phase 0–5 of the SEO plan.

## Overview

| # | Feature | Effort | Why |
|---|---|---|---|
| A | Single source of truth for pricing | 4–6 h | Today the prices are hardcoded in `pricing_screen.dart` AND `marketing-site/src/pages/pricing.astro`. Drift inevitable. |
| B | EN version of pricing screen | 2–3 h | VI-only excludes the 30% of Vietnamese families who speak English at home. Already a 4-prong l10n system. |
| C | "Nhắc tôi sau" dismissible banner on home | 2–3 h | Today the daily limit triggers a hard `paywall_modal`. A soft banner converts better. |

**Total: ~10–12 hours.** Sequence: A → B → C (B depends on A; C is independent).

---

## Feature A — Single source of truth for pricing

**Goal**: One JSON file defines the pricing tiers. Both the Flutter app and the marketing site read from it at build time. Change prices once, ship once.

### Design

**File**: `math-app/pricing.json` at the repo root (so both `marketing-site/` and `frontend/` can read it as a relative path).

```json
{
  "version": 1,
  "currency": "VND",
  "tiers": [
    {
      "id": "free",
      "name_vi": "Miễn phí",
      "name_en": "Free",
      "price": 0,
      "price_period_vi": "/ mãi mãi",
      "price_period_en": "/ forever",
      "is_default": true,
      "features": [
        { "id": "lessons_50", "text_vi": "50 bài học mỗi ngày", "text_en": "50 lessons per day" },
        { "id": "personas", "text_vi": "Đầy đủ 4 phong cách học", "text_en": "All 4 learning personas" },
        { "id": "bilingual", "text_vi": "Song ngữ Việt–Anh", "text_en": "Bilingual Vietnamese–English" },
        { "id": "dashboard_basic", "text_vi": "Dashboard phụ huynh cơ bản", "text_en": "Basic parent dashboard" },
        { "id": "auth", "text_vi": "Google Sign-In + Guest", "text_en": "Google Sign-In + Guest" },
        { "id": "unlimited_time", "text_vi": "Không giới hạn thời gian", "text_en": "No time limit" }
      ]
    },
    {
      "id": "premium_monthly",
      "name_vi": "Premium",
      "name_en": "Premium",
      "price": 199000,
      "price_period_vi": "/ tháng",
      "price_period_en": "/ month",
      "features": [
        { "id": "unlimited_lessons", "text_vi": "Không giới hạn bài học mỗi ngày", "text_en": "Unlimited lessons per day" },
        { "id": "weekly_email", "text_vi": "Báo cáo tiến bộ hàng tuần qua email", "text_en": "Weekly progress reports via email" },
        { "id": "export_csv", "text_vi": "Xuất dữ liệu học tập (CSV)", "text_en": "Export learning data (CSV)" },
        { "id": "multi_child", "text_vi": "Nhiều hồ sơ bé trong 1 tài khoản", "text_en": "Multiple child profiles" },
        { "id": "priority_support", "text_vi": "Hỗ trợ ưu tiên 24/7", "text_en": "Priority 24/7 support" },
        { "id": "early_access", "text_vi": "Sớm nhận nội dung mới", "text_en": "Early access to new content" }
      ]
    },
    {
      "id": "premium_yearly",
      "name_vi": "Premium (năm)",
      "name_en": "Premium (yearly)",
      "price": 1990000,
      "price_period_vi": "/ năm",
      "price_period_en": "/ year",
      "compare_to_monthly": "save_17_percent",
      "features": "inherits_premium_monthly"
    }
  ],
  "compare_rows": [
    { "id": "lessons_per_day", "label_vi": "Bài học / ngày", "label_en": "Lessons / day", "free": "50", "premium": "Không giới hạn" }
    // ... etc
  ],
  "contact_email": "contact@sekklings.com"
}
```

### Files to add

- `math-app/pricing.json` — the source of truth

### Files to change

- `math-app/marketing-site/src/pages/pricing.astro` — read from `import pricing from '../../../pricing.json'`, render the same JSON structure
- `math-app/marketing-site/scripts/build-pricing.mjs` — optionally validate the JSON (price tiers sum, no missing fields, version is `1`)
- `math-app/frontend/lib/screens/pricing_screen.dart` — read JSON at build time via `rootBundle.loadString` and parse, or use a `const _kPricingJson = String.fromEnvironment(...)` + build script
- `math-app/frontend/lib/data/pricing.dart` — new file, wraps the parsed JSON with typed accessors (`getTiers(locale)`, `getCompareRows(locale)`, `getContactEmail()`)
- `math-app/frontend/pubspec.yaml` — add the `pricing.json` to assets list
- `math-app/Makefile` — extend `build-web` and `build-rust` to depend on `pricing.json` being valid (run a JSON check)
- `math-app/CHANGELOG.md` — entry under [Unreleased]

### Integration pattern (Flutter)

```dart
// lib/data/pricing.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class PricingConfig {
  static late Map<String, dynamic> _cache;
  static Future<void> load() async {
    final s = await rootBundle.loadString('assets/pricing.json');
    _cache = jsonDecode(s) as Map<String, dynamic>;
  }
  static List<Map<String, dynamic>> get tiers => (List<Map<String, dynamic>>)((_cache['tiers'] as List).cast<Map<String, dynamic>>());
  static String contactEmail() => _cache['contact_email'] as String;
  // ... typed accessors ...
}
```

Call `PricingConfig.load()` in `main()` before `runApp`.

### Versioning

When changing the JSON schema, bump `version` and add a `MIGRATION.md` entry. The build script refuses to build if `version` < the highest known version (forces explicit migration).

### Acceptance criteria

- [ ] Single `pricing.json` defines all pricing data
- [ ] Changing `pricing.json` + rebuilding both apps shows the new price in both
- [ ] `marketing-site/src/pages/pricing.astro` reads from JSON, no hardcoded prices
- [ ] Flutter pricing screen reads from `rootBundle`-loaded JSON
- [ ] Build script validates JSON against schema, fails on invalid
- [ ] `CHANGELOG.md` mentions the new file + migration path

### Effort

| Task | Hours |
|---|---:|
| Design JSON schema | 1 |
| Migrate marketing-site to read JSON | 1 |
| Migrate Flutter app to read JSON | 1.5 |
| Build validation + Makefile | 1 |
| Test + deploy | 1 |
| **Total** | **5.5** |

---

## Feature B — EN version of pricing screen

**Goal**: When the app's language is set to English, the pricing screen shows English. The l10n system is already in place — extract the hardcoded VI strings to keys.

### Design

The pricing screen currently uses hardcoded Vietnamese strings. Move them to `lib/l10n/app_vi.arb` and `app_en.arb`. Pricing screen uses `AppLocalizations.of(context)` instead of literals.

### Files to change

- `math-app/frontend/lib/l10n/app_vi.arb` — add ~30 new keys
- `math-app/frontend/lib/l10n/app_en.arb` — add English translations of same keys
- `math-app/frontend/lib/l10n/app_localizations*.dart` — auto-regenerated by `flutter gen-l10n`
- `math-app/frontend/lib/screens/pricing_screen.dart` — replace all hardcoded VI strings with `l10n?.X ?? 'fallback'`
- `math-app/frontend/lib/data/pricing.dart` — extend with `getTiers(locale)` that returns localized text from the JSON (already locale-aware from Feature A)

### Keys to add (sample)

```
pricingPageTitle = "Bảng giá" / "Pricing"
pricingPageSubtitle = "Học vui mỗi ngày..." / "Learn joyfully every day..."
pricingFree = "Miễn phí" / "Free"
pricingPremium = "Premium" / "Premium"
pricingYearly = "Premium (năm)" / "Premium (yearly)"
pricingCurrent = "Đang dùng" / "Current plan"
pricingPopular = "Phổ biến" / "Popular"
pricingUpgrade = "Nâng cấp ngay 🚀" / "Upgrade now 🚀"
pricingCompareTitle = "So sánh chi tiết" / "Detailed comparison"
pricingFooterNote = "Thanh toán online..." / "Online payment not yet integrated..."
pricingFreePerDay = "50 bài học mỗi ngày" / "50 lessons per day"
... (one per feature × 2 tiers = ~16 keys)
pricingCloseButton = "Đóng" / "Close"
```

### Acceptance criteria

- [ ] All hardcoded strings replaced with `l10n?.X ?? 'fallback'`
- [ ] Both `app_vi.arb` and `app_en.arb` updated with matching keys
- [ ] `flutter gen-l10n` runs clean, no missing keys
- [ ] In Vietnamese, screen looks identical to current
- [ ] In English, every string is natural English (not machine-translated)
- [ ] Feature flags (✓/—) work in both languages
- [ ] Decimals + currency format uses locale (199,000 ₫ vs 199K)
- [ ] FAQ schema in marketing site is also bilingual (already is)

### Effort

| Task | Hours |
|---|---:|
| Define l10n keys | 0.5 |
| Update both .arb files | 0.5 |
| Refactor pricing_screen.dart to use l10n | 1 |
| Verify both languages render correctly | 0.5 |
| Test + deploy | 0.5 |
| **Total** | **3** |

---

## Feature C — "Nhắc tôi sau" dismissible banner

**Goal**: When a kid hits the daily limit, show a non-blocking banner at the top of the home screen (above the existing content). The banner has two actions:
- "Nhắc tôi sau" — dismiss for 24 hours
- "Nâng cấp" — navigate to `/pricing`

This complements (does not replace) the existing `paywall_modal` which appears when the kid tries to *start* a lesson past the limit. The banner is proactive; the modal is reactive.

### Design

```
┌─────────────────────────────────────────────────┐
│ ⭐ Bạn đã học 50/50 bài hôm nay!                  │
│ Nâng cấp Premium để học không giới hạn.        │
│ [Nâng cấp]   [Nhắc tôi sau]                  ✕   │
└─────────────────────────────────────────────────┘
```

### Behavior

- **Show condition**: User is at daily limit AND not Premium AND not dismissed in last 24h
- **Dismiss**: tap "Nhắc tôi sau" or "✕" → set `pricing_banner_dismissed_at = now()` in `LocalStorageService`
- **Re-show**: 24h after dismiss, banner returns
- **Persistence**: `LocalStorageService` (already exists, see `lib/services/local_storage_service.dart`)
- **Never shows**: if user is Premium (`subscriptionTier == 'premium'`)

### Files to add

- `math-app/frontend/lib/widgets/pricing_banner.dart` — the banner widget

### Files to change

- `math-app/frontend/lib/screens/home_screen.dart` — read `isAtDailyLimit` (already exists in providers), add banner above the content if true
- `math-app/frontend/lib/services/local_storage_service.dart` — add `getPricingBannerDismissedAt()`, `setPricingBannerDismissedAt()`
- `math-app/frontend/lib/l10n/app_vi.arb` + `app_en.arb` — banner strings
- `math-app/frontend/lib/widgets/paywall_modal.dart` — minor copy: change "Để mai học tiếp" → "Quay lại trang chủ" (better UX, since the banner now provides the dismiss path)

### Storage shape

```dart
// in local_storage_service.dart
static const _kPricingBannerDismissedAt = 'pricing_banner_dismissed_at';
static Future<DateTime?> getPricingBannerDismissedAt() async { /* ... */ }
static Future<void> setPricingBannerDismissedAt(DateTime ts) async { /* ... */ }
```

### Banner visibility logic

```dart
final isAtLimit = ref.watch(isAtDailyLimitProvider);
final dismissedAt = await LocalStorageService.getPricingBannerDismissedAt();
final isPremium = (userAsync.valueOrNull?.subscriptionTier ?? 'free') == 'premium';
final showBanner = isAtLimit && !isPremium && (dismissedAt == null || DateTime.now().difference(dismissedAt) > Duration(hours: 24));
```

### Acceptance criteria

- [ ] Banner shows when kid hits daily limit
- [ ] Banner does NOT show for Premium users
- [ ] Tapping "Nhắc tôi sau" hides it for 24h
- [ ] Tapping "Nâng cấp" navigates to `/pricing`
- [ ] Tapping "✕" same as "Nhắc tôi sau"
- [ ] Dismissing persists across app restarts
- [ ] Dismiss timer uses device time (not server time)
- [ ] Banner is visually distinct from the existing `paywall_modal` (banner = soft, modal = blocking)
- [ ] Banner is fully translated (vi + en)

### Effort

| Task | Hours |
|---|---:|
| Banner widget | 1.5 |
| Storage helpers | 0.5 |
| Home screen integration + visibility logic | 0.5 |
| l10n strings | 0.3 |
| Test + deploy | 0.7 |
| **Total** | **3.5** |

---

## Dependencies

```
A (shared pricing JSON)
  ↓ feeds into
B (EN pricing screen)  ── independent ──→  C (dismissible banner)
```

A is a strict prerequisite for B (B reads from A's JSON). C is fully independent.

## Suggested calendar (1 person, focused)

| Day | Phase | Hours |
|---|---|---:|
| Day 1 | A: Design JSON + migrate marketing site | 2 |
| Day 1 | A: Migrate Flutter app + build validation | 3 |
| Day 2 | B: l10n keys + refactor pricing screen | 2 |
| Day 2 | B: Test + deploy both languages | 1 |
| Day 3 | C: Banner widget + home screen integration | 2 |
| Day 3 | C: Storage + l10n + test + deploy | 1.5 |

**Total: ~12 hours over 3 days**

## Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| JSON schema breaks existing builds | Low | Medium | Version field, build validation, fail-loud on unknown version |
| Marketing site renders wrong locale | Medium | Low | Test both vi/en on `npm run build` |
| Banner shows when user is Premium | Medium | Medium | Test all 3 conditions; explicit `subscriptionTier` check |
| Dismiss timer wrong (timezone / drift) | Low | Low | Use `DateTime.now()` (device time), 24h `Duration` comparison |
| Flutter `rootBundle` load fails at startup | Low | High | Catch exception, fall back to embedded default; show error toast |
| Pricing changes need a new build | Certain | Low | Document in `CHANGELOG.md`; both apps build on every push via CI |

## Open questions

1. **Yearly pricing**: keep as 2 separate tier objects (`premium_monthly` + `premium_yearly`) or unify into 1 tier with a `compare_to_monthly` field? Current spec uses 2 objects.
2. **Free tier daily limit**: hardcode 50 or move to JSON? If moving, also update `daily_limit.dart` to read from JSON.
3. **Banner position**: top of home screen (above stats cards) or bottom (above footer)? Top is more visible but takes scroll space.
4. **Banner dismissal timer**: 24h is spec default. Could be 12h (less aggressive) or 7d (more forgiving). 24h is the sweet spot.
5. **Should the banner also appear on `/subject` and `/lesson` screens?** The current spec only mentions home screen. If the user navigates away from home, the banner disappears.
6. **Should "Nâng cấp" go to `/pricing` (in-app) or `mailto:` (current behavior of paywall_modal)?** Recommend in-app — keep them in the funnel.
7. **Add a "Trial 7 days free" tier?** Could increase Premium conversions. Out of scope for this plan; revisit Q4.

## License

MIT

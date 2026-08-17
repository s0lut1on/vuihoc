# Pricing & Freemium

The app uses a simple free/premium tier model. Free users can complete up to 50 lessons per day; premium users have unlimited access.

## Files

- `math-app/frontend/lib/services/daily_limit.dart`
- `math-app/frontend/lib/widgets/pricing_banner.dart`
- `math-app/frontend/lib/widgets/paywall_modal.dart`
- `math-app/frontend/lib/screens/pricing_screen.dart`
- `math-app/frontend/lib/screens/lesson_screen.dart`
- `math-app/frontend/lib/data/pricing.dart`
- `math-app/pricing.json`

## Free Tier Cap

```dart
const int freeTierDailyLimit = 50;
```

- `shouldShowPaywall(count: _dailyCount, tier: _userTier)` returns `true` when `count >= 50` and tier is not `premium`.
- Unknown or missing tiers are treated as free to avoid silently bypassing the cap.

## Paywall

- Hard paywall: when a free user tries to start a new lesson after hitting the cap, `PaywallModal` blocks the action.
- Soft banner: `PricingBanner` appears on the home screen at the cap and links to `/pricing`.
- Banner can be dismissed for 24 hours.

## Pricing Screen

- Loads plans from `PricingConfig` (`data/pricing.dart` + synced `assets/pricing.json`).
- Shows plan cards and a call-to-action.
- Web checkout is handled by the `payment-service` (Stripe).

## Tier Source

- `currentUserTierProvider` reads `tier` from `/api/auth/me`.
- `dailyLimitProvider` reads `count` and `tier` from `/api/progress/daily-limit/:userId`.

## Backend

- `payment-service` handles Stripe checkout and webhooks.
- Admins can flip `subscription_tier` in the database.

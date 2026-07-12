import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../data/pricing.dart';
import '../l10n/app_localizations.dart';
import '../utils/url_launcher.dart';
import '../widgets/mascot.dart';

/// Bảng giá (Pricing) — Free vs Premium tier comparison.
///
/// Mirrors the marketing site at /pricing/ (Astro page). Data from
/// `assets/pricing.json` (synced from `math-app/pricing.json`). Chrome
/// (header, buttons, table labels, footer) uses l10n; tier + feature text
/// comes from per-locale JSON fields (`text_vi` / `text_en`).
class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pricing = PricingConfig.instance;
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    final free = pricing.tierById('free');
    final premium = pricing.tierById('premium_monthly');
    final yearly = pricing.tierById('premium_yearly');

    // Defensive: if the pricing JSON hasn't loaded yet (e.g. asset fetch
    // is slow on first paint, or the load() promise hasn't resolved),
    // show a loading state instead of crashing with a null-check error.
    // Previously this used `!` on each tier and threw "Null check operator
    // used on a null value" when the PricingConfig was still the empty
    // stub — which made the pricing screen render as just the top bar.
    if (free == null || premium == null || yearly == null) {
      return Scaffold(
        backgroundColor: AppColors.pinkBg,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, l10n),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.pink,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, l10n),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Cap content width on very wide viewports so the page
                  // reads like a marketing page, not a stretched kid screen.
                  final maxW =
                      constraints.maxWidth >= 1024 ? 1024.0 : double.infinity;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxW),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHero(l10n, isEn),
                              const SizedBox(height: 32),
                              _buildTierRow(
                                context,
                                l10n,
                                free,
                                premium,
                                yearly,
                                isEn: isEn,
                              ),
                              const SizedBox(height: 40),
                              _buildCompareTable(
                                context,
                                l10n,
                                pricing,
                                isEn: isEn,
                              ),
                              const SizedBox(height: 32),
                              _buildNoteBox(context, l10n),
                              const SizedBox(height: 24),
                              _buildBuildVersionFooter(l10n),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────
  // Minimal: just a back arrow + brand label, since the user came
  // here from the kid app's nav bar. No full KidNavBar (this is a
  // marketing-style page, not a kid screen).
  Widget _buildTopBar(BuildContext context, AppLocalizations? l10n) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.pinkSoft, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n?.pricingBackTooltip ?? 'Back',
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back, color: AppColors.deepPurple),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniMascot(size: 28),
              const SizedBox(width: 8),
              Text(
                l10n?.pricingBrandShort ?? 'HocVui',
                style: AppTheme.display(size: 18),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 48), // balance IconButton width
        ],
      ),
    );
  }

  // ── Hero ────────────────────────────────────────────────────────────
  // Marketing-site equivalent: gradient bg, plain title + subtitle.
  // No BigMascot, no kid-style icon.
  Widget _buildHero(AppLocalizations? l10n, bool isEn) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.pinkSoft, AppColors.pinkBg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        children: [
          Text(
            l10n?.pricingHeroTitle ?? (isEn ? 'Pricing' : 'Gói học'),
            style: AppTheme.display(size: 36),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.pricingHeroSubtitle ??
                (isEn
                    ? 'Free to start. Upgrade when you need more.'
                    : 'Bắt đầu miễn phí. Nâng cấp khi cần.'),
            textAlign: TextAlign.center,
            style: AppTheme.body(size: 16, color: AppColors.mutedPurple),
          ),
        ],
      ),
    );
  }

  // ── Tier row ────────────────────────────────────────────────────────
  // 3 columns on wide (≥ 768px), 1 column on narrow — matches the
  // marketing site `md:grid-cols-3` breakpoint (Tailwind's md = 768).
  // Uses MediaQuery as the source of truth (more reliable than
  // LayoutBuilder constraints inside a Column with stretch).
  Widget _buildTierRow(
    BuildContext context,
    AppLocalizations? l10n,
    Map<String, dynamic> free,
    Map<String, dynamic> premium,
    Map<String, dynamic> yearly, {
    required bool isEn,
  }) {
    final viewportW = MediaQuery.sizeOf(context).width;
    final wide = viewportW >= 768;
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildTierCard(context, l10n, free, isEn: isEn)),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTierCard(
              context,
              l10n,
              premium,
              isEn: isEn,
              popular: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _buildTierCard(context, l10n, yearly, isEn: isEn)),
        ],
      );
    }
    return Column(
      children: [
        _buildTierCard(context, l10n, free, isEn: isEn),
        const SizedBox(height: 16),
        _buildTierCard(context, l10n, premium, isEn: isEn, popular: true),
        const SizedBox(height: 16),
        _buildTierCard(context, l10n, yearly, isEn: isEn),
      ],
    );
  }

  Widget _buildTierCard(
    BuildContext context,
    AppLocalizations? l10n,
    Map<String, dynamic> tier, {
    required bool isEn,
    bool popular = false,
  }) {
    final pricing = PricingConfig.instance;
    final isYearly = (tier['id'] as String) == 'premium_yearly';
    final isFree = (tier['id'] as String) == 'free';

    final Color borderColor = popular ? AppColors.pink : AppColors.pinkSoft;
    final double borderWidth = popular ? 4 : 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4), // room for popular badge
          decoration: BoxDecoration(
            color: isYearly
                ? AppColors.cream
                : (popular ? null : AppColors.white),
            gradient: popular
                ? const LinearGradient(
                    // pinkSoft (not pinkBg) on the top-left so the
                    // card's outline stays visible against the page
                    // background — pinkBg is the same color as the
                    // page bg, which made the top-left edge invisible
                    // and made the popular card merge with the
                    // cream-colored yearly card.
                    colors: [AppColors.pinkSoft, AppColors.cream],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: popular
                ? const [
                    BoxShadow(
                      color: AppColors.pinkDark,
                      offset: Offset(0, 6),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pricing.tierName(tier, isEn).toUpperCase(),
                style: AppTheme.body(
                  size: 12,
                  color: AppColors.pinkDark,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isFree && !isEn
                        ? '0 đ'
                        : (isFree
                            ? '\$0'
                            : pricing.formatPrice(
                                tier['price'] as num,
                                en: isEn,
                              )),
                    style: AppTheme.display(size: 40),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      pricing.pricePeriod(tier, isEn),
                      style: AppTheme.body(
                        size: isEn ? 16 : 18,
                        color: AppColors.mutedPurple,
                      ),
                    ),
                  ),
                ],
              ),
              if (popular) ...[
                const SizedBox(height: 4),
                _buildYearlySubtitle(pricing, isEn),
              ],
              if (isYearly) ...[
                const SizedBox(height: 4),
                Text(
                  l10n?.pricingYearlySaveLine ??
                      (isEn
                          ? 'Save 17% vs monthly'
                          : 'Tiết kiệm 17% so với trả theo tháng'),
                  style: AppTheme.body(
                    size: 13,
                    color: AppColors.green,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ...((tier['features'] as List)
                  .cast<Map<String, dynamic>>()
                  .map((f) => _feature(pricing.featureText(f, isEn)))),
              const SizedBox(height: 20),
              _buildTierCta(context, l10n, tier, isEn),
              if (popular) ...[
                const SizedBox(height: 8),
                Text(
                  l10n?.pricingRefundLine ??
                      (isEn
                          ? 'Cancel anytime. 7-day refund.'
                          : 'Huỷ bất cứ lúc nào. Hoàn tiền trong 7 ngày.'),
                  textAlign: TextAlign.center,
                  style: AppTheme.body(
                    size: 11,
                    color: AppColors.mutedPurple,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (popular)
          Positioned(
            top: -10,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.pink,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n?.pricingPopularBadge ??
                    (isEn ? 'Popular' : 'Phổ biến'),
                style: AppTheme.body(
                  size: 11,
                  color: AppColors.white,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Subtitle under the monthly price: "1,99 triệu / năm (tiết kiệm 17%)"
  Widget _buildYearlySubtitle(PricingConfig pricing, bool isEn) {
    final yearly = pricing.tierById('premium_yearly');
    if (yearly == null) return const SizedBox.shrink();
    final price = pricing.formatPrice(yearly['price'] as num, en: isEn);
    if (isEn) {
      return Text(
        '$price/year (save 17%)',
        style: AppTheme.body(size: 13, color: AppColors.mutedPurple),
      );
    }
    return Text(
      '$price ${yearly['price_period_vi']} (tiết kiệm 17%)',
      style: AppTheme.body(size: 13, color: AppColors.mutedPurple),
    );
  }

  Widget _buildTierCta(
    BuildContext context,
    AppLocalizations? l10n,
    Map<String, dynamic> tier,
    bool isEn,
  ) {
    final id = tier['id'] as String;
    final pricing = PricingConfig.instance;

    String label;
    VoidCallback onTap;
    bool primary;

    if (id == 'free') {
      label = l10n?.pricingCtaStartFree ??
          (isEn ? 'Get started free' : 'Bắt đầu miễn phí');
      onTap = () => context.go('/home');
      primary = false; // white outlined
    } else if (id == 'premium_yearly') {
      label = l10n?.pricingCtaSave ??
          (isEn ? 'Save 17%' : 'Tiết kiệm ngay');
      onTap = () => _mailUpgrade(l10n, pricing, tier, isEn);
      primary = false; // white outlined
    } else {
      label = l10n?.pricingCtaUpgrade ??
          (isEn ? 'Upgrade now' : 'Nâng cấp ngay');
      onTap = () => _mailUpgrade(l10n, pricing, tier, isEn);
      primary = true; // solid pink
    }

    return _CtaButton(
      label: label,
      primary: primary,
      onTap: onTap,
    );
  }

  void _mailUpgrade(
    AppLocalizations? l10n,
    PricingConfig pricing,
    Map<String, dynamic> tier,
    bool isEn,
  ) {
    final tierName = pricing.tierName(tier, isEn);
    final subject = l10n?.pricingEmailSubject(tierName) ??
        'Upgrade HocVui $tierName';
    openExternalUrl(
      'mailto:${PricingConfig.instance.contactEmail}?subject=${Uri.encodeComponent(subject)}',
    );
  }

  // ── Compare table ───────────────────────────────────────────────────
  // Matches marketing site `<table>`: border-b rows, "Tính năng" / "Free"
  // / "Premium" headers, premium column bolded in pink-dark.
  Widget _buildCompareTable(
    BuildContext context,
    AppLocalizations? l10n,
    PricingConfig pricing, {
    required bool isEn,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.pinkSoft, width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n?.pricingCompareTitle ??
                (isEn ? 'Detailed comparison' : 'So sánh chi tiết'),
            textAlign: TextAlign.center,
            style: AppTheme.display(size: 20),
          ),
          const SizedBox(height: 16),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    l10n?.pricingCompareFeatureCol ??
                        (isEn ? 'Feature' : 'Tính năng'),
                    style: AppTheme.body(
                      size: 12,
                      color: AppColors.mutedPurple,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n?.pricingCompareFreeCol ?? 'Free',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(
                      size: 12,
                      color: AppColors.pinkDark,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n?.pricingComparePremiumCol ?? 'Premium',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(
                      size: 12,
                      color: AppColors.pinkDark,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 2, color: AppColors.pinkSoft),
          ...pricing.compareRows.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      isEn
                          ? (row['label_en'] as String)
                          : (row['label_vi'] as String),
                      style: AppTheme.body(
                        size: 13,
                        color: AppColors.deepPurple,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row['free'] as String,
                      textAlign: TextAlign.center,
                      style: AppTheme.body(
                        size: 12,
                        color: (row['free'] == '—')
                            ? AppColors.mutedText
                            : AppColors.deepPurple,
                        weight: (row['free'] == '✓')
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row['premium'] as String,
                      textAlign: TextAlign.center,
                      style: AppTheme.body(
                        size: 12,
                        color: AppColors.pinkDark,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Note box (matches marketing site "Lưu ý:" / "Note:" prefix) ────
  Widget _buildNoteBox(BuildContext context, AppLocalizations? l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pinkSoft, width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: l10n?.pricingNoteLabel ?? 'Lưu ý: ',
              style: AppTheme.body(
                size: 13,
                color: AppColors.deepPurple,
                weight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: l10n?.pricingNoteBody(PricingConfig.instance.contactEmail) ??
                  'Hiện tại thanh toán chưa tích hợp online. Nâng cấp Premium qua liên hệ: ${PricingConfig.instance.contactEmail}',
              style: AppTheme.body(
                size: 13,
                color: AppColors.mutedPurple,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBuildVersionFooter(AppLocalizations? l10n) {
    return Center(
      child: Text(
        l10n?.pricingFooterBrand ?? 'HocVui • Học vui mỗi ngày',
        style: AppTheme.body(size: 11, color: AppColors.mutedText),
      ),
    );
  }

  // Plain text "✓" checkmark, no circle background — matches marketing site.
  Widget _feature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1, right: 8),
            child: Text(
              '✓',
              style: TextStyle(
                color: AppColors.pinkDark,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTheme.body(
                size: 13,
                color: AppColors.deepPurple,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CTA button used inside tier cards.
/// Primary: solid pink w/ hard shadow. Secondary: white w/ pink border.
class _CtaButton extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _CtaButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? AppColors.pink : AppColors.white;
    final fg = primary ? AppColors.white : AppColors.pinkDark;
    final border =
        primary ? null : Border.all(color: AppColors.pink, width: 2);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: border,
            boxShadow: primary
                ? const [
                    BoxShadow(
                      color: AppColors.pinkDark,
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTheme.body(
              size: 14,
              color: fg,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

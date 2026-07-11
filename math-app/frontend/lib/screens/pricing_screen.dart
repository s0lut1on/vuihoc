import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../data/pricing.dart';
import '../providers/app_providers.dart';
import '../utils/url_launcher.dart';
import '../widgets/bubble_button.dart';
import '../widgets/kid_nav_bar.dart';
import '../widgets/mascot.dart';

/// Bảng giá (Pricing) — Free vs Premium tier comparison.
/// Data is read from `assets/pricing.json` (synced from `math-app/pricing.json`).
/// Strings are locale-aware: shows Vietnamese when the app locale is vi,
/// English when the locale is en. Hardcoded headers + buttons are VI-only
/// for now; Phase B moves them to the l10n system.
class PricingScreen extends ConsumerWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricing = PricingConfig.instance;
    final isEn = ref.watch(localeProvider).languageCode == 'en';

    final free = pricing.tierById('free')!;
    final premium = pricing.tierById('premium_monthly')!;
    final yearly = pricing.tierById('premium_yearly')!;

    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: SafeArea(
        child: Column(
          children: [
            KidNavBar(
              trailing: GestureDetector(
                onTap: () => context.go('/home'),
                child: const Icon(Icons.close,
                    color: AppColors.deepPurple, size: 24),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(isEn),
                    const SizedBox(height: 20),
                    _buildTierCard(context, free, isEn: isEn, currentBadge: true),
                    const SizedBox(height: 16),
                    _buildTierCard(context, premium, isEn: isEn, popular: true, currentBadge: false),
                    const SizedBox(height: 16),
                    _buildTierCard(context, yearly, isEn: isEn, currentBadge: false),
                    const SizedBox(height: 16),
                    _buildCompareTable(context, pricing, isEn: isEn),
                    const SizedBox(height: 24),
                    _buildUpgradeCta(context, isEn: isEn),
                    const SizedBox(height: 16),
                    _buildFooterNote(context, isEn: isEn),
                    const SizedBox(height: 16),
                    _buildBuildVersionFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEn) {
    return Column(
      children: [
        const BigMascot(size: 90, emoji: '⭐'),
        const SizedBox(height: 8),
        Text(
          isEn ? 'HocVui Pricing' : 'Bảng giá HocVui',
          style: AppTheme.display(size: 30),
        ),
        const SizedBox(height: 4),
        Text(
          isEn
              ? 'Learn joyfully every day — free or upgrade to Premium'
              : 'Học vui mỗi ngày, miễn phí hoặc nâng cấp Premium',
          textAlign: TextAlign.center,
          style: AppTheme.body(size: 14, color: AppColors.mutedPurple),
        ),
      ],
    );
  }

  Widget _buildTierCard(
    BuildContext context,
    Map<String, dynamic> tier, {
    required bool isEn,
    bool popular = false,
    bool currentBadge = false,
  }) {
    final pricing = PricingConfig.instance;
    final isPremium = (tier['id'] as String).startsWith('premium');
    final iconBg = isPremium ? AppColors.pink : AppColors.pinkSoft;
    final checkColor = isPremium ? AppColors.white : AppColors.pinkDark;

    return Container(
      decoration: BoxDecoration(
        color: popular ? null : AppColors.white,
        gradient: popular
            ? const LinearGradient(
                colors: [AppColors.pinkBg, Color(0xFFFFF8E1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: popular ? AppColors.pink : AppColors.pinkSoft, width: popular ? 3 : 2),
        boxShadow: popular
            ? const [
                BoxShadow(color: AppColors.pinkDark, offset: Offset(0, 6), blurRadius: 0),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  isPremium ? '👑' : '🎁',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              Text(pricing.tierName(tier, isEn), style: AppTheme.display(size: 22)),
              const Spacer(),
              if (currentBadge) _CurrentBadge(isEn: isEn),
              if (popular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.pink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isEn ? 'Popular' : 'Phổ biến',
                    style: AppTheme.body(
                        size: 12,
                        color: AppColors.white,
                        weight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(pricing.formatPrice(tier['price'] as num, en: isEn),
                  style: AppTheme.display(size: 40)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(pricing.pricePeriod(tier, isEn),
                    style: AppTheme.body(
                        size: isEn ? 16 : 18, color: AppColors.mutedPurple)),
              ),
            ],
          ),
          if (isPremium) ...[
            const SizedBox(height: 4),
            Text(
              isEn
                  ? 'or ${pricing.formatPrice(pricing.tierById('premium_yearly')!['price'] as num, en: true)}/year (save 17%)'
                  : 'hoặc ${pricing.formatPrice(pricing.tierById('premium_yearly')!['price'] as num, en: false)}/năm (tiết kiệm 17%)',
              style: AppTheme.body(size: 13, color: AppColors.pinkDark),
            ),
          ],
          const SizedBox(height: 14),
          ...((tier['features'] as List).cast<Map<String, dynamic>>().map((f) {
            return _feature(
              pricing.featureText(f, isEn),
              checkColor: checkColor,
            );
          })),
          if (!currentBadge) ...[
            const SizedBox(height: 18),
            BubbleButton(
              label: isEn
                  ? (popular
                      ? 'Upgrade now 🚀'
                      : (tier['id'] == 'premium_yearly' ? 'Save 17%' : 'Get started'))
                  : (popular
                      ? 'Nâng cấp ngay 🚀'
                      : (tier['id'] == 'premium_yearly' ? 'Tiết kiệm ngay' : 'Bắt đầu')),
              minWidth: double.infinity,
              height: 48,
              fontSize: 15,
              onPressed: () => openExternalUrl(
                  'mailto:${PricingConfig.instance.contactEmail}?subject=${isEn ? 'Upgrade' : 'Nâng cấp'} HocVui ${pricing.tierName(tier, isEn)}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompareTable(BuildContext context, PricingConfig pricing, {required bool isEn}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pinkSoft, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              isEn ? 'Detailed comparison' : 'So sánh chi tiết',
              style: AppTheme.display(size: 18),
            ),
          ),
          const SizedBox(height: 8),
          ...pricing.compareRows.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(isEn ? (row['label_en'] as String) : (row['label_vi'] as String),
                        style: AppTheme.body(size: 13, color: AppColors.deepPurple)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(row['free'] as String,
                        textAlign: TextAlign.center,
                        style: AppTheme.body(
                            size: 12,
                            color: (row['free'] == '—')
                                ? AppColors.mutedText
                                : AppColors.deepPurple,
                            weight: (row['free'] == '✓') ? FontWeight.w800 : FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(row['premium'] as String,
                        textAlign: TextAlign.center,
                        style: AppTheme.body(
                            size: 12, color: AppColors.pinkDark, weight: FontWeight.w800)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUpgradeCta(BuildContext context, {required bool isEn}) {
    return BubbleButton(
      label: isEn ? 'Upgrade now 🚀' : 'Nâng cấp ngay 🚀',
      minWidth: double.infinity,
      height: 56,
      fontSize: 17,
      onPressed: () => openExternalUrl(
          'mailto:${PricingConfig.instance.contactEmail}?subject=${isEn ? 'Upgrade' : 'Nâng cấp'} HocVui Premium'),
    );
  }

  Widget _buildFooterNote(BuildContext context, {required bool isEn}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orangeSoft, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEn
                  ? 'Online payment is not yet integrated. Need Premium? Email ${PricingConfig.instance.contactEmail} — admin activates within 24h.'
                  : 'Thanh toán online chưa tích hợp. Bé đang dùng gói Premium? Liên hệ ${PricingConfig.instance.contactEmail} — admin sẽ kích hoạt trong 24h.',
              style: AppTheme.body(size: 12, color: AppColors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildVersionFooter() {
    return Center(
      child: Text(
        'HocVui • Học vui mỗi ngày',
        style: AppTheme.body(size: 11, color: AppColors.mutedText),
      ),
    );
  }

  Widget _feature(String text, {required Color checkColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: checkColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.check, size: 14, color: AppColors.deepPurple),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTheme.body(size: 13, color: AppColors.deepPurple, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  final bool isEn;
  const _CurrentBadge({required this.isEn});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.successGreen, width: 1),
      ),
      child: Text(isEn ? 'Current plan' : 'Đang dùng',
          style: AppTheme.body(size: 12, color: AppColors.successGreen, weight: FontWeight.w800)),
    );
  }
}

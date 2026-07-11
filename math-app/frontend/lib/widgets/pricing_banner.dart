import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/daily_limit.dart';
import '../services/local_storage_service.dart';

/// "Nhắc tôi sau" dismissible banner — shown on the home screen when
/// the kid hits the daily limit. Soft (non-blocking) complement to the
/// hard `paywall_modal` that appears when starting a new lesson past
/// the limit. Dismissed via [LocalStorageService] for 24h.
class PricingBanner extends ConsumerStatefulWidget {
  const PricingBanner({super.key});

  @override
  ConsumerState<PricingBanner> createState() => _PricingBannerState();
}

class _PricingBannerState extends ConsumerState<PricingBanner> {
  bool _hidden = false;

  void _dismiss() {
    setState(() => _hidden = true);
    LocalStorageService.savePricingBannerDismissedAt(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final limitAsync = ref.watch(dailyLimitProvider);
    final dismissedAtAsync = ref.watch(_pricingBannerDismissedAtProvider);
    return limitAsync.when(
      data: (limit) {
        if (limit == null) return const SizedBox.shrink();
        final count = limit['count'] as int? ?? 0;
        final tier = limit['tier'] as String? ?? 'free';
        return dismissedAtAsync.when(
          data: (dismissedAt) {
            final show = shouldShowPricingBanner(
              dismissedAt: dismissedAt,
              now: DateTime.now(),
              count: count,
              tier: tier,
            );
            if (!show) return const SizedBox.shrink();
            return _buildCard(l10n);
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFE0EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pink, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), offset: Offset(0, 4), blurRadius: 12),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.pricingBannerTitle,
                    style: AppTheme.body(size: 14, color: AppColors.deepPurple, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(l10n.pricingBannerBody,
                    style: AppTheme.body(size: 12, color: AppColors.mutedPurple)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _PrimaryBtn(
                      label: l10n.pricingBannerCta,
                      onPressed: () => context.push('/pricing'),
                    ),
                    const SizedBox(width: 8),
                    _SecondaryBtn(
                      label: l10n.pricingBannerRemindLater,
                      onPressed: _dismiss,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _dismiss,
            icon: const Icon(Icons.close, color: AppColors.mutedPurple, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

/// FutureProvider for the dismiss timestamp. Wraps [LocalStorageService]
/// so widgets can watch it via Riverpod. Returns null = never dismissed.
final _pricingBannerDismissedAtProvider = FutureProvider<DateTime?>((ref) {
  return LocalStorageService.getPricingBannerDismissedAt();
});

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryBtn({required this.label, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.pink,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(0, 32),
        textStyle: AppTheme.body(size: 12, weight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Text(label),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _SecondaryBtn({required this.label, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.deepPurple,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        textStyle: AppTheme.body(size: 12, weight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

/// Visibility helper — banner should be shown if:
///   - user is at daily limit (>= [freeTierDailyLimit] for non-premium)
///   - last dismiss was > 24h ago (or never)
bool shouldShowPricingBanner({
  required DateTime? dismissedAt,
  required DateTime now,
  required int count,
  required String tier,
}) {
  if (tier == 'premium') return false;
  if (count < freeTierDailyLimit) return false;
  if (dismissedAt == null) return true;
  return now.difference(dismissedAt) > const Duration(hours: 24);
}

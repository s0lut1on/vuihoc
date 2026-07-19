import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../utils/url_launcher.dart';
import 'bubble_button.dart';
import 'mascot.dart';

class PaywallModal extends StatelessWidget {
  final VoidCallback onClose;
  const PaywallModal({super.key, required this.onClose});

  void _upgrade(context) async {
    try {
      final resp = await ApiService().post('/payments/create-checkout', data: {
        'price_id': 'premium_monthly',
        'success_url': '${Uri.base.origin}/home',
        'cancel_url': '${Uri.base.origin}/home',
      });
      final url = resp['data']?['url'] as String?;
      if (url != null && url.isNotEmpty) {
        openExternalUrl(url);
      }
    } catch (e) {
      debugPrint('Checkout failed: $e');
    }
    onClose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: AppColors.pinkBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BigMascot(size: 90, emoji: '⭐'),
            const SizedBox(height: 16),
            Text(
              l10n?.paywallTitle ?? "Hôm nay bé học giỏi quá! 🌟",
              textAlign: TextAlign.center,
              style: AppTheme.display(size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.paywallBody ??
                  'Mỗi ngày bé học được 50 bài miễn phí. Nâng cấp Premium để học không giới hạn!',
              textAlign: TextAlign.center,
              style: AppTheme.body(size: 14, color: AppColors.mutedPurple),
            ),
            const SizedBox(height: 24),
            BubbleButton(
              label: l10n?.paywallGotIt ?? 'Nâng cấp ngay 🚀',
              minWidth: 220,
              height: 52,
              fontSize: 16,
              onPressed: () => _upgrade(context),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onClose,
              child: Text(
                l10n?.paywallClose ?? 'Để mai học tiếp',
                style: AppTheme.body(size: 14, color: AppColors.mutedPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

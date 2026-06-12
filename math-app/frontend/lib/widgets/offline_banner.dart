import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      content: Text(
        l10n.offlineBanner ?? 'You are offline. Changes will sync later.',
        style: const TextStyle(fontSize: 13, color: AppColors.white),
      ),
      backgroundColor: Colors.orange.shade700,
      leading: const Icon(Icons.wifi_off, color: AppColors.white, size: 20),
      actions: const [SizedBox.shrink()],
    );
  }
}

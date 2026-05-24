import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';

class PaywallModal extends StatelessWidget {
  final VoidCallback onClose;

  const PaywallModal({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              l10n?.paywallTitle ?? "You've reached today's limit",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.darkPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.paywallBody ??
                  'Free accounts can study up to 50 lessons per day. Upgrade to study unlimited.',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onClose,
              child: Text(l10n?.paywallGotIt ?? 'Got it'),
            ),
            TextButton(
              onPressed: onClose,
              child: Text(
                l10n?.paywallClose ?? 'Close',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/locale_service.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          onPressed: () {
            ref.read(localeProvider.notifier).state = const Locale('vi', 'VN');
            saveLocale('vi');
          },
          child: const Text('🇻🇳'),
        ),
        const SizedBox(width: 8),
        TextButton(
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          onPressed: () {
            ref.read(localeProvider.notifier).state = const Locale('en', 'GB');
            saveLocale('en');
          },
          child: const Text('🇬🇧'),
        ),
        const SizedBox(width: 8),
        Text(
          AppLocalizations.of(context)!.languageSwitcherLabel,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/locale_service.dart';
import '../core/app_colors.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isVietnamese = currentLocale.languageCode == 'vi';
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      return _DesktopSwitcher(
        isVietnamese: isVietnamese,
        onSelectVi: () {
          ref.read(localeProvider.notifier).state = const Locale('vi', 'VN');
          saveLocale('vi');
        },
        onSelectEn: () {
          ref.read(localeProvider.notifier).state = const Locale('en', 'GB');
          saveLocale('en');
        },
      );
    }

    return _MobileButton(
      isVietnamese: isVietnamese,
      onTap: () => _showLanguageSheet(context, ref),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.parentDashboardLanguage,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkPurple,
                  ),
                ),
                const SizedBox(height: 24),
                _LanguageOption(
                  flag: '🇻🇳',
                  label: 'Tiếng Việt',
                  isSelected: ref.read(localeProvider).languageCode == 'vi',
                  onTap: () {
                    ref.read(localeProvider.notifier).state =
                        const Locale('vi', 'VN');
                    saveLocale('vi');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 12),
                _LanguageOption(
                  flag: '🇬🇧',
                  label: 'English',
                  isSelected: ref.read(localeProvider).languageCode == 'en',
                  onTap: () {
                    ref.read(localeProvider.notifier).state =
                        const Locale('en', 'GB');
                    saveLocale('en');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DesktopSwitcher extends StatelessWidget {
  final bool isVietnamese;
  final VoidCallback onSelectVi;
  final VoidCallback onSelectEn;

  const _DesktopSwitcher({
    required this.isVietnamese,
    required this.onSelectVi,
    required this.onSelectEn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageChip(
            flag: '🇻🇳',
            label: 'Tiếng Việt',
            isSelected: isVietnamese,
            onTap: onSelectVi,
          ),
          Container(
            width: 1,
            height: 20,
            color: AppColors.divider,
          ),
          _LanguageChip(
            flag: '🇬🇧',
            label: 'English',
            isSelected: !isVietnamese,
            onTap: onSelectEn,
          ),
        ],
      ),
    );
  }
}

class _MobileButton extends StatelessWidget {
  final bool isVietnamese;
  final VoidCallback onTap;

  const _MobileButton({
    required this.isVietnamese,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          isVietnamese ? '🇻🇳' : '🇬🇧',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPink.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryPink : AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPink.withValues(alpha: 0.08)
              : AppColors.grayBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.darkPurple,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primaryPink, size: 24),
          ],
        ),
      ),
    );
  }
}

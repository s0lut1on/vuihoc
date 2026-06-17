import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';

/// Rounded language switcher pill. Vietnamese / English toggle.
class KidLangSwitcher extends StatelessWidget {
  final bool isVietnamese;
  final ValueChanged<bool> onChanged;
  const KidLangSwitcher({super.key, required this.isVietnamese, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip('🇻🇳', 'Tiếng Việt', isVietnamese, () => onChanged(true)),
          Container(width: 1, height: 20, color: AppColors.divider),
          _chip('🇬🇧', 'English', !isVietnamese, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _chip(String flag, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.pink.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(label, style: AppTheme.body(
              size: 12, weight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? AppColors.pink : AppColors.mutedText,
            )),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import 'mascot.dart';

/// Top navigation bar. Optional active label, optional avatar slot on right.
class KidNavBar extends StatelessWidget {
  final String activeLabel;
  final Widget? trailing;
  const KidNavBar({super.key, this.activeLabel = '', this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.pinkSoft, width: 4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniMascot(size: 44),
              const SizedBox(width: 10),
              Text('Học Vui', style: AppTheme.display(size: 22)),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navLink('Chủ đề', activeLabel == 'Chủ đề'),
              _navLink('Bảng giá', activeLabel == 'Bảng giá'),
              _navLink('Liên hệ', activeLabel == 'Liên hệ'),
            ],
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _navLink(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        label,
        style: AppTheme.body(
          size: 14,
          weight: active ? FontWeight.w800 : FontWeight.w700,
          color: AppColors.deepPurple,
        ),
      ),
    );
  }
}

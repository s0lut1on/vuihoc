import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';

/// Compact flame-with-count pill used in nav bars. Tappable — usually links
/// to the streak/achievement view.
///
/// Pure presentation: pass the count; widget decides colors. When count is 0
/// the pill renders dimmed so we don't tease kids with a literal "0 days".
class StreakBadge extends StatelessWidget {
  final int days;
  final VoidCallback? onTap;
  const StreakBadge({super.key, required this.days, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dim = days <= 0;
    final bg = dim ? AppColors.grayBg : AppColors.orangeSoft;
    final border = dim ? AppColors.divider : AppColors.orange;
    final fg = dim ? AppColors.mutedText : AppColors.orangeText;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 2),
          boxShadow: dim
              ? null
              : const [
                  BoxShadow(
                      color: AppColors.orange,
                      offset: Offset(0, 2),
                      blurRadius: 0),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔥',
                style: TextStyle(
                    fontSize: 16, color: dim ? AppColors.mutedText : null)),
            const SizedBox(width: 4),
            Text('$days',
                style: AppTheme.display(
                    size: 14, color: fg, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

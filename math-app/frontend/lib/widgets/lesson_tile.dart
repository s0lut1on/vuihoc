import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';

/// Lesson row: status icon + title + meta. States: done, current, locked.
class LessonTile extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final LessonState state;
  final VoidCallback? onTap;
  const LessonTile({
    super.key,
    required this.id,
    required this.title,
    this.subtitle = '',
    this.state = LessonState.locked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, border;
    Color textColor = AppColors.deepPurple;
    String icon;
    switch (state) {
      case LessonState.done:
        bg = AppColors.greenSoft; border = AppColors.mint;
        textColor = AppColors.green; icon = '✅'; break;
      case LessonState.current:
        bg = AppColors.pinkSoft; border = AppColors.pink;
        icon = '▶'; break;
      case LessonState.locked:
        bg = AppColors.grayBg; border = AppColors.divider;
        textColor = const Color(0xFF9CA3AF); icon = '🔒'; break;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: state == LessonState.current ? 3 : 2),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.display(size: 16, color: textColor)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTheme.body(size: 12, color: AppColors.mutedPurple)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum LessonState { done, current, locked }

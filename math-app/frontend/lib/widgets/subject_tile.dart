import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import 'kid_card.dart';

/// Subject tile: big emoji + name + lesson count. Used in Home grid.
class SubjectTile extends StatelessWidget {
  final String id;
  final String emoji;
  final String nameVi;
  final String nameEn;
  final int lessonCount;
  final VoidCallback? onTap;
  final bool locked;
  const SubjectTile({
    super.key,
    required this.id,
    required this.emoji,
    required this.nameVi,
    required this.nameEn,
    required this.lessonCount,
    this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return KidCard(
      padding: const EdgeInsets.all(20),
      color: locked ? AppColors.grayBg : AppColors.white,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(nameVi, style: AppTheme.display(
            size: 20, color: locked ? const Color(0xFF9CA3AF) : AppColors.deepPurple)),
          const SizedBox(height: 2),
          Text('$lessonCount bài',
              style: AppTheme.body(size: 13, color: AppColors.mutedPurple)),
        ],
      ),
    );
  }
}

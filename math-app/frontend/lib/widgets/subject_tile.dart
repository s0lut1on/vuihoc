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

  /// Minimum grade (inclusive) at which this subject is available.
  /// When the user's grade is below this, the tile renders as
  /// greyed-out with a "Lớp N+" badge so kids can see what's coming.
  final int gradeMin;
  const SubjectTile({
    super.key,
    required this.id,
    required this.emoji,
    required this.nameVi,
    required this.nameEn,
    required this.lessonCount,
    this.onTap,
    this.locked = false,
    this.gradeMin = 1,
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
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const Spacer(),
              if (locked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.pinkSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('Lớp $gradeMin+',
                      style: AppTheme.body(
                          size: 10,
                          color: AppColors.deepPurple,
                          weight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(nameVi,
              style: AppTheme.display(
                  size: 20,
                  color:
                      locked ? const Color(0xFF9CA3AF) : AppColors.deepPurple)),
          const SizedBox(height: 2),
          Text(locked ? 'Sắp ra mắt' : '$lessonCount bài',
              style: AppTheme.body(size: 13, color: AppColors.mutedPurple)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Cute pill-shaped progress bar with rounded "bubble" cap.
class KidProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;
  const KidProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.pink,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0.0, 1.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: pct,
        child: Container(
          decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [AppColors.pink, AppColors.orange]),
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

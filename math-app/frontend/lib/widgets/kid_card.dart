import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';

/// Big rounded white card with soft drop-shadow. The "kid card" building block.
class KidCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final List<Color>? gradient;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;
  const KidCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.gradient,
    this.radius = 24,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final box = BoxDecoration(
      color: color,
      gradient: gradient != null
          ? LinearGradient(
              colors: gradient!,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)
          : null,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
            color: AppColors.pinkSoft,
            offset: const Offset(0, 6),
            blurRadius: 0),
        BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.08),
            offset: const Offset(0, 8),
            blurRadius: 16),
      ],
    );
    Widget body = Container(padding: padding, decoration: box, child: child);
    if (onTap != null) {
      body = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: body,
      );
    }
    if (semanticLabel != null) {
      body = Semantics(label: semanticLabel, child: body);
    }
    return body;
  }
}

/// Stat tile: emoji + big number + label. Used in Home, Profile, Parent.
class StatTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color? valueColor;
  final List<Color>? gradient;
  const StatTile({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
    this.valueColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return KidCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      gradient: gradient,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTheme.display(
                  size: 36, color: valueColor ?? AppColors.pink)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTheme.body(size: 14, color: AppColors.mutedPurple)),
        ],
      ),
    );
  }
}

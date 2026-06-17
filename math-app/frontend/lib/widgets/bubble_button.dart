import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// A pill-shaped button with hard 3D shadow ("bubble") that depresses on tap.
class BubbleButton extends StatefulWidget {
  final String label;
  final String? emoji;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final double fontSize;
  final double minWidth;
  final double height;
  final bool primary; // pink solid vs white outlined
  final double elevation;

  const BubbleButton({
    super.key,
    required this.label,
    this.emoji,
    this.icon,
    this.onPressed,
    this.color = AppColors.pink,
    this.textColor = AppColors.white,
    this.fontSize = 18,
    this.minWidth = 160,
    this.height = 56,
    this.primary = true,
    this.elevation = 6,
  });

  /// Factory: outlined white variant (for secondary actions).
  const BubbleButton.secondary({
    super.key,
    required this.label,
    this.emoji,
    this.icon,
    this.onPressed,
    this.fontSize = 18,
    this.minWidth = 160,
    this.height = 56,
    this.elevation = 4,
  })  : color = AppColors.white,
        textColor = AppColors.deepPurple,
        primary = false;

  /// Factory: green "go" button.
  const BubbleButton.success({
    super.key,
    required this.label,
    this.emoji,
    this.icon,
    this.onPressed,
    this.fontSize = 18,
    this.minWidth = 160,
    this.height = 56,
    this.elevation = 6,
  })  : color = AppColors.green,
        textColor = AppColors.white,
        primary = true;

  @override
  State<BubbleButton> createState() => _BubbleButtonState();
}

class _BubbleButtonState extends State<BubbleButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final shadow = widget.elevation - (_down ? 4 : 0);
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          constraints: BoxConstraints(
              minWidth: widget.minWidth, minHeight: widget.height),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: widget.primary
                ? null
                : Border.all(color: AppColors.divider, width: 2),
            boxShadow: [
              BoxShadow(
                  color:
                      widget.primary ? AppColors.pinkDark : AppColors.divider,
                  offset: Offset(0, shadow),
                  blurRadius: 0),
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, 4),
                  blurRadius: 12),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.emoji != null) ...[
                Text(widget.emoji!,
                    style: TextStyle(fontSize: widget.fontSize + 4)),
                const SizedBox(width: 8),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon,
                    color: widget.textColor, size: widget.fontSize + 2),
                const SizedBox(width: 8),
              ],
              Text(widget.label,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w800,
                    color: widget.textColor,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

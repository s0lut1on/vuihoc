import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../utils/url_launcher.dart';
import 'mascot.dart';

/// Top navigation bar. Optional active label, optional avatar slot on right.
///
/// Layout:
///   [logo]                  [Chủ đề] [Bảng giá] [Liên hệ]              [trailing]
///
/// Pricing is a primary CTA pill (the conversion path), the other two are
/// quiet text links. Active state for the text links is a pink dot underline.
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
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      child: Row(
        children: [
          // Brand
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniMascot(size: 44),
              const SizedBox(width: 10),
              Text('Học Vui', style: AppTheme.display(size: 22)),
            ],
          ),
          const Spacer(),
          // Nav links
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _TextLink(
                label: 'Chủ đề',
                active: activeLabel == 'Chủ đề',
                onTap: () => context.go('/home'),
              ),
              const SizedBox(width: 4),
              // Pricing is the conversion CTA — primary pill
              _PrimaryCta(
                label: 'Bảng giá',
                active: activeLabel == 'Bảng giá',
                onTap: () => context.push('/pricing'),
              ),
              const SizedBox(width: 4),
              _TextLink(
                label: 'Liên hệ',
                active: activeLabel == 'Liên hệ',
                url: 'https://www.facebook.com/profile.php?id=100064784463812',
              ),
            ],
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Plain text link with a pink underline when active.
class _TextLink extends StatelessWidget {
  final String label;
  final bool active;
  final String? url;
  final VoidCallback? onTap;
  const _TextLink({required this.label, required this.active, this.url, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap ?? (url != null ? () => openExternalUrl(url!) : null),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.pinkSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTheme.body(
                  size: 15,
                  weight: active ? FontWeight.w800 : FontWeight.w700,
                  color: active ? AppColors.pinkDark : AppColors.deepPurple,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.pink,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary CTA pill — used for the conversion path ("Bảng giá" pricing).
/// 3D-style chunky shadow on rest, presses flat on tap. The "→" arrow
/// reinforces "go to the pricing screen".
class _PrimaryCta extends StatefulWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PrimaryCta({required this.label, required this.active, required this.onTap});

  @override
  State<_PrimaryCta> createState() => _PrimaryCtaState();
}

class _PrimaryCtaState extends State<_PrimaryCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final pressed = _pressed;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(top: pressed ? 4 : 0, bottom: pressed ? 0 : 4),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.pink, AppColors.pinkDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: pressed
                ? const []
                : const [
                    BoxShadow(color: AppColors.pinkDark, offset: Offset(0, 4), blurRadius: 0),
                    BoxShadow(color: Color(0x22000000), offset: Offset(0, 6), blurRadius: 8),
                  ],
            border: widget.active
                ? Border.all(color: AppColors.white, width: 2)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: AppTheme.body(
                  size: 15,
                  weight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Text('→', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

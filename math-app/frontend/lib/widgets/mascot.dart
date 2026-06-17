import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Big 3D-styled frog mascot circle. The face of Hoc Vui.
class BigMascot extends StatelessWidget {
  final double size;
  final String emoji;
  final bool wiggle;
  final bool float_;
  const BigMascot({
    super.key,
    this.size = 120,
    this.emoji = '🐸',
    this.wiggle = false,
    this.float_ = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFC1DA), AppColors.pink],
          stops: [0.3, 1.0],
        ),
        boxShadow: const [
          BoxShadow(color: AppColors.pinkDark, offset: Offset(0, 8), blurRadius: 0),
          BoxShadow(color: Color(0x33000000), offset: Offset(0, 4), blurRadius: 12),
        ],
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.55)),
    );
    if (wiggle) {
      child = _Wiggle(child: child);
    }
    if (float_) {
      child = _Float(child: child);
    }
    return child;
  }
}

class _Wiggle extends StatefulWidget {
  final Widget child;
  const _Wiggle({required this.child});
  @override
  State<_Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<_Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  @override
  void initState() {
    super.initState();
    _c.repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, w) => Transform.rotate(angle: (_c.value - 0.5) * 0.12, child: w),
      child: widget.child,
    );
  }
}

class _Float extends StatefulWidget {
  final Widget child;
  const _Float({required this.child});
  @override
  State<_Float> createState() => _FloatState();
}

class _FloatState extends State<_Float> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );
  @override
  void initState() {
    super.initState();
    _c.repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, w) => Transform.translate(
        offset: Offset(0, -10 * _c.value),
        child: w,
      ),
      child: widget.child,
    );
  }
}

/// Small inline mascot avatar (used in nav/profile chips).
class MiniMascot extends StatelessWidget {
  final double size;
  final String emoji;
  const MiniMascot({super.key, this.size = 40, this.emoji = '🐸'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.pink,
        boxShadow: const [BoxShadow(color: AppColors.pinkDark, offset: Offset(0, 3), blurRadius: 0)],
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.6)),
    );
  }
}

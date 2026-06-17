import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import 'mascot.dart';

/// Animation themes for sub-subject unlock celebration.
///
/// Each theme = an emoji "scene" + a base color. The overlay renders a
/// gently rotating/lifting version of the emoji as a low-cost stand-in for
/// Rive/Lottie assets (which we don't ship yet). Switching is data-driven via
/// the `theme` parameter so admins can pick per sub-subject in the future.
enum UnlockTheme {
  space('🚀', 'Vũ trụ', 'Space', AppColors.purple,
      [AppColors.purple, AppColors.sky]),
  jungle('🐒', 'Rừng xanh', 'Jungle', AppColors.gamerText,
      [AppColors.green, AppColors.cream]),
  ocean('🐠', 'Đại dương', 'Ocean', AppColors.deepPurple,
      [AppColors.sky, AppColors.pinkSoft]),
  castle('🏰', 'Lâu đài', 'Castle', AppColors.orangeText,
      [AppColors.orangeSoft, AppColors.cream]),
  farm('🚜', 'Trang trại', 'Farm', AppColors.gamerGreen,
      [AppColors.greenSoft, AppColors.cream]);

  final String emoji;
  final String labelVi;
  final String labelEn;
  final Color accent;
  final List<Color> gradient;
  const UnlockTheme(
      this.emoji, this.labelVi, this.labelEn, this.accent, this.gradient);
}

class UnlockAnimationOverlay extends StatefulWidget {
  final String titleVi;
  final String titleEn;
  final Color accentColor;
  final UnlockTheme theme;
  final VoidCallback onDismiss;

  const UnlockAnimationOverlay({
    super.key,
    required this.titleVi,
    required this.titleEn,
    required this.accentColor,
    this.theme = UnlockTheme.space,
    required this.onDismiss,
  });

  @override
  State<UnlockAnimationOverlay> createState() => _UnlockAnimationOverlayState();
}

class _UnlockAnimationOverlayState extends State<UnlockAnimationOverlay>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _bounce;
  late final AnimationController _spin;
  late final Animation<double> _bounceAnim;
  late final Animation<double> _spinAnim;
  late final List<_Sparkle> _sparkles;
  final _rand = math.Random();

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _confetti.play();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounceAnim = CurvedAnimation(parent: _bounce, curve: Curves.easeInOut);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
    _spinAnim = CurvedAnimation(parent: _spin, curve: Curves.linear);
    _sparkles = List.generate(8, (i) {
      final angle = i * (2 * math.pi / 8);
      return _Sparkle(
        angle: angle,
        radius: 80 + _rand.nextDouble() * 40,
        size: 4 + _rand.nextDouble() * 6,
        color: [
          AppColors.pink,
          AppColors.yellow,
          AppColors.purple,
          AppColors.green
        ][_rand.nextInt(4)],
      );
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _confetti.stop();
    _confetti.dispose();
    _bounce.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xCC2D1B4E), Color(0xCC1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Sparkle ring around the card
          Center(
            child: AnimatedBuilder(
              animation: _spinAnim,
              builder: (_, __) => SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: _sparkles.map((s) {
                    final dx =
                        math.cos(s.angle + _spinAnim.value * 2 * math.pi) *
                            s.radius;
                    final dy =
                        math.sin(s.angle + _spinAnim.value * 2 * math.pi) *
                            s.radius;
                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: Container(
                        width: s.size,
                        height: s.size,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: s.color.withValues(alpha: 0.6),
                                blurRadius: 8)
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _bounceAnim,
              builder: (_, child) => Transform.scale(
                scale: 0.95 + _bounceAnim.value * 0.10,
                child: child,
              ),
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: widget.theme.accent.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                    const BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 20,
                        offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.theme.emoji,
                        style: const TextStyle(fontSize: 88)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.theme.gradient[0],
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isVi ? widget.theme.labelVi : widget.theme.labelEn,
                        style: AppTheme.display(
                            size: 12, color: widget.theme.accent),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isVi ? 'Mở khóa rồi!' : 'Unlocked!',
                      style: AppTheme.display(
                          size: 30, color: widget.theme.accent),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isVi ? widget.titleVi : widget.titleEn,
                      textAlign: TextAlign.center,
                      style: AppTheme.display(size: 18),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isVi ? 'Chạm để tiếp tục 🚀' : 'Tap to continue 🚀',
                      style:
                          AppTheme.body(size: 12, color: AppColors.mutedPurple),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [
                widget.theme.accent,
                AppColors.pink,
                AppColors.green,
                AppColors.deepPurple,
                AppColors.orange,
                AppColors.yellow,
              ],
              numberOfParticles: 24,
              maxBlastForce: 18,
              minBlastForce: 6,
            ),
          ),
          // Bottom-right frog peek
          const Positioned(
            right: 16,
            bottom: 16,
            child: MiniMascot(size: 60),
          ),
        ],
      ),
    );
  }
}

class _Sparkle {
  final double angle;
  final double radius;
  final double size;
  final Color color;
  _Sparkle(
      {required this.angle,
      required this.radius,
      required this.size,
      required this.color});
}

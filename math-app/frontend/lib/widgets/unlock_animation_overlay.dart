import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';

class UnlockAnimationOverlay extends StatefulWidget {
  final String titleVi;
  final String titleEn;
  final Color accentColor;
  final VoidCallback onDismiss;

  const UnlockAnimationOverlay({
    super.key,
    required this.titleVi,
    required this.titleEn,
    required this.accentColor,
    required this.onDismiss,
  });

  @override
  State<UnlockAnimationOverlay> createState() => _UnlockAnimationOverlayState();
}

class _UnlockAnimationOverlayState extends State<UnlockAnimationOverlay> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _confetti.play();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _confetti.stop();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Stack(
        children: [
          Container(color: Colors.black54),
          Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withAlpha(50),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎉', style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    isVi ? 'Mở khóa!' : 'Unlocked!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: widget.accentColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isVi ? widget.titleVi : widget.titleEn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isVi
                        ? 'Chạm để tiếp tục'
                        : 'Tap to continue',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedPurple,
                    ),
                  ),
                ],
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
                widget.accentColor,
                AppColors.primaryPink,
                AppColors.successGreen,
                AppColors.darkPurple,
                Colors.orange,
                Colors.amber,
              ],
              numberOfParticles: 20,
              maxBlastForce: 15,
              minBlastForce: 5,
            ),
          ),
        ],
      ),
    );
  }
}

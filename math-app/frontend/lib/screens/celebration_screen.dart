import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/persona_model.dart';
import '../providers/app_providers.dart';
import '../services/content_api.dart';
import '../widgets/bubble_button.dart';
import '../widgets/kid_card.dart';
import '../widgets/mascot.dart';

class CelebrationScreen extends ConsumerStatefulWidget {
  final int stars;
  final String persona;
  final String? subjectId;
  final String? lessonId;

  const CelebrationScreen({
    super.key,
    required this.stars,
    required this.persona,
    this.subjectId,
    this.lessonId,
  });

  @override
  ConsumerState<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends ConsumerState<CelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final List<Offset> _confetti;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    _confetti = List.generate(40, (i) {
      final r = i * 1.7;
      return Offset(((r * 13) % 400) - 200, -((r * 17) % 600));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final persona = Persona.values.byName(widget.persona);
    final messages = _getMessages(l10n, persona);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(_confetti, _controller.value),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.pinkSoft,
                          offset: Offset(0, 3),
                          blurRadius: 0)
                    ],
                  ),
                  child: const Icon(Icons.close,
                      color: AppColors.deepPurple, size: 20),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const BigMascot(size: 140, float_: false),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: const Text('🎉',
                                  style: TextStyle(fontSize: 60)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(messages['title']!,
                        textAlign: TextAlign.center,
                        style: AppTheme.display(size: 40)),
                    const SizedBox(height: 8),
                    Text(messages['subtitle']!,
                        textAlign: TextAlign.center,
                        style: AppTheme.body(
                            size: 16, color: AppColors.mutedPurple)),
                    const SizedBox(height: 24),
                    _buildStars(),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                              color: AppColors.deepPurple,
                              offset: Offset(0, 4),
                              blurRadius: 0)
                        ],
                      ),
                      child: Text('+${widget.stars * 5} 💎',
                          style: AppTheme.display(
                              size: 18, color: AppColors.white)),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BubbleButton.success(
                          label: messages['next']!,
                          emoji: '🚀',
                          minWidth: 160,
                          fontSize: 16,
                          height: 52,
                          onPressed: _goNext,
                        ),
                        const SizedBox(width: 12),
                        BubbleButton.secondary(
                          label: messages['home']!,
                          emoji: '🏠',
                          minWidth: 140,
                          fontSize: 16,
                          height: 52,
                          onPressed: () => context.go('/home'),
                        ),
                      ],
                    ),
                    if (persona == Persona.gamer) ...[
                      const SizedBox(height: 16),
                      KidCard(
                        padding: const EdgeInsets.all(12),
                        color: AppColors.gamerBg,
                        child: Row(
                          children: [
                            const Text('🎮', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(l10n.celebrationGamerUnlock,
                                  style: AppTheme.body(
                                      size: 14,
                                      color: AppColors.gamerText,
                                      weight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isFilled = index < widget.stars;
        return ScaleTransition(
          scale: CurvedAnimation(
              parent: _controller,
              curve: Interval(index * 0.2, 1, curve: Curves.elasticOut)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(isFilled ? '⭐' : '☆',
                style: const TextStyle(
                    fontSize: 64,
                    color: Color(0xFFFFD93D),
                    shadows: [
                      Shadow(
                          color: AppColors.pinkDark,
                          offset: Offset(0, 4),
                          blurRadius: 0)
                    ])),
          ),
        );
      }),
    );
  }

  void _goNext() async {
    final nextRoute = await _resolveNextLesson();
    if (mounted) context.go(nextRoute ?? '/home');
  }

  Future<String?> _resolveNextLesson() async {
    if (widget.subjectId == null || widget.lessonId == null) return null;
    // Use the lightweight per-subject endpoint instead of fetching
    // the full curriculum (1,720 lessons, 808KB) just to find the
    // next sibling. ~5x faster, payload is just this subject's
    // 30-50 lesson summaries.
    final userGrade = ref.read(userProvider).value?.grade ?? 1;
    final subjectLessons = await ContentApi.getSubjectLessons(
        widget.subjectId!, userGrade)
      ..sort((a, b) => a.order.compareTo(b.order));
    final currentIndex =
        subjectLessons.indexWhere((l) => l.id == widget.lessonId);
    if (currentIndex == -1 || currentIndex >= subjectLessons.length - 1)
      return null;
    final next = subjectLessons[currentIndex + 1];
    if (widget.subjectId == 'vietnamese' || widget.subjectId == 'english') {
      return '/language-lesson/${widget.subjectId}/${next.id}';
    }
    return '/lesson/${widget.subjectId}/${next.id}';
  }

  Map<String, String> _getMessages(AppLocalizations l10n, Persona persona) {
    final baseMessages = {
      'achiever': {
        'title': l10n.celebrationAchieverTitle,
        'subtitle': l10n.celebrationAchieverSubtitle
      },
      'gamer': {
        'title': l10n.celebrationGamerTitle,
        'subtitle': l10n.celebrationGamerSubtitle
      },
      'struggler': {
        'title': l10n.celebrationStrugglerTitle,
        'subtitle': l10n.celebrationStrugglerSubtitle
      },
      'silent': {
        'title': l10n.celebrationSilentTitle,
        'subtitle': l10n.celebrationSilentSubtitle
      },
    };
    final personaMessages = baseMessages[persona.name]!;
    return {
      'title': personaMessages['title']!,
      'subtitle': personaMessages['subtitle']!,
      'next': l10n.celebrationNext,
      'home': l10n.celebrationHome,
    };
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<Offset> offsets;
  final double progress;
  _ConfettiPainter(this.offsets, this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final colors = [
      AppColors.pink,
      AppColors.yellow,
      AppColors.purple,
      AppColors.green,
      AppColors.orange,
      AppColors.skyBlue,
    ];
    for (var i = 0; i < offsets.length; i++) {
      final p = (progress + i * 0.013) % 1.0;
      final dx = center.dx + offsets[i].dx * (0.5 + p);
      final dy = center.dy + offsets[i].dy * p + 200 * p;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 1 - p);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p * 6.28);
      canvas.drawRect(const Rect.fromLTWH(-3, -6, 6, 12), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

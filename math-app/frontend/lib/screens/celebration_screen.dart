import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/persona_model.dart';
import '../providers/app_providers.dart';
import '../services/content_api.dart';
import '../widgets/language_switcher.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
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
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: const LanguageSwitcher(),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildStars(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      messages['title']!,
                      style: Theme.of(context).textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      messages['subtitle']!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🎉', style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 8),
                        Text(
                          '+${widget.stars * 5} 💎',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryPink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _goNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                          ),
                          child: Text(messages['next']!),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () => context.go('/home'),
                          child: Text(messages['home']!),
                        ),
                      ],
                    ),
                    if (persona == Persona.gamer) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.gamerGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.celebrationGamerUnlock,
                          style: TextStyle(
                            color: AppColors.gamerText,
                            fontWeight: FontWeight.w600,
                          ),
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

  void _goNext() async {
    final nextRoute = await _resolveNextLesson();
    if (mounted) {
      context.go(nextRoute ?? '/home');
    }
  }

  Future<String?> _resolveNextLesson() async {
    if (widget.subjectId == null || widget.lessonId == null) return null;
    final userGrade = ref.read(userProvider).value?.grade ?? 1;
    final lessons = await ContentApi.getCurriculum(grade: userGrade);
    final subjectLessons = lessons
        .where((l) => l.subjectId == widget.subjectId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final currentIndex =
        subjectLessons.indexWhere((l) => l.id == widget.lessonId);
    if (currentIndex == -1 || currentIndex >= subjectLessons.length - 1) {
      return null;
    }

    final next = subjectLessons[currentIndex + 1];
    if (widget.subjectId == 'vietnamese' || widget.subjectId == 'english') {
      return '/language-lesson/${widget.subjectId}/${next.id}';
    }
    return '/lesson/${widget.subjectId}/${next.id}';
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isFilled = index < widget.stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            isFilled ? Icons.star : Icons.star_border,
            size: 56,
            color: isFilled ? Colors.amber : AppColors.divider,
          ),
        );
      }),
    );
  }

  Map<String, String> _getMessages(AppLocalizations l10n, Persona persona) {
    final baseMessages = {
      'achiever': {
        'title': l10n.celebrationAchieverTitle,
        'subtitle': l10n.celebrationAchieverSubtitle,
      },
      'gamer': {
        'title': l10n.celebrationGamerTitle,
        'subtitle': l10n.celebrationGamerSubtitle,
      },
      'struggler': {
        'title': l10n.celebrationStrugglerTitle,
        'subtitle': l10n.celebrationStrugglerSubtitle,
      },
      'silent': {
        'title': l10n.celebrationSilentTitle,
        'subtitle': l10n.celebrationSilentSubtitle,
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

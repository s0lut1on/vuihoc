import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/language_api.dart';
import '../widgets/exercise_dispatcher.dart';
import '../widgets/language_switcher.dart';

class LanguageLessonScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String lessonId;

  const LanguageLessonScreen({
    super.key,
    required this.subjectId,
    required this.lessonId,
  });

  @override
  ConsumerState<LanguageLessonScreen> createState() =>
      _LanguageLessonScreenState();
}

class _LanguageLessonScreenState extends ConsumerState<LanguageLessonScreen> {
  int _currentExercise = 0;
  Map<String, dynamic>? _lesson;
  bool _loading = true;
  bool _showHint = false;
  int _correctAnswers = 0;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final lesson = await LanguageApi.getLesson(widget.lessonId);
      if (mounted) {
        setState(() {
          _lesson = lesson;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPink),
        ),
      );
    }

    if (_lesson == null || _lesson!['exercises'] == null) {
      return Scaffold(
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.lessonNotFound,
            style: const TextStyle(fontSize: 18, color: AppColors.primaryPink),
          ),
        ),
      );
    }

    final exercises = _lesson!['exercises'] as List<dynamic>;
    final currentExercise = exercises[_currentExercise] as Map<String, dynamic>;
    final totalExercises = exercises.length;

    return Scaffold(
      backgroundColor: AppColors.lightBlueBg,
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(currentExercise, totalExercises)
            : _buildMobileLayout(currentExercise, totalExercises),
      ),
    );
  }

  Widget _buildMobileLayout(
      Map<String, dynamic> currentExercise, int totalExercises) {
    final locale = ref.watch(localeProvider);
    final titleVi = _lesson!['title_vi'] as String? ?? '';
    final titleEn = _lesson!['title_en'] as String? ?? '';
    final title = locale.languageCode == 'en' ? titleEn : titleVi;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(totalExercises),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.topRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LanguageSwitcher(),
                IconButton(
                  icon: const Icon(Icons.close, size: 24),
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ExerciseDispatcher(
              exercise: currentExercise,
              onAnswered: _onAnswered,
            ),
          ),
          const SizedBox(height: 16),
          if (_showHint)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locale.languageCode == 'en'
                          ? currentExercise['hint_en'] as String? ?? ''
                          : currentExercise['hint_vi'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
      Map<String, dynamic> currentExercise, int totalExercises) {
    final locale = ref.watch(localeProvider);
    final titleVi = _lesson!['title_vi'] as String? ?? '';
    final titleEn = _lesson!['title_en'] as String? ?? '';
    final title = locale.languageCode == 'en' ? titleEn : titleVi;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Column(
        children: [
          _buildDesktopNav(totalExercises),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.darkPurple,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.only(right: 48),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: ExerciseDispatcher(
                      exercise: currentExercise,
                      onAnswered: _onAnswered,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (_showHint)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  locale.languageCode == 'en'
                                      ? currentExercise['hint_en'] as String? ??
                                          ''
                                      : currentExercise['hint_vi'] as String? ??
                                          '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primaryPink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNav(int totalExercises) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('🐸', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)?.appTitle ?? 'Math Learning Fun',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
        Row(
          children: List.generate(totalExercises, (index) {
            final isFilled = index <= _currentExercise;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isFilled ? AppColors.successGreen : AppColors.divider,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 24, color: AppColors.darkText),
          onPressed: () => context.go('/home'),
        ),
        const LanguageSwitcher(),
      ],
    );
  }

  Widget _buildProgressBar(int total) {
    return Row(
      children: List.generate(total, (index) {
        final isFilled = index <= _currentExercise;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            decoration: BoxDecoration(
              color: isFilled ? AppColors.successGreen : AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  void _onAnswered(bool isCorrect) {
    if (isCorrect) {
      HapticFeedback.lightImpact();
      setState(() {
        _correctAnswers++;
      });

      // Advance to next exercise or finish lesson
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _advanceExercise();
        }
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _showHint = true;
      });

      // Hide hint after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showHint = false;
          });
        }
      });
    }
  }

  void _advanceExercise() {
    final exercises = _lesson!['exercises'] as List<dynamic>;
    if (_currentExercise < exercises.length - 1) {
      setState(() {
        _currentExercise++;
        _showHint = false;
      });
    } else {
      _finishLesson();
    }
  }

  void _finishLesson() async {
    final userId = ref.read(userIdProvider);
    if (userId == null || userId.isEmpty) return;

    // Calculate stars based on correct answers
    final totalExercises = (_lesson!['exercises'] as List<dynamic>).length;
    final accuracy = totalExercises > 0 ? _correctAnswers / totalExercises : 0;
    int stars = 1;
    if (accuracy >= 0.9) {
      stars = 3;
    } else if (accuracy >= 0.7) {
      stars = 2;
    }

    try {
      await LanguageApi.updateProgress(
        userId: userId,
        lessonId: widget.lessonId,
        stars: stars,
        completed: true,
      );

      if (mounted) {
        context.go('/celebration', extra: {
          'stars': stars,
          'subjectId': widget.subjectId,
          'lessonId': widget.lessonId,
        });
      }
    } catch (e) {
      // Fallback navigation even if API call fails
      if (mounted) {
        context.go('/celebration', extra: {
          'stars': stars,
          'subjectId': widget.subjectId,
          'lessonId': widget.lessonId,
        });
      }
    }
  }
}

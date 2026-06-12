import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/language_api.dart';
import '../services/progress_api.dart';
import '../services/tts_service.dart';
import '../widgets/exercise_dispatcher.dart';
import '../widgets/language_switcher.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _reviewMeta = []; // {exercise_id, lesson_id, wrong_count}
  int _currentIndex = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviewSession();
  }

  Future<void> _loadReviewSession() async {
    final userId = ref.read(userIdProvider) ?? '';
    if (userId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }

    try {
      // 1. Fetch review session from progress-service
      final session = await ProgressApi.getReviewSession(userId);
      if (session.isEmpty) {
        setState(() {
          _exercises = [];
          _reviewMeta = [];
          _loading = false;
        });
        return;
      }

      // 2. For each review entry, fetch the full exercise from language-service
      final loaded = <Map<String, dynamic>>[];
      final meta = <Map<String, dynamic>>[];

      for (final entry in session) {
        final exerciseId = entry['exercise_id'] as String? ?? '';
        final lessonId = entry['lesson_id'] as String? ?? '';
        final wrongCount = entry['wrong_count'] as int? ?? 0;

        final lesson = await LanguageApi.getLesson(lessonId);
        if (lesson == null || lesson['exercises'] == null) continue;

        final exercises = lesson['exercises'] as List<dynamic>;
        final exercise = exercises.firstWhere(
          (e) => (e as Map<String, dynamic>)['id'] == exerciseId,
          orElse: () => null,
        );

        if (exercise != null) {
          loaded.add(exercise as Map<String, dynamic>);
          meta.add({
            'exercise_id': exerciseId,
            'lesson_id': lessonId,
            'wrong_count': wrongCount,
          });
        }
      }

      if (mounted) {
        setState(() {
          _exercises = loaded;
          _reviewMeta = meta;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPink),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_exercises.isEmpty) {
      return _buildEmptyState(context);
    }

    final currentExercise = _exercises[_currentIndex];
    final currentMeta = _reviewMeta[_currentIndex];
    final total = _exercises.length;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBlueBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressBar(total),
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
                AppLocalizations.of(context)!.reviewScreenTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!
                    .reviewWrongCount(currentMeta['wrong_count'] ?? 0),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlueBg,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkPurple),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          AppLocalizations.of(context)!.reviewScreenTitle,
          style: const TextStyle(
            color: AppColors.darkPurple,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.reviewAllClear,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.darkPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int total) {
    return Row(
      children: List.generate(total, (index) {
        final isFilled = index <= _currentIndex;
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

  void _onAnswered(bool isCorrect, {String? userAnswer}) {
    final userId = ref.read(userIdProvider) ?? '';
    final currentMeta = _reviewMeta[_currentIndex];
    final exerciseId = currentMeta['exercise_id'] as String;
    final lessonId = currentMeta['lesson_id'] as String;

    // Submit to progress-service for spaced-repetition tracking
    if (userId.isNotEmpty) {
      ProgressApi.submitExerciseResult(
        userId: userId,
        exerciseId: exerciseId,
        lessonId: lessonId,
        isCorrect: isCorrect,
      );
    }

    if (isCorrect) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        if (_currentIndex < _exercises.length - 1) {
          setState(() => _currentIndex++);
        } else {
          // All done — go home
          context.go('/home');
        }
      });
    } else {
      // Wrong — stay on same question, user can retry
      // ExerciseDispatcher auto-resets after delay for MCQ
      // For other types, they handle their own retry
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/language_api.dart';
import '../services/progress_api.dart';
import '../widgets/exercise_dispatcher.dart';
import '../widgets/kid_card.dart';
import '../widgets/kid_progress_bar.dart';
import '../widgets/mascot.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _reviewMeta = [];
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
      final session = await ProgressApi.getReviewSession(userId);
      if (session.isEmpty) {
        setState(() {
          _exercises = [];
          _reviewMeta = [];
          _loading = false;
        });
        return;
      }

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
            'wrong_count': wrongCount
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
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.pinkBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.pink)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.pinkBg,
        body: Center(
            child: Text('Error: $_error',
                style: const TextStyle(color: AppColors.red))),
      );
    }
    if (_exercises.isEmpty) return _buildEmptyState(context);

    final currentExercise = _exercises[_currentIndex];
    final currentMeta = _reviewMeta[_currentIndex];
    final total = _exercises.length;

    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, currentMeta['wrong_count'] ?? 0, total),
              const SizedBox(height: 12),
              KidProgressBar(
                  value: (_currentIndex + 1) / total,
                  color: AppColors.purple,
                  height: 12),
              const SizedBox(height: 16),
              Expanded(
                child: ExerciseDispatcher(
                    exercise: currentExercise, onAnswered: _onAnswered),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int wrongCount, int total) {
    final l10n = AppLocalizations.of(context)!;
    return KidCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      gradient: const [AppColors.pinkSoft, AppColors.cream],
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Container(
              width: 40,
              height: 40,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.reviewScreenTitle, style: AppTheme.display(size: 18)),
                Text('Sai ${wrongCount} lần — cùng luyện lại nha!',
                    style:
                        AppTheme.body(size: 12, color: AppColors.mutedPurple)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999)),
            child: Text('${_currentIndex + 1}/$total',
                style: AppTheme.display(size: 14, color: AppColors.pink)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BigMascot(size: 140, emoji: '🎉', float_: true),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.reviewAllClear,
                  textAlign: TextAlign.center,
                  style: AppTheme.display(size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bé làm tốt lắm! Hẹn gặp lại ở bài sau nhé 💖',
                  textAlign: TextAlign.center,
                  style: AppTheme.body(size: 16, color: AppColors.mutedPurple),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.pink,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.pinkDark,
                            offset: Offset(0, 4),
                            blurRadius: 0)
                      ],
                    ),
                    child: Text('Về nhà 🏠',
                        style:
                            AppTheme.display(size: 16, color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onAnswered(bool isCorrect, {String? userAnswer}) {
    final userId = ref.read(userIdProvider) ?? '';
    final currentMeta = _reviewMeta[_currentIndex];
    final exerciseId = currentMeta['exercise_id'] as String;
    final lessonId = currentMeta['lesson_id'] as String;

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
          context.go('/home');
        }
      });
    }
  }
}

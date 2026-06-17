import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/language_api.dart';
import '../services/progress_api.dart';
import '../services/question_bank_api.dart';
import '../services/connectivity_service.dart';
import '../services/tts_service.dart';
import '../widgets/exercise_dispatcher.dart';
import '../widgets/kid_card.dart';
import '../widgets/kid_progress_bar.dart';
import '../widgets/mascot.dart';
import '../widgets/offline_banner.dart';

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
  int _wrongCountThisExercise = 0;
  String _hintText = '';
  final List<String> _answerHistory = [];
  final Stream<bool> _connectivityStream =
      ConnectivityService().onConnectivityChanged;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final lesson = await LanguageApi.getLesson(widget.lessonId);
      if (mounted)
        setState(() {
          _lesson = lesson;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.pinkBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.pink)),
      );
    }
    if (_lesson == null || _lesson!['exercises'] == null) {
      return Scaffold(
        backgroundColor: AppColors.pinkBg,
        body: Center(
          child: Text(AppLocalizations.of(context)!.lessonNotFound,
              style: AppTheme.display(size: 20, color: AppColors.mutedPurple)),
        ),
      );
    }

    final exercises = _lesson!['exercises'] as List<dynamic>;
    final currentExercise = exercises[_currentExercise] as Map<String, dynamic>;
    final totalExercises = exercises.length;

    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: Column(
        children: [
          StreamBuilder<bool>(
            stream: _connectivityStream,
            initialData: true,
            builder: (context, snapshot) => snapshot.data == false
                ? const OfflineBanner()
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: SafeArea(
              child: isDesktop
                  ? _buildDesktopLayout(currentExercise, totalExercises)
                  : _buildMobileLayout(currentExercise, totalExercises),
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(totalExercises),
          const SizedBox(height: 12),
          KidProgressBar(
            value: (_currentExercise + 1) / totalExercises,
            color: AppColors.purple,
            height: 12,
          ),
          const SizedBox(height: 12),
          KidCard(
            gradient: const [AppColors.pinkSoft, AppColors.cream],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text('📚', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: AppTheme.display(size: 18))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_showHint) _buildHintBanner(currentExercise, locale.languageCode),
          const SizedBox(height: 12),
          Expanded(
            child: ExerciseDispatcher(
                exercise: currentExercise, onAnswered: _onAnswered),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Row(
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
            child:
                const Icon(Icons.close, color: AppColors.deepPurple, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        const BigMascot(size: 40),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.pinkSoft,
                  offset: Offset(0, 3),
                  blurRadius: 0)
            ],
          ),
          child: Text('${_currentExercise + 1} / $total',
              style: AppTheme.display(size: 14, color: AppColors.pink)),
        ),
      ],
    );
  }

  Widget _buildHintBanner(Map<String, dynamic> ex, String lang) {
    final text = _hintText.isNotEmpty
        ? _hintText
        : (lang == 'en'
            ? (ex['hint_en'] as String? ?? '')
            : (ex['hint_vi'] as String? ?? ''));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange, width: 2),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: AppTheme.body(
                    size: 13,
                    color: AppColors.deepPurple,
                    weight: FontWeight.w800)),
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
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 24),
      child: Column(
        children: [
          _buildDesktopNav(totalExercises, title),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: KidCard(
                      padding: const EdgeInsets.all(32),
                      gradient: const [AppColors.pinkSoft, AppColors.cream],
                      child: ExerciseDispatcher(
                          exercise: currentExercise, onAnswered: _onAnswered),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (_showHint)
                        _buildHintBanner(currentExercise, locale.languageCode),
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

  Widget _buildDesktopNav(int totalExercises, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const BigMascot(size: 40),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)?.appTitle ?? 'Học Vui',
                style: AppTheme.display(size: 22)),
          ],
        ),
        Row(
          children: List.generate(totalExercises, (index) {
            final isFilled = index <= _currentExercise;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isFilled ? AppColors.green : AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: isFilled ? AppColors.green : AppColors.divider,
                      width: 2),
                ),
                alignment: Alignment.center,
                child: Text('${index + 1}',
                    style: AppTheme.display(
                        size: 14,
                        color: isFilled
                            ? AppColors.white
                            : AppColors.mutedPurple)),
              ),
            );
          }),
        ),
        Text(title, style: AppTheme.display(size: 18)),
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
            child:
                const Icon(Icons.close, color: AppColors.deepPurple, size: 20),
          ),
        ),
      ],
    );
  }

  // ================ GAME LOGIC (preserved) ================
  void _onAnswered(bool isCorrect, {String? userAnswer}) {
    final exercises = _lesson!['exercises'] as List<dynamic>;
    final currentEx = exercises[_currentExercise] as Map<String, dynamic>;
    final exerciseId = currentEx['id'] as String? ?? '';
    final userId = ref.read(userIdProvider);
    if (userId != null && userId.isNotEmpty && exerciseId.isNotEmpty) {
      ProgressApi.submitExerciseResult(
        userId: userId,
        exerciseId: exerciseId,
        lessonId: widget.lessonId,
        isCorrect: isCorrect,
      );
    }

    if (isCorrect) {
      HapticFeedback.lightImpact();
      setState(() {
        _correctAnswers++;
        _wrongCountThisExercise = 0;
        _hintText = '';
        _answerHistory.clear();
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _advanceExercise();
      });
    } else {
      HapticFeedback.heavyImpact();
      _wrongCountThisExercise++;
      if (userAnswer != null && userAnswer.isNotEmpty)
        _answerHistory.add(userAnswer);

      final locale = ref.read(localeProvider);
      final staticHint = locale.languageCode == 'en'
          ? currentEx['hint_en'] as String? ?? ''
          : currentEx['hint_vi'] as String? ?? '';

      if (_wrongCountThisExercise >= 2) {
        _fetchAiHint(currentEx, staticHint, locale.languageCode);
      } else {
        setState(() {
          _showHint = true;
          _hintText = staticHint;
        });
      }

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _showHint = false);
      });
    }
  }

  void _fetchAiHint(
      Map<String, dynamic> currentEx, String fallback, String lang) async {
    final exerciseId = currentEx['id'] as String? ?? '';
    final questionText = lang == 'vi'
        ? (currentEx['question_vi'] as String? ?? '')
        : (currentEx['question_en'] as String? ?? '');
    final correctIndex = currentEx['correct_index'] as int?;
    final options = currentEx['options'] as List<dynamic>?;
    final expectedAnswer = (options != null &&
            correctIndex != null &&
            correctIndex < options.length)
        ? options[correctIndex].toString()
        : '';

    final hint = await QuestionBankApi.getHint(
      exerciseId: exerciseId,
      questionText: questionText,
      answerHistory: _answerHistory,
      expectedAnswer: expectedAnswer,
      isVietnamese: lang == 'vi',
      userId: ref.read(userIdProvider) ?? '',
    );

    if (mounted)
      setState(() {
        _showHint = true;
        _hintText = hint ?? fallback;
      });
  }

  void _advanceExercise() {
    final exercises = _lesson!['exercises'] as List<dynamic>;
    if (_currentExercise < exercises.length - 1) {
      setState(() {
        _currentExercise++;
        _showHint = false;
        _wrongCountThisExercise = 0;
        _hintText = '';
        _answerHistory.clear();
      });
      if (ref.read(ttsEnabledProvider)) {
        final nextEx = exercises[_currentExercise] as Map<String, dynamic>;
        final locale = ref.read(localeProvider);
        final vi = nextEx['question_vi'] as String? ?? '';
        final en = nextEx['question_en'] as String? ?? '';
        final question = locale.languageCode == 'vi' ? vi : en;
        if (question.isNotEmpty)
          TtsService().speak(question, languageCode: locale.languageCode);
      }
    } else {
      _finishLesson();
    }
  }

  void _finishLesson() async {
    final userId = ref.read(userIdProvider);
    if (userId == null || userId.isEmpty) return;

    final totalExercises = (_lesson!['exercises'] as List<dynamic>).length;
    final accuracy = totalExercises > 0 ? _correctAnswers / totalExercises : 0;
    int stars = 1;
    if (accuracy >= 0.9)
      stars = 3;
    else if (accuracy >= 0.7) stars = 2;

    try {
      await LanguageApi.updateProgress(
        userId: userId,
        lessonId: widget.lessonId,
        stars: stars,
        completed: true,
      );
      ref.invalidate(streakProvider);
      ref.invalidate(rawProgressProvider);

      if (mounted) {
        context.go('/celebration', extra: {
          'stars': stars,
          'subjectId': widget.subjectId,
          'lessonId': widget.lessonId,
        });
      }
    } catch (e) {
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

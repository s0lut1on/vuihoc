import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/lesson_model.dart';
import '../providers/app_providers.dart';
import '../services/content_api.dart';
import '../services/progress_api.dart';
import '../services/tts_service.dart';
import '../services/wrong_answer_storage.dart';
import '../models/wrong_answer_model.dart';
import '../widgets/clock_face.dart';
import '../widgets/language_switcher.dart';
import '../widgets/paywall_modal.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String lessonId;

  const LessonScreen({
    super.key,
    required this.subjectId,
    required this.lessonId,
  });

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  int _currentQuestion = 0;
  int? _selectedAnswer;
  bool _isCorrect = false;
  bool _showHint = false;
  ApiLesson? _lesson;
  bool _loading = true;
  int _dailyCount = 0;
  String _userTier = 'free';

  @override
  void initState() {
    super.initState();
    _loadLesson();
    _checkDailyLimit();
  }

  Future<void> _checkDailyLimit() async {
    final userId = ref.read(userIdProvider);
    if (userId == null || userId.isEmpty) return;
    final limit = await ProgressApi.getDailyLimit(userId);
    if (limit != null && mounted) {
      setState(() {
        _dailyCount = limit['count'] as int? ?? 0;
        _userTier = limit['tier'] as String? ?? 'free';
      });
    }
  }

  Future<void> _loadLesson() async {
    try {
      final lessons = await ContentApi.getCurriculum();
      final lesson = lessons.firstWhere(
        (l) => l.subjectId == widget.subjectId && l.id == widget.lessonId,
        orElse: () => const ApiLesson(
            id: '',
            subjectId: '',
            titleVi: '',
            titleEn: '',
            order: 0,
            exercises: []),
      );
      setState(() {
        _lesson = lesson;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
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

    if (_lesson == null || _lesson!.exercises.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.lessonNotFound,
            style: const TextStyle(fontSize: 18, color: AppColors.primaryPink),
          ),
        ),
      );
    }

    final currentQ = _lesson!.exercises[_currentQuestion];
    final totalQuestions = _lesson!.exercises.length;

    return Scaffold(
      backgroundColor: AppColors.lightBlueBg,
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(currentQ, totalQuestions)
            : _buildMobileLayout(currentQ, totalQuestions),
      ),
    );
  }

  Widget _buildMobileLayout(ApiExercise currentQ, int totalQuestions) {
    final locale = ref.watch(localeProvider);
    final questionText =
        locale.languageCode == 'en' ? currentQ.questionEn : currentQ.questionVi;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(totalQuestions),
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
            '🍎 $questionText',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: _buildVisualAsset(currentQ),
          ),
          const SizedBox(height: 32),
          _buildOptions(currentQ),
          const SizedBox(height: 16),
          if (_showHint)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locale.languageCode == 'en'
                          ? currentQ.hintEn ?? ''
                          : currentQ.hintVi ?? '',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.primaryPink),
                    ),
                  ),
                ],
              ),
            ),
          if (!_isCorrect && _selectedAnswer != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _resetQuestion,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    AppLocalizations.of(context)!.lessonIncorrectFeedback,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          Center(
            child: GestureDetector(
              onTap: _speakQuestion,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.primaryPink),
                child: const Center(
                    child: Text('🔊', style: TextStyle(fontSize: 28))),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(ApiExercise currentQ, int totalQuestions) {
    final locale = ref.watch(localeProvider);
    final questionText =
        locale.languageCode == 'en' ? currentQ.questionEn : currentQ.questionVi;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Column(
        children: [
          _buildDesktopNav(totalQuestions),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '🍎 $questionText',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkPurple),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildVisualAsset(currentQ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildOptions(currentQ),
                      const SizedBox(height: 24),
                      if (_showHint)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  locale.languageCode == 'en'
                                      ? currentQ.hintEn ?? ''
                                      : currentQ.hintVi ?? '',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.primaryPink),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!_isCorrect && _selectedAnswer != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: _resetQuestion,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                AppLocalizations.of(context)!
                                    .lessonIncorrectFeedback,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _speakQuestion,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryPink),
                          child: const Center(
                              child: Text('🔊',
                                  style: TextStyle(
                                      fontSize: 28, color: Colors.white))),
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

  Widget _buildDesktopNav(int totalQuestions) {
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
                  color: AppColors.darkText),
            ),
          ],
        ),
        Row(
          children: List.generate(totalQuestions, (index) {
            final isFilled = index <= _currentQuestion;
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
                      fontWeight: FontWeight.w700),
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
        final isFilled = index <= _currentQuestion;
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

  Widget _buildVisualAsset(ApiExercise question) {
    final asset = question.visualAsset ?? '';
    final clock = ClockFace.tryParse(asset);
    if (clock != null) return clock;
    return Text(
      asset,
      style: const TextStyle(fontSize: 64),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildOptions(ApiExercise question) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;
        final isSelected = _selectedAnswer == index;
        final isRightAnswer = index == question.correctIndex;

        Color bgColor = AppColors.white;
        Color borderColor = AppColors.divider;
        double borderWidth = 1;

        if (_selectedAnswer != null) {
          if (isRightAnswer) {
            bgColor = Colors.green.shade50;
            borderColor = AppColors.successGreen;
            borderWidth = 2;
          } else if (isSelected && !isRightAnswer) {
            bgColor = Colors.red.shade50;
            borderColor = Colors.red;
            borderWidth = 2;
          }
        } else if (isSelected) {
          borderColor = AppColors.primaryPink;
          borderWidth = 2;
        }

        final minSize = isDesktop ? 140.0 : 110.0;
        final fontSize = isDesktop ? 48.0 : 28.0;

        return GestureDetector(
          onTap: () => _selectAnswer(index, question.correctIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: BoxConstraints(
              minWidth: minSize,
              minHeight: minSize,
              maxWidth: minSize * 2.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: isSelected && !_isCorrect && !isRightAnswer
                        ? Colors.red
                        : AppColors.darkPurple,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _selectAnswer(int index, int correctIndex) {
    if (_selectedAnswer != null) return;

    HapticFeedback.lightImpact();
    setState(() => _selectedAnswer = index);
    _isCorrect = index == correctIndex;

    if (!_isCorrect) {
      final currentQ = _lesson!.exercises[_currentQuestion];
      WrongAnswerStorage.record(WrongAnswer(
        exerciseId: currentQ.id,
        lessonId: widget.lessonId,
        subjectId: widget.subjectId,
        questionVi: currentQ.questionVi,
        questionEn: currentQ.questionEn,
        hintVi: currentQ.hintVi,
        hintEn: currentQ.hintEn,
        options: currentQ.options,
        correctIndex: currentQ.correctIndex,
        wrongCount: 1,
        lastWrongAt: DateTime.now(),
      ));
    }

    if (_isCorrect) {
      _showCorrectFeedback();
    } else {
      _showIncorrectFeedback();
    }
  }

  void _resetQuestion() {
    setState(() {
      _selectedAnswer = null;
      _isCorrect = false;
      _showHint = false;
    });
  }

  void _advanceQuestion() {
    if (_lesson == null) return;
    if (_currentQuestion < _lesson!.exercises.length - 1) {
      setState(() {
        _currentQuestion += 1;
        _selectedAnswer = null;
        _isCorrect = false;
        _showHint = false;
      });
    } else {
      _finishLesson();
    }
  }

  void _finishLesson() async {
    if (_userTier != 'premium' && _dailyCount >= 50) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PaywallModal(onClose: () => context.go('/home')),
      );
      return;
    }

    final userId = ref.read(userIdProvider) ?? '';
    if (userId.isNotEmpty) {
      await ProgressApi.updateProgress(
        userId: userId,
        lessonId: widget.lessonId,
        stars: 3,
        completed: true,
      );
      final updated = await ProgressApi.getDailyLimit(userId);
      if (updated != null && mounted) {
        setState(() => _dailyCount = updated['count'] as int? ?? 0);
      }
    }

    if (mounted) {
      context.go('/celebration', extra: {
        'stars': 3,
        'persona': ref.read(personaProvider)?.name ?? 'achiever',
        'subjectId': widget.subjectId,
        'lessonId': widget.lessonId,
      });
    }
  }

  void _showCorrectFeedback() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _advanceQuestion();
      }
    });
  }

  void _showIncorrectFeedback() {
    setState(() => _showHint = true);
  }

  void _speakQuestion() {
    final isEnabled = ref.read(ttsEnabledProvider);
    if (!isEnabled) return;

    final currentQ = _lesson!.exercises[_currentQuestion];
    final locale = ref.read(localeProvider);
    final text =
        locale.languageCode == 'en' ? currentQ.questionEn : currentQ.questionVi;
    TtsService().speak(text, languageCode: locale.languageCode);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/lesson_model.dart';
import '../providers/app_providers.dart';
import '../services/content_api.dart';
import '../services/daily_limit.dart';
import '../services/progress_api.dart';
import '../services/review_api.dart';
import '../services/tts_service.dart';
import '../services/wrong_answer_storage.dart';
import '../models/wrong_answer_model.dart';
import '../widgets/clock_face.dart';
import '../widgets/kid_card.dart';
import '../widgets/kid_progress_bar.dart';
import '../widgets/mascot.dart';
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
      final userGrade = ref.read(userProvider).value?.grade ?? 1;
      final lessons = await ContentApi.getCurriculum(grade: userGrade);
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
        backgroundColor: AppColors.pinkBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.pink)),
      );
    }
    if (_lesson == null || _lesson!.exercises.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.pinkBg,
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.lessonNotFound,
            style: AppTheme.display(size: 20, color: AppColors.mutedPurple),
          ),
        ),
      );
    }

    final currentQ = _lesson!.exercises[_currentQuestion];
    final totalQuestions = _lesson!.exercises.length;

    return Scaffold(
      backgroundColor: AppColors.pinkBg,
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(totalQuestions, locale.languageCode),
          const SizedBox(height: 12),
          KidProgressBar(
            value: (_currentQuestion + 1) / totalQuestions,
            color: _isCorrect ? AppColors.green : AppColors.pink,
            height: 12,
          ),
          const SizedBox(height: 16),
          Expanded(
              child: _buildQuestionCard(
                  currentQ, questionText, locale.languageCode)),
          const SizedBox(height: 12),
          _buildOptionsGrid(currentQ),
          const SizedBox(height: 12),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildHeader(int total, String lang) {
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
        const SizedBox(width: 8),
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
          child: Text('${_currentQuestion + 1} / $total',
              style: AppTheme.display(size: 14, color: AppColors.pink)),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _speakQuestion,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                    color: AppColors.pinkDark,
                    offset: Offset(0, 4),
                    blurRadius: 0)
              ],
            ),
            child:
                const Center(child: Text('🔊', style: TextStyle(fontSize: 22))),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(ApiExercise q, String questionText, String lang) {
    return KidCard(
      padding: const EdgeInsets.all(20),
      gradient: const [AppColors.pinkSoft, AppColors.cream],
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🍎', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  questionText,
                  style: AppTheme.display(size: 22, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVisualAsset(q),
          if (_showHint) ...[
            const SizedBox(height: 12),
            Container(
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
                    child: Text(
                      lang == 'en' ? (q.hintEn ?? '') : (q.hintVi ?? ''),
                      style: AppTheme.body(
                          size: 13,
                          color: AppColors.deepPurple,
                          weight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisualAsset(ApiExercise question) {
    final asset = question.visualAsset ?? '';
    final clock = ClockFace.tryParse(asset);
    if (clock != null) return clock;
    return Text(asset,
        style: const TextStyle(fontSize: 64), textAlign: TextAlign.center);
  }

  Widget _buildOptionsGrid(ApiExercise question) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;
        final isSelected = _selectedAnswer == index;
        final isRightAnswer = index == question.correctIndex;

        Color bg = AppColors.white;
        Color border = AppColors.divider;
        double borderWidth = 2;
        Color textColor = AppColors.deepPurple;

        if (_selectedAnswer != null) {
          if (isRightAnswer) {
            bg = AppColors.greenSoft;
            border = AppColors.green;
            textColor = AppColors.green;
          } else if (isSelected && !isRightAnswer) {
            bg = const Color(0xFFFEE2E2);
            border = AppColors.red;
            textColor = AppColors.red;
          }
        } else if (isSelected) {
          border = AppColors.pink;
        }

        return GestureDetector(
          onTap: () => _selectAnswer(index, question.correctIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(
                minWidth: 110, minHeight: 90, maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: _selectedAnswer == null
                      ? AppColors.pinkSoft
                      : (isRightAnswer
                          ? AppColors.greenSoft
                          : Colors.transparent),
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTheme.display(size: 32, color: textColor),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow() {
    if (!_isCorrect && _selectedAnswer != null) {
      return Center(
        child: GestureDetector(
          onTap: _resetQuestion,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                    color: Color(0xFFCC5500),
                    offset: Offset(0, 4),
                    blurRadius: 0)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔄', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(AppLocalizations.of(context)!.lessonIncorrectFeedback,
                    style: AppTheme.display(size: 14, color: AppColors.white)),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ================ DESKTOP LAYOUT (kept close to original) ================
  Widget _buildDesktopLayout(ApiExercise currentQ, int totalQuestions) {
    final locale = ref.watch(localeProvider);
    final questionText =
        locale.languageCode == 'en' ? currentQ.questionEn : currentQ.questionVi;
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 24),
      child: Column(
        children: [
          _buildDesktopNav(totalQuestions),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🍎 $questionText',
                              style: AppTheme.display(size: 28),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          _buildVisualAsset(currentQ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildOptionsGrid(currentQ),
                      const SizedBox(height: 16),
                      if (_showHint)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.yellow,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: AppColors.orange, width: 2),
                          ),
                          child: Row(
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  locale.languageCode == 'en'
                                      ? (currentQ.hintEn ?? '')
                                      : (currentQ.hintVi ?? ''),
                                  style: AppTheme.body(
                                      size: 13, weight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!_isCorrect && _selectedAnswer != null)
                        _buildBottomRow(),
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
            const BigMascot(size: 40),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)?.appTitle ?? 'Học Vui',
                style: AppTheme.display(size: 22)),
          ],
        ),
        Row(
          children: List.generate(totalQuestions, (index) {
            final isFilled = index <= _currentQuestion;
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
  void _selectAnswer(int index, int correctIndex) {
    if (_selectedAnswer != null) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedAnswer = index);
    _isCorrect = index == correctIndex;

    if (!_isCorrect) {
      final currentQ = _lesson!.exercises[_currentQuestion];
      final userId = ref.read(userIdProvider) ?? '';
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
      if (userId.isNotEmpty) {
        ReviewApi.recordWrong(
          userId: userId,
          exerciseId: currentQ.id,
          lessonId: widget.lessonId,
          subjectId: widget.subjectId,
          questionVi: currentQ.questionVi,
          questionEn: currentQ.questionEn,
          hintVi: currentQ.hintVi,
          hintEn: currentQ.hintEn,
          options: currentQ.options,
          correctIndex: currentQ.correctIndex,
        );
      }
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
    if (shouldShowPaywall(count: _dailyCount, tier: _userTier)) {
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
      if (mounted) _advanceQuestion();
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

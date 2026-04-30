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
  final int _currentQuestion = 0;
  int? _selectedAnswer;
  bool _isCorrect = false;
  bool _showHint = false;
  ApiLesson? _lesson;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLesson();
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(totalQuestions),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, size: 24),
              onPressed: () => context.go('/home'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '🍎 ${currentQ.questionVi}',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              currentQ.visualAsset ?? '',
              style: const TextStyle(fontSize: 56),
              textAlign: TextAlign.center,
            ),
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
                      currentQ.hintEn ?? '',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.primaryPink),
                    ),
                  ),
                ],
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
                          '🍎 ${currentQ.questionVi}',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkPurple),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          currentQ.visualAsset ?? '',
                          style: const TextStyle(fontSize: 64),
                          textAlign: TextAlign.center,
                        ),
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
                                  currentQ.hintEn ?? '',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.primaryPink),
                                ),
                              ),
                            ],
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
            const Text(
              'Học Toán Vui',
              style: TextStyle(
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

  Widget _buildOptions(ApiExercise question) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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

        final size = isDesktop ? 140.0 : 90.0;
        final fontSize = isDesktop ? 48.0 : 32.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GestureDetector(
            onTap: () => _selectAnswer(index, question.correctIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: Center(
                child: Text(
                  value,
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

    if (_isCorrect) {
      _showCorrectFeedback();
    } else {
      _showIncorrectFeedback();
    }
  }

  void _showCorrectFeedback() async {
    final userId = ref.read(userIdProvider) ?? '';
    if (userId.isNotEmpty) {
      await ProgressApi.updateProgress(
        userId: userId,
        lessonId: widget.lessonId,
        stars: 3,
        completed: true,
      );
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.go('/celebration', extra: {
          'stars': 3,
          'persona': ref.read(personaProvider)?.name ?? 'achiever',
        });
      }
    });
  }

  void _showIncorrectFeedback() {
    setState(() => _showHint = true);
  }

  void _speakQuestion() {}
}

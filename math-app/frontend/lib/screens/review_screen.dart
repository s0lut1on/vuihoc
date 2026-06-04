import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/wrong_answer_model.dart';
import '../providers/app_providers.dart';
import '../services/review_api.dart';
import '../services/tts_service.dart';
import '../services/wrong_answer_storage.dart';
import '../widgets/language_switcher.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<WrongAnswer> _items = [];
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _isCorrect = false;
  bool _showHint = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final local = await WrongAnswerStorage.load();
    final userId = ref.read(userIdProvider) ?? '';
    List<WrongAnswer> merged = List.from(local);

    if (userId.isNotEmpty) {
      try {
        final remote = await ReviewApi.getReview(userId);
        for (final entry in remote) {
          final existing = merged.indexWhere((e) => e.exerciseId == entry['exercise_id']);
          final wrongCount = (entry['wrong_count'] as int?) ?? 1;
          final remoteLastWrong = DateTime.tryParse(entry['last_wrong_at'] as String? ?? '') ?? DateTime.now();
          if (existing >= 0) {
            // Keep whichever has higher wrong_count or more recent
            if (wrongCount > merged[existing].wrongCount ||
                remoteLastWrong.isAfter(merged[existing].lastWrongAt)) {
              merged[existing] = WrongAnswer(
                exerciseId: entry['exercise_id'] as String,
                lessonId: entry['lesson_id'] as String,
                subjectId: entry['subject_id'] as String,
                questionVi: entry['question_vi'] as String,
                questionEn: entry['question_en'] as String,
                hintVi: entry['hint_vi'] as String?,
                hintEn: entry['hint_en'] as String?,
                options: (entry['options'] as List<dynamic>).cast<String>(),
                correctIndex: entry['correct_index'] as int,
                wrongCount: wrongCount,
                lastWrongAt: remoteLastWrong,
              );
            }
          } else {
            merged.add(WrongAnswer(
              exerciseId: entry['exercise_id'] as String,
              lessonId: entry['lesson_id'] as String,
              subjectId: entry['subject_id'] as String,
              questionVi: entry['question_vi'] as String,
              questionEn: entry['question_en'] as String,
              hintVi: entry['hint_vi'] as String?,
              hintEn: entry['hint_en'] as String?,
              options: (entry['options'] as List<dynamic>).cast<String>(),
              correctIndex: entry['correct_index'] as int,
              wrongCount: wrongCount,
              lastWrongAt: remoteLastWrong,
            ));
          }
        }
      } catch (_) {
        // offline: show local only
      }
    }

    setState(() {
      _items = merged..sort((a, b) => b.wrongCount.compareTo(a.wrongCount));
      _loading = false;
    });
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

    if (_items.isEmpty) {
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

    final current = _items[_currentIndex];
    final total = _items.length;
    final locale = ref.watch(localeProvider);
    final questionText =
        locale.languageCode == 'en' ? current.questionEn : current.questionVi;

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.lightBlueBg,
      body: SafeArea(
        child: Padding(
          padding: isDesktop
              ? const EdgeInsets.symmetric(horizontal: 48, vertical: 24)
              : const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                '🍎 $questionText',
                style: isDesktop
                    ? const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkPurple)
                    : Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!
                    .reviewWrongCount(current.wrongCount),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedPurple,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: _buildOptions(current, isDesktop),
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
                              ? current.hintEn ?? ''
                              : current.hintVi ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryPink,
                          ),
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

  Widget _buildOptions(WrongAnswer question, bool isDesktop) {
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
          onTap: () => _selectAnswer(index, question),
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

  void _selectAnswer(int index, WrongAnswer question) {
    if (_selectedAnswer != null) return;

    HapticFeedback.lightImpact();
    setState(() => _selectedAnswer = index);
    _isCorrect = index == question.correctIndex;

    if (_isCorrect) {
      // User finally got it right — remove from wrong-answer pool.
      WrongAnswerStorage.remove(question.exerciseId);
      final userId = ref.read(userIdProvider) ?? '';
      if (userId.isNotEmpty) {
        ReviewApi.clearWrong(
          userId: userId,
          exerciseId: question.exerciseId,
        );
      }
      _showCorrectFeedback();
    } else {
      WrongAnswerStorage.record(question);
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

  void _showCorrectFeedback() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_currentIndex < _items.length - 1) {
        setState(() {
          _currentIndex += 1;
          _selectedAnswer = null;
          _isCorrect = false;
          _showHint = false;
        });
      } else {
        context.go('/home');
      }
    });
  }

  void _showIncorrectFeedback() {
    setState(() => _showHint = true);
  }

  void _speakQuestion() {
    final isEnabled = ref.read(ttsEnabledProvider);
    if (!isEnabled) return;

    final current = _items[_currentIndex];
    final locale = ref.read(localeProvider);
    final text =
        locale.languageCode == 'en' ? current.questionEn : current.questionVi;
    TtsService().speak(text, languageCode: locale.languageCode);
  }
}

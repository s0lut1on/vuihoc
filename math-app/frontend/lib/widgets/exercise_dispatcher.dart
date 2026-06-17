import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_colors.dart';
import '../providers/app_providers.dart';
import '../services/tts_service.dart';
import 'audio_player_widget.dart';
import 'text_input_widget.dart';
import 'matching_exercise.dart';
import 'ordering_exercise.dart';

class ExerciseDispatcher extends ConsumerStatefulWidget {
  final Map<String, dynamic> exercise;
  final Function(bool isCorrect, {String? userAnswer}) onAnswered;

  const ExerciseDispatcher({
    super.key,
    required this.exercise,
    required this.onAnswered,
  });

  @override
  ConsumerState<ExerciseDispatcher> createState() => _ExerciseDispatcherState();
}

class _ExerciseDispatcherState extends ConsumerState<ExerciseDispatcher> {
  int? _selectedAnswer;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    // Plan 3: auto-play the prompt for listen_select exercises on first
    // build. Guarded by ttsEnabledProvider + isSupported so non-web builds
    // and disabled users are no-ops.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ttsEnabled = ref.read(ttsEnabledProvider);
      if (!ttsEnabled || !TtsService().isSupported) return;
      final ex = widget.exercise;
      final type = ex['exercise_type'] as String? ?? 'mcq';
      if (type != 'listen_select') return;
      final locale = Localizations.localeOf(context);
      final text = locale.languageCode == 'en'
          ? (ex['question_en'] as String? ?? '')
          : (ex['question_vi'] as String? ?? '');
      if (text.isEmpty) return;
      // Small delay so the screen settles before speech starts.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      TtsService().speak(text, languageCode: locale.languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final exerciseType = widget.exercise['exercise_type'] as String? ?? 'mcq';

    switch (exerciseType) {
      case 'audio_mcq':
        return _buildAudioMcqExercise();
      case 'listen_select':
        return _buildListenSelectExercise();
      case 'typing':
        return _buildTypingExercise();
      case 'matching':
        return MatchingExercise(
            exercise: widget.exercise, onAnswered: widget.onAnswered);
      case 'ordering':
        return OrderingExercise(
            exercise: widget.exercise, onAnswered: widget.onAnswered);
      case 'mcq':
      default:
        return _buildMcqExercise();
    }
  }

  Widget _buildAudioMcqExercise() {
    final audioUrl = widget.exercise['audio_url'] as String?;
    return Column(
      children: [
        Center(
          child: AudioPlayerWidget(
            audioUrl: audioUrl,
            fallbackText: _resolveQuestion(),
            languageCode: Localizations.localeOf(context).languageCode,
          ),
        ),
        const SizedBox(height: 24),
        _buildMcqOptions(),
      ],
    );
  }

  Widget _buildListenSelectExercise() {
    final audioUrl = widget.exercise['audio_url'] as String?;
    final locale = Localizations.localeOf(context);
    final question = _resolveQuestion();
    final ttsEnabled = ref.watch(ttsEnabledProvider);
    return Column(
      children: [
        Center(
          child: AudioPlayerWidget(
            audioUrl: audioUrl,
            fallbackText: question,
            languageCode: locale.languageCode,
          ),
        ),
        if (question.isNotEmpty && ttsEnabled && TtsService().isSupported)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ElevatedButton.icon(
              onPressed: () => TtsService()
                  .speak(question, languageCode: locale.languageCode),
              icon: const Icon(Icons.volume_up, size: 18),
              label: Text(locale.languageCode == 'en' ? 'Listen' : 'Nghe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        const SizedBox(height: 32),
        _buildMcqOptions(),
      ],
    );
  }

  Widget _buildTypingExercise() {
    final exerciseId = widget.exercise['id'] as String? ?? '';
    final expectedText = widget.exercise['expected_text'] as String? ?? '';
    final hintVi = widget.exercise['hint_vi'] as String? ?? '';
    final hintEn = widget.exercise['hint_en'] as String? ?? '';
    final diacriticSensitive =
        widget.exercise['diacritic_sensitive'] as bool? ?? true;
    final validationMode =
        widget.exercise['validation_mode'] as String? ?? 'exact';

    return TextInputWidget(
      exerciseId: exerciseId,
      expectedText: expectedText,
      hintVi: hintVi,
      hintEn: hintEn,
      diacriticSensitive: diacriticSensitive,
      validationMode: validationMode,
      onAnswered: widget.onAnswered,
    );
  }

  Widget _buildMcqExercise() {
    return _buildMcqOptions();
  }

  Widget _buildMcqOptions() {
    final options =
        (widget.exercise['options'] as List<dynamic>?)?.cast<String>() ?? [];
    final correctIndex = widget.exercise['correct'] as int? ?? 0;
    final question = _resolveQuestion();
    final locale = Localizations.localeOf(context);
    final ttsEnabled = ref.watch(ttsEnabledProvider);

    return Column(
      children: [
        if (question.isNotEmpty && ttsEnabled && TtsService().isSupported)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => TtsService()
                      .speak(question, languageCode: locale.languageCode),
                  icon: const Icon(Icons.volume_up, size: 18),
                  label: Text(locale.languageCode == 'en' ? 'Listen' : 'Nghe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: options.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;
            final isSelected = _selectedAnswer == index;
            final isRightAnswer = index == correctIndex;

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

            return GestureDetector(
              onTap: () => _selectAnswer(index, correctIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                constraints: const BoxConstraints(
                  minWidth: 110,
                  minHeight: 110,
                  maxWidth: 200,
                ),
                padding: const EdgeInsets.all(16),
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
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isSelected &&
                                _selectedAnswer != null &&
                                !isRightAnswer
                            ? Colors.red
                            : AppColors.darkPurple,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _selectAnswer(int index, int correctIndex) {
    if (_selectedAnswer != null) return;

    HapticFeedback.lightImpact();
    setState(() => _selectedAnswer = index);
    _isCorrect = index == correctIndex;

    final options =
        (widget.exercise['options'] as List<dynamic>?)?.cast<String>() ?? [];
    final userAnswer =
        (index >= 0 && index < options.length) ? options[index] : '';
    widget.onAnswered(_isCorrect, userAnswer: userAnswer);

    if (!_isCorrect) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _selectedAnswer = null;
            _isCorrect = false;
          });
        }
      });
    }
  }

  String _resolveQuestion() {
    final locale = Localizations.localeOf(context);
    final vi = widget.exercise['question_vi'] as String? ?? '';
    final en = widget.exercise['question_en'] as String? ?? '';
    return locale.languageCode == 'vi' ? vi : en;
  }
}

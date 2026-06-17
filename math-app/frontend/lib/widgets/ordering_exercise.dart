import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_colors.dart';
import '../providers/app_providers.dart';
import '../services/tts_service.dart';

/// Ordering exercise: arrange scrambled words in correct sentence order.
/// User taps words from a pool to add to answer row; taps in answer row to remove.
class OrderingExercise extends ConsumerStatefulWidget {
  final Map<String, dynamic> exercise;
  final Function(bool isCorrect) onAnswered;

  const OrderingExercise({
    super.key,
    required this.exercise,
    required this.onAnswered,
  });

  @override
  ConsumerState<OrderingExercise> createState() => _OrderingExerciseState();
}

class _OrderingExerciseState extends ConsumerState<OrderingExercise> {
  List<String> _answer = [];
  List<String> _pool = [];

  @override
  void initState() {
    super.initState();
    final options =
        (widget.exercise['options'] as List<dynamic>?)?.cast<String>() ?? [];
    _pool = [...options]..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final question = _resolveQuestion(widget.exercise);
    final ttsEnabled = ref.watch(ttsEnabledProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (question.isNotEmpty && ttsEnabled && TtsService().isSupported)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () => TtsService()
                  .speak(question, languageCode: locale.languageCode),
              icon: const Icon(Icons.volume_up, size: 18),
              label: Text(locale.languageCode == 'en' ? 'Listen' : 'Nghe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        Text(
          question,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.darkPurple),
        ),
        const SizedBox(height: 32),
        // Answer row
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryPink, width: 2),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _answer.isEmpty
                ? [
                    Text(
                      'Tap words below',
                      style: TextStyle(
                          fontSize: 18,
                          color: AppColors.darkText.withOpacity(0.4)),
                    ),
                  ]
                : _answer.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final word = entry.value;
                    return GestureDetector(
                      onTap: () => _removeFromAnswer(idx),
                      child: Chip(
                        label: Text(word),
                        backgroundColor:
                            AppColors.primaryPink.withOpacity(0.15),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeFromAnswer(idx),
                      ),
                    );
                  }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        // Word pool
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _pool.map((word) {
            return GestureDetector(
              onTap: () => _addToAnswer(word),
              child: Chip(
                label: Text(word,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600)),
                backgroundColor: AppColors.lightBlueBg,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        // Submit (only when pool is empty = all words used)
        if (_pool.isEmpty)
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Kiểm tra / Check',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
      ],
    );
  }

  String _resolveQuestion(Map<String, dynamic> exercise) {
    final locale = Localizations.localeOf(context);
    final vi = exercise['question_vi'] as String? ?? '';
    final en = exercise['question_en'] as String? ?? '';
    return locale.languageCode == 'vi' ? vi : en;
  }

  void _addToAnswer(String word) {
    HapticFeedback.lightImpact();
    setState(() {
      _answer.add(word);
      _pool.remove(word);
    });
  }

  void _removeFromAnswer(int idx) {
    HapticFeedback.lightImpact();
    setState(() {
      final word = _answer.removeAt(idx);
      _pool.add(word);
    });
  }

  void _submit() {
    HapticFeedback.mediumImpact();
    // For ordering, we validate client-side then server-side
    // Client-side can give instant feedback
    final expected = (widget.exercise['expected_text'] as String? ?? '')
        .trim()
        .toLowerCase();
    final userAnswer = _answer.join(' ').trim().toLowerCase();
    final isCorrect = userAnswer == expected;
    widget.onAnswered(isCorrect);
  }
}

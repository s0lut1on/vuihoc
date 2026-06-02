import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../services/language_api.dart';
import '../l10n/app_localizations.dart';

class TextInputWidget extends StatefulWidget {
  final String exerciseId;
  final String expectedText;
  final String hintVi;
  final String hintEn;
  final bool diacriticSensitive;
  final String validationMode;
  final Function(bool isCorrect) onAnswered;

  const TextInputWidget({
    super.key,
    required this.exerciseId,
    required this.expectedText,
    required this.hintVi,
    required this.hintEn,
    required this.diacriticSensitive,
    required this.validationMode,
    required this.onAnswered,
  });

  @override
  State<TextInputWidget> createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  final TextEditingController _textController = TextEditingController();
  bool _isCorrect = false;
  bool _showResult = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final isCorrect = await LanguageApi.validateText(
        widget.exerciseId,
        _textController.text,
      );

      if (mounted) {
        setState(() {
          _isCorrect = isCorrect;
          _showResult = true;
          _isLoading = false;
        });

        widget.onAnswered(isCorrect);

        // If incorrect, provide haptic feedback
        if (!isCorrect) {
          HapticFeedback.lightImpact();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _textController.clear();
      _isCorrect = false;
      _showResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isVietnamese = locale.languageCode == 'vi';
    final hintText = isVietnamese ? widget.hintVi : widget.hintEn;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _textController,
          enabled: !_showResult,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryPink),
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitAnswer(),
        ),
        const SizedBox(height: 16),
        Center(
          child: !_showResult
              ? ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitAnswer,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 20),
                  label:
                      Text(locale.languageCode == 'vi' ? 'Kiểm tra' : 'Check'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCorrect
                            ? AppColors.successGreen
                            : Colors.red.shade400,
                      ),
                      child: Icon(
                        _isCorrect ? Icons.check : Icons.close,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _isCorrect
                          ? l10n.lessonCorrectFeedback
                          : '${l10n.lessonIncorrectFeedback}!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isCorrect
                            ? AppColors.successGreen
                            : Colors.red.shade400,
                      ),
                    ),
                    if (!_isCorrect) ...[
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _reset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(locale.languageCode == 'vi'
                            ? 'Thử lại'
                            : 'Try again'),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/local_storage_service.dart';
import '../widgets/language_switcher.dart';

class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({super.key});

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  int _currentQuestion = 0;
  final List<int?> _answers = [null, null, null, null];

  final List<Map<String, dynamic>> _questions = [
    {
      'vi': 'Bé đã đếm được đến số mấy rồi?',
      'en': 'How far can you count?',
      'options': [
        {'vi': 'Đếm đến 10', 'en': 'Up to 10', 'value': 10},
        {'vi': 'Đếm đến 50', 'en': 'Up to 50', 'value': 50},
        {'vi': 'Đếm đến 100 hoặc hơn', 'en': 'Up to 100 or more', 'value': 100},
      ],
    },
    {
      'vi': 'Bé đã biết cộng trừ chưa?',
      'en': 'Do you know addition and subtraction?',
      'options': [
        {'vi': 'Chưa biết', 'en': 'Not yet', 'value': 0},
        {'vi': 'Biết một chút', 'en': 'A little', 'value': 1},
        {'vi': 'Biết nhiều rồi', 'en': 'Very well', 'value': 2},
      ],
    },
    {
      'vi': 'Bé học nhanh hay chậm?',
      'en': 'How fast do you learn?',
      'options': [
        {'vi': 'Cần thời gian', 'en': 'Need time', 'value': 0},
        {'vi': 'Bình thường', 'en': 'Normal', 'value': 1},
        {'vi': 'Rất nhanh', 'en': 'Very fast', 'value': 2},
      ],
    },
    {
      'vi': 'Bé thích điều gì nhất?',
      'en': 'What do you like most?',
      'options': [
        {'vi': 'Được khen giỏi', 'en': 'Being praised', 'value': 0},
        {'vi': 'Chơi game, nhận quà', 'en': 'Games and rewards', 'value': 1},
        {'vi': 'Tự học một mình', 'en': 'Learning quietly', 'value': 2},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentQ = _questions[_currentQuestion];
    final options = currentQ['options'] as List<Map<String, dynamic>>;
    final answeredCount = _answers.where((a) => a != null).length;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(l10n, currentQ, options, answeredCount)
            : _buildMobileLayout(l10n, currentQ, options, answeredCount),
      ),
    );
  }

  // ==================== MOBILE ====================
  Widget _buildMobileLayout(
      AppLocalizations l10n,
      Map<String, dynamic> currentQ,
      List<Map<String, dynamic>> options,
      int answeredCount) {
    final questionText = _getQuestionText(l10n, _currentQuestion);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🦉', style: TextStyle(fontSize: 48)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    questionText,
                    style: const TextStyle(
                        fontSize: 17, color: AppColors.darkText),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final isSelected = _answers[_currentQuestion] == index;
                return _optionCard(options[index], l10n, isSelected,
                    () => _selectAnswer(index));
              },
            ),
          ),
          const SizedBox(height: 16),
          if (answeredCount > 0)
            Center(
              child: TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  l10n.assessmentSkip(answeredCount),
                  style: const TextStyle(color: AppColors.mutedText),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ==================== DESKTOP ====================
  Widget _buildDesktopLayout(
      AppLocalizations l10n,
      Map<String, dynamic> currentQ,
      List<Map<String, dynamic>> options,
      int answeredCount) {
    final questionText = _getQuestionText(l10n, _currentQuestion);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Column(
        children: [
          _buildDesktopNav(l10n),
          const SizedBox(height: 32),
          _buildDesktopProgressBar(),
          const SizedBox(height: 40),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              questionText,
              style: const TextStyle(fontSize: 20, color: AppColors.darkText),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = _answers[_currentQuestion] == index;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildDesktopOptionCard(option, l10n, isSelected,
                      () => _selectAnswer(index), index),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            '💡 ${l10n.assessmentHint}',
            style: const TextStyle(fontSize: 14, color: AppColors.mutedText),
          ),
          if (answeredCount > 0)
            TextButton(
              onPressed: () => context.go('/home'),
              child: Text(
                l10n.assessmentSkip(answeredCount),
                style: const TextStyle(color: AppColors.mutedText),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopNav(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('🐸', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Text(
              l10n.appTitle,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText),
            ),
          ],
        ),
        Row(
          children: [
            const LanguageSwitcher(),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.darkText),
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopProgressBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index <= _currentQuestion;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isFilled ? AppColors.primaryPink : AppColors.divider,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDesktopOptionCard(Map<String, dynamic> option,
      AppLocalizations l10n, bool isSelected, VoidCallback onTap, int index) {
    final locale = Localizations.localeOf(context);
    final optionText = _getOptionText(locale, option);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${index + 1}',
              style: TextStyle(
                  fontSize: 48,
                  color: AppColors.primaryPink,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                optionText,
                style: const TextStyle(fontSize: 18, color: AppColors.darkText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SHARED ====================
  Widget _buildProgressBar() {
    return Row(
      children: List.generate(4, (index) {
        final isFilled = index <= _currentQuestion;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            decoration: BoxDecoration(
              color: isFilled ? AppColors.primaryPink : AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _optionCard(Map<String, dynamic> option, AppLocalizations l10n,
      bool isSelected, VoidCallback onTap) {
    final locale = Localizations.localeOf(context);
    final optionText = _getOptionText(locale, option);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              optionText,
              style: const TextStyle(fontSize: 16, color: AppColors.darkText),
            ),
          ],
        ),
      ),
    );
  }

  String _getQuestionText(AppLocalizations l10n, int index) {
    switch (index) {
      case 0:
        return l10n.assessmentQuestion1;
      case 1:
        return l10n.assessmentQuestion2;
      case 2:
        return l10n.assessmentQuestion3;
      case 3:
        return l10n.assessmentQuestion4;
      default:
        return l10n.assessmentQuestion1;
    }
  }

  String _getOptionText(Locale locale, Map<String, dynamic> option) {
    return option[locale.languageCode] as String;
  }

  void _selectAnswer(int index) async {
    HapticFeedback.lightImpact();
    setState(() => _answers[_currentQuestion] = index);

    await Future.delayed(const Duration(milliseconds: 300));

    if (_currentQuestion < _questions.length - 1) {
      setState(() => _currentQuestion++);
    } else {
      await _completeAssessment();
    }
  }

  Future<void> _completeAssessment() async {
    await LocalStorageService.saveOnboardingComplete();
    if (mounted) {
      final persona = ref.read(personaProvider)?.name ?? 'achiever';
      context.go('/celebration', extra: {
        'stars': 3,
        'persona': persona,
      });
    }
  }
}

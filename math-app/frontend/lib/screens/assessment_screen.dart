import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/local_storage_service.dart';
import '../widgets/bubble_button.dart';
import '../widgets/kid_card.dart';
import '../widgets/kid_progress_bar.dart';
import '../widgets/mascot.dart';

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
      'vi': 'Bé đã đếm và đọc được đến đâu rồi?',
      'en': 'How far can your child count and read?',
      'icon': '🔢',
      'options': [
        {'vi': 'Đếm đến 10', 'en': 'Up to 10', 'value': 10, 'emoji': '🔟'},
        {'vi': 'Đếm đến 50', 'en': 'Up to 50', 'value': 50, 'emoji': '5️⃣'},
        {'vi': 'Đếm đến 100 hoặc hơn', 'en': 'Up to 100 or more', 'value': 100, 'emoji': '💯'},
      ],
    },
    {
      'vi': 'Bé đã biết chữ cái và số chưa?',
      'en': 'Does your child know letters and numbers?',
      'icon': '🔤',
      'options': [
        {'vi': 'Chưa biết', 'en': 'Not yet', 'value': 0, 'emoji': '🌱'},
        {'vi': 'Biết một chút', 'en': 'A little', 'value': 1, 'emoji': '🌿'},
        {'vi': 'Biết nhiều rồi', 'en': 'Very well', 'value': 2, 'emoji': '🌳'},
      ],
    },
    {
      'vi': 'Bé học nhanh hay chậm?',
      'en': 'How fast do you learn?',
      'icon': '🚀',
      'options': [
        {'vi': 'Cần thời gian', 'en': 'Need time', 'value': 0, 'emoji': '🐢'},
        {'vi': 'Bình thường', 'en': 'Normal', 'value': 1, 'emoji': '🐰'},
        {'vi': 'Rất nhanh', 'en': 'Very fast', 'value': 2, 'emoji': '⚡'},
      ],
    },
    {
      'vi': 'Bé thích điều gì nhất?',
      'en': 'What do you like most?',
      'icon': '💖',
      'options': [
        {'vi': 'Được khen giỏi', 'en': 'Being praised', 'value': 0, 'emoji': '🏆'},
        {'vi': 'Chơi game, nhận quà', 'en': 'Games and rewards', 'value': 1, 'emoji': '🎮'},
        {'vi': 'Tự học một mình', 'en': 'Learning quietly', 'value': 2, 'emoji': '🤫'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentQ = _questions[_currentQuestion];
    final options = currentQ['options'] as List<Map<String, dynamic>>;
    final answeredCount = _answers.where((a) => a != null).length;

    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(l10n),
              const SizedBox(height: 16),
              _buildProgressDots(),
              const SizedBox(height: 20),
              _buildQuestionCard(currentQ, l10n),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final isSelected = _answers[_currentQuestion] == index;
                    return _optionCard(options[index], isSelected, () => _selectAnswer(index));
                  },
                ),
              ),
              if (answeredCount > 0)
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(l10n.assessmentSkip(answeredCount),
                        style: AppTheme.body(size: 13, color: AppColors.mutedPurple)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        const BigMascot(size: 56, float_: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.appTitle, style: AppTheme.display(size: 22)),
              Text('Cho bé làm vài câu hỏi vui nhé!',
                  style: AppTheme.body(size: 12, color: AppColors.mutedPurple)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/home'),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.white, shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: AppColors.pinkSoft, offset: Offset(0, 3), blurRadius: 0)],
            ),
            child: const Icon(Icons.close, color: AppColors.deepPurple, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDots() {
    return KidProgressBar(
      value: (_currentQuestion + 1) / _questions.length,
      color: AppColors.purple, height: 12,
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q, AppLocalizations l10n) {
    final questionText = _getQuestionText(l10n, _currentQuestion);
    final icon = q['icon'] as String;
    return KidCard(
      gradient: const [AppColors.pinkSoft, AppColors.cream],
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              questionText,
              style: AppTheme.display(size: 20, color: AppColors.deepPurple, weight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionCard(Map<String, dynamic> option, bool isSelected, VoidCallback onTap) {
    final locale = Localizations.localeOf(context);
    final optionText = option[locale.languageCode] as String;
    final emoji = option['emoji'] as String? ?? '✨';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pinkSoft : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.pink : AppColors.divider,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.pinkSoft : Colors.transparent,
              offset: const Offset(0, 4), blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(child: Text(optionText, style: AppTheme.display(size: 16))),
            if (isSelected) const Text('✓', style: TextStyle(fontSize: 24, color: AppColors.pink)),
          ],
        ),
      ),
    );
  }

  String _getQuestionText(AppLocalizations l10n, int index) {
    switch (index) {
      case 0: return l10n.assessmentQuestion1;
      case 1: return l10n.assessmentQuestion2;
      case 2: return l10n.assessmentQuestion3;
      case 3: return l10n.assessmentQuestion4;
      default: return l10n.assessmentQuestion1;
    }
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
      context.go('/celebration', extra: {'stars': 3, 'persona': persona});
    }
  }
}

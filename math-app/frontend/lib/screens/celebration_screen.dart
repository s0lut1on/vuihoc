import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../models/persona_model.dart';
import '../providers/app_providers.dart';

class CelebrationScreen extends ConsumerStatefulWidget {
  final int stars;
  final String persona;

  const CelebrationScreen({
    super.key,
    required this.stars,
    required this.persona,
  });

  @override
  ConsumerState<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends ConsumerState<CelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final isVietnamese = locale.languageCode == 'vi';
    final persona = Persona.values.byName(widget.persona);

    final messages = _getMessages(isVietnamese, persona);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildStars(),
                ),
                const SizedBox(height: 24),
                Text(
                  messages['title']!,
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  messages['subtitle']!,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🎉', style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 8),
                    Text(
                      '+${widget.stars * 5} 💎',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                      ),
                      child: Text(messages['next']!),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => context.go('/home'),
                      child: Text(messages['home']!),
                    ),
                  ],
                ),
                if (persona == Persona.gamer) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gamerGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isVietnamese
                          ? 'Mo khoa: Phep cong cap do 2!'
                          : 'Unlock: Addition Level 2!',
                      style: TextStyle(
                        color: AppColors.gamerText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isFilled = index < widget.stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            isFilled ? Icons.star : Icons.star_border,
            size: 56,
            color: isFilled ? Colors.amber : AppColors.divider,
          ),
        );
      }),
    );
  }

  Map<String, String> _getMessages(bool isVietnamese, Persona persona) {
    final baseMessages = {
      'achiever': {
        'titleVi': 'Chinh xac!',
        'titleEn': 'Correct!',
        'subVi': 'Be gioi qua! Tiep tuc nao!',
        'subEn': 'Great job! Keep going!',
      },
      'gamer': {
        'titleVi': 'Chien thang!',
        'titleEn': 'Victory!',
        'subVi': 'Be nhan duoc +15 diem!',
        'subEn': 'You earned +15 points!',
      },
      'struggler': {
        'titleVi': 'Be lam rat co gang!',
        'titleEn': 'Great effort!',
        'subVi': 'Dung bo cuoi, minh lam tiep bai khac nhe!',
        'subEn': "Don't give up, let's try another!",
      },
      'silent': {
        'titleVi': 'Lam tot lam!',
        'titleEn': 'Well done!',
        'subVi': 'Bé đã học được thứ mới rồi!',
        'subEn': 'You learned something new!',
      },
    };

    final personaMessages = baseMessages[persona.name]!;
    return {
      'title': isVietnamese
          ? personaMessages['titleVi']!
          : personaMessages['titleEn']!,
      'subtitle':
          isVietnamese ? personaMessages['subVi']! : personaMessages['subEn']!,
      'next': isVietnamese ? 'Học tiếp' : 'Continue',
      'home': isVietnamese ? 'Về nhà' : 'Home',
    };
  }
}

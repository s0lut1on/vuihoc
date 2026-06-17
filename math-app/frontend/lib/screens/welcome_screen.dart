import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/persona_model.dart';
import '../services/local_storage_service.dart';
import '../services/user_api.dart';
import '../widgets/bubble_button.dart';
import '../widgets/language_switcher.dart';
import '../widgets/mascot.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  Persona? _selectedPersona;
  int _selectedGrade = 1;
  late final AnimationController _anim;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
    _anim.forward();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: LanguageSwitcher(),
              ),
            ),
            ScaleTransition(
              scale: _scale,
              child: const BigMascot(size: 140, wiggle: true),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n.welcomeSelectPersona,
                textAlign: TextAlign.center,
                style: AppTheme.display(size: 40),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                l10n.welcomePersonaSubtitle,
                textAlign: TextAlign.center,
                style: AppTheme.body(size: 16, color: AppColors.mutedPurple),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: Persona.values.map((p) => _personaCard(p, l10n)).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${l10n.parentDashboardSettings == null ? 'Lớp' : 'Lớp'}: ',
                      style: AppTheme.body(size: 16, color: AppColors.mutedPurple)),
                  const SizedBox(width: 8),
                  for (var g in const [1, 2, 3]) ...[
                    _gradeChip(g, l10n),
                    if (g != 3) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: BubbleButton(
                label: l10n.welcomeStartButton,
                onPressed: _selectedPersona == null ? null : _start,
                minWidth: 280,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _personaCard(Persona p, AppLocalizations l10n) {
    final selected = _selectedPersona == p;
    return GestureDetector(
      onTap: () => setState(() => _selectedPersona = p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? p.backgroundColor : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? AppColors.pink : AppColors.pinkSoft, width: selected ? 4 : 3),
          boxShadow: [
            const BoxShadow(color: AppColors.pinkSoft, offset: Offset(0, 6), blurRadius: 0),
            BoxShadow(color: AppColors.purple.withValues(alpha: 0.10), offset: const Offset(0, 8), blurRadius: 16),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(p.emoji, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 8),
            Text(
              _personaName(p),
              style: AppTheme.display(size: 18, color: p.textColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _personaName(Persona p) {
    switch (p) {
      case Persona.achiever: return 'Học giỏi';
      case Persona.gamer: return 'Chơi game';
      case Persona.struggler: return 'Cần động viên';
      case Persona.silent: return 'Nhút nhát';
    }
  }

  Widget _gradeChip(int g, AppLocalizations l10n) {
    final selected = _selectedGrade == g;
    return GestureDetector(
      onTap: () => setState(() => _selectedGrade = g),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.pink : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.pink : AppColors.pinkSoft, width: 2),
        ),
        child: Text('Lớp $g',
            style: AppTheme.display(size: 16, color: selected ? AppColors.white : AppColors.deepPurple)),
      ),
    );
  }

  void _start() async {
    try {
      await UserApi.createUser(
        name: 'Bé',
        persona: _selectedPersona!.name,
        grade: _selectedGrade,
      );
      await LocalStorageService.saveOnboardingComplete();
    } catch (_) {}
    if (mounted) context.go('/home');
  }
}

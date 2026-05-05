import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/persona_model.dart';
import '../providers/app_providers.dart';
import '../widgets/language_switcher.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  Persona? _selectedPersona;
  late final AnimationController _mascotController;
  late final Animation<double> _mascotAnimation;

  @override
  void initState() {
    super.initState();
    _mascotController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _mascotAnimation = CurvedAnimation(
      parent: _mascotController,
      curve: Curves.elasticOut,
    );
    _mascotController.forward();
  }

  @override
  void dispose() {
    _mascotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightPinkBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildDesktop();
          }
          return _buildMobile();
        },
      ),
    );
  }

  // =================== DESKTOP ===================
  Widget _buildDesktop() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildDesktopNav(),
        Expanded(
          child: Container(
            color: const Color(0xFFFFE8F0),
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 60),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.welcomeGreeting,
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkPurple,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.welcomeSubtitle,
                        style: const TextStyle(
                          fontSize: 20,
                          color: AppColors.mutedPurple,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.welcomeSelectPersona,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A4A6A),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: [
                          _personaCardDesktop(Persona.achiever),
                          _personaCardDesktop(Persona.gamer),
                          _personaCardDesktop(Persona.struggler),
                          _personaCardDesktop(Persona.silent),
                        ],
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _selectedPersona == null ? null : _onStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          minimumSize: const Size(260, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(l10n.welcomeTitle),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _onParentAccess,
                        child: Text(
                          l10n.welcomeParentAccess,
                          style: const TextStyle(
                              color: AppColors.mutedPurple, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                Container(
                  width: 480,
                  height: 480,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryPink,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('🐸', style: TextStyle(fontSize: 96)),
                      const SizedBox(height: 8),
                      Text(
                        'Mascot Preview',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopNav() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 48),
      color: AppColors.white,
      child: Row(
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
                  color: AppColors.darkPurple,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const LanguageSwitcher(),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Chủ đề',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkPurple,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Bảng giá',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkPurple,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Liên hệ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkPurple,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _selectedPersona == null ? null : _onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  minimumSize: const Size(140, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Bắt đầu',
                    style: TextStyle(color: AppColors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _personaCardDesktop(Persona persona) {
    final isSelected = _selectedPersona == persona;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedPersona = persona);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: persona.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(persona.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              persona.displayNameVi,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: persona.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== MOBILE (unchanged) ===================
  Widget _buildMobile() {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildMascot(),
            const SizedBox(height: 16),
            Text(
              l10n.welcomeGreeting,
              style: Theme.of(context).textTheme.displayLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.welcomeSubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.welcomeSelectPersona,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            _buildPersonaGrid(),
            const SizedBox(height: 24),
            _buildLanguageToggle(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _selectedPersona == null ? null : _onStart,
              child: Text(l10n.welcomeTitle),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _onParentAccess,
              child: Text(
                l10n.welcomeParentAccess,
                style: const TextStyle(color: AppColors.mutedPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascot() {
    return ScaleTransition(
      scale: _mascotAnimation,
      child: Container(
        width: 160,
        height: 160,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryPink,
        ),
        child: const Center(
          child: Text('🐸', style: TextStyle(fontSize: 80)),
        ),
      ),
    );
  }

  Widget _buildPersonaGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _personaCardMobile(Persona.achiever),
            const SizedBox(width: 16),
            _personaCardMobile(Persona.gamer),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _personaCardMobile(Persona.struggler),
            const SizedBox(width: 16),
            _personaCardMobile(Persona.silent),
          ],
        ),
      ],
    );
  }

  Widget _personaCardMobile(Persona persona) {
    final isSelected = _selectedPersona == persona;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedPersona = persona);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: persona.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(persona.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              persona.displayNameVi,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: persona.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return const LanguageSwitcher();
  }

  void _onStart() async {
    if (_selectedPersona == null) return;

    ref.read(personaProvider.notifier).state = _selectedPersona!;
    final locale = ref.read(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    final userNotifier = ref.read(userProvider.notifier);
    try {
      await userNotifier.createUser(
        name: l10n.homeDefaultName,
        persona: _selectedPersona!,
        locale: locale.toString(),
      );
    } catch (_) {
      // Silently ignore user creation failure; app works offline
    }

    if (mounted) {
      context.go('/assessment');
    }
  }

  void _onParentAccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Danh cho phu huynh'),
        content: const Text(
          'Vui long nhap nam sinh de truy cap khu vuc phu huynh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

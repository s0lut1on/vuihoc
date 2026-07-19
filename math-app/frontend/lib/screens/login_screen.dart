import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/bubble_button.dart';
import '../widgets/mascot.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth > 900) return _buildDesktop(l10n);
            return _buildMobile(l10n);
          },
        ),
      ),
    );
  }

  Widget _buildMobile(AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: FadeTransition(
          opacity: _animController,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const BigMascot(size: 160, float_: true),
              const SizedBox(height: 32),
              Text(l10n.welcomeGreeting,
                  textAlign: TextAlign.center,
                  style: AppTheme.display(size: 36)),
              const SizedBox(height: 8),
              Text(l10n.welcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.body(size: 16, color: AppColors.mutedPurple)),
              const SizedBox(height: 40),
              BubbleButton(
                label: l10n.welcomeGoogleSignIn,
                emoji: '🇬',
                onPressed: _isSigningIn ? null : _signInWithGoogle,
                minWidth: 280,
              ),
              const SizedBox(height: 16),
              Row(children: [
                const Expanded(
                    child: Divider(color: AppColors.pinkSoft, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(l10n.welcomeOrDivider,
                      style: AppTheme.body(
                          size: 12, color: AppColors.mutedPurple)),
                ),
                const Expanded(
                    child: Divider(color: AppColors.pinkSoft, thickness: 1)),
              ]),
              const SizedBox(height: 16),
              BubbleButton.secondary(
                label: l10n.welcomeGuestButton,
                emoji: '🐸',
                onPressed: _signInAsGuest,
                minWidth: 280,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktop(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: AppColors.pinkBg,
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 64, vertical: 60),
                child: FadeTransition(
                  opacity: _animController,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const BigMascot(size: 200, float_: true),
                      const SizedBox(height: 40),
                      Text(l10n.welcomeGreeting,
                          textAlign: TextAlign.center,
                          style: AppTheme.display(size: 44)),
                      const SizedBox(height: 8),
                      Text(l10n.welcomeSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTheme.body(
                              size: 16, color: AppColors.mutedPurple)),
                      const SizedBox(height: 48),
                      BubbleButton(
                        label: l10n.welcomeGoogleSignIn,
                        emoji: '🇬',
                        onPressed: _isSigningIn ? null : _signInWithGoogle,
                        minWidth: 320,
                      ),
                      const SizedBox(height: 16),
                      BubbleButton.secondary(
                        label: l10n.welcomeGuestButton,
                        emoji: '🐸',
                        onPressed: _signInAsGuest,
                        minWidth: 320,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.pink.withValues(alpha: 0.10),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🐸', style: TextStyle(fontSize: 200)),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.appTitle, style: AppTheme.display(size: 32)),
                  const SizedBox(height: 8),
                  Text(l10n.welcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTheme.body(
                          size: 16, color: AppColors.mutedPurple)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _signInWithGoogle() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      final ok = await AuthService().signInWithGoogle();
      if (ok && mounted) {
        NotificationService().initialize();
        context.go('/home');
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _signInAsGuest() async {
    final ok = await AuthService().signInAsGuest();
    if (ok && mounted) {
      NotificationService().initialize();
      context.go('/home');
    }
  }
}

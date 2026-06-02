import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
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

  Widget _buildMobile() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildMascot(),
                const SizedBox(height: 32),
                _buildTitle(),
                const SizedBox(height: 40),
                _buildGoogleButton(),
                const SizedBox(height: 16),
                _buildDivider(),
                const SizedBox(height: 16),
                _buildGuestButton(),
                // _buildParentLink(), // Hidden per user request
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktop() {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: AppColors.lightPinkBg,
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 60),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildMascot(size: 200),
                      const SizedBox(height: 40),
                      _buildTitle(desktop: true),
                      const SizedBox(height: 56),
                      _buildGoogleButton(width: 320),
                      const SizedBox(height: 20),
                      _buildDivider(width: 320),
                      const SizedBox(height: 20),
                      _buildGuestButton(width: 320),
                      const SizedBox(height: 40),
                      // _buildParentLink() // Hidden - parent access disabled
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
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryPink.withValues(alpha: 0.1),
                    ),
                    child: const Center(
                      child: Text('🐸', style: TextStyle(fontSize: 120)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)?.appTitle ??
                        'Math Learning Fun',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.welcomeSubtitle ??
                        "Let's learn math together! Choose a learning style.",
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.mutedPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMascot({double size = 140}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryPink,
      ),
      child: Center(
        child: Text('🐸', style: TextStyle(fontSize: size * 0.5)),
      ),
    );
  }

  Widget _buildTitle({bool desktop = false}) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(
          l10n?.loginWelcomeTitle ?? 'Welcome!',
          style: TextStyle(
            fontSize: desktop ? 40 : 28,
            fontWeight: FontWeight.w700,
            color: AppColors.darkPurple,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.loginWelcomeSubtitle ?? 'Choose a way to start learning math',
          style: TextStyle(
            fontSize: desktop ? 18 : 14,
            color: AppColors.mutedPurple,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGoogleButton({double width = 260}) {
    return GestureDetector(
      onTap: _isSigningIn ? null : _signInWithGoogle,
      child: Container(
        width: width,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A000000),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _isSigningIn
              ? [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)?.loginGoogleSignIn ??
                          'Sign in with Google',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ]
              : [
                  const Text('G',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.red)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)?.loginGoogleSignIn ??
                          'Sign in with Google',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildGuestButton({double width = 260}) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton(
      onPressed: _signInAsGuest,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(width, 48),
        side: const BorderSide(color: AppColors.primaryPink, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Text(
        l10n?.loginGuestSignIn ?? 'Continue without signing in',
        key: const Key('guest-login-button'),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryPink,
        ),
      ),
    );
  }

  Widget _buildDivider({double width = 260}) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              l10n?.loginOrDivider ?? 'or',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedPurple,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: AppColors.divider)),
        ],
      ),
    );
  }

  /*
  Widget _buildParentLink() {
    final l10n = AppLocalizations.of(context);
    return TextButton(
      onPressed: _onParentAccess,
      child: Text(
        l10n?.loginParentAccess ?? 'For parents',
        style: const TextStyle(
          color: AppColors.mutedPurple,
          fontSize: 14,
        ),
      ),
    );
  }
  */

  void _signInWithGoogle() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      final success = await AuthService().signInWithGoogle();
      if (success && mounted) {
        context.go('/home');
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  void _signInAsGuest() async {
    final success = await AuthService().signInAsGuest();
    if (success && mounted) {
      context.go('/home');
    }
  }

  /*
  void _onParentAccess() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.loginParentDialogTitle ?? 'For parents'),
        content: Text(
          l10n?.loginParentDialogContent ??
              'Please enter your birth year to access the parent area.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.lessonClose ?? 'Close'),
          ),
        ],
      ),
    );
  }
  */
}

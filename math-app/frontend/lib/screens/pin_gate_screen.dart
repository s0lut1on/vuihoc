import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/mascot.dart';

class PinGateScreen extends StatefulWidget {
  const PinGateScreen({super.key});

  @override
  State<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends State<PinGateScreen> {
  String _pin = '';
  static const String _correctPin = '1234';
  bool _shake = false;

  void _onKeyPressed(String value) {
    HapticFeedback.lightImpact();
    if (_pin.length < 4) {
      setState(() => _pin += value);
      if (_pin.length == 4) {
        _checkPin();
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _checkPin() {
    if (_pin == _correctPin) {
      context.go('/parent-dashboard/main');
    } else {
      setState(() {
        _pin = '';
        _shake = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pinGateWrongPin),
          backgroundColor: AppColors.red,
        ),
      );
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _shake = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.deepPurple,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.close, color: AppColors.white, size: 20),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BigMascot(size: 100, emoji: '👨‍👩‍👧', float_: true),
                    const SizedBox(height: 16),
                    Text(l10n.pinGateTitle,
                        textAlign: TextAlign.center,
                        style:
                            AppTheme.display(size: 26, color: AppColors.white)),
                    const SizedBox(height: 8),
                    Text('Chỉ bố mẹ mới biết nhé!',
                        style:
                            AppTheme.body(size: 14, color: AppColors.pinkSoft)),
                    const SizedBox(height: 32),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      transform: _shake
                          ? (Matrix4.identity()..translate(-8.0, 0, 0))
                          : Matrix4.identity(),
                      curve: Curves.easeInOut,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final filled = index < _pin.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  filled ? AppColors.pink : Colors.transparent,
                              border:
                                  Border.all(color: AppColors.white, width: 2),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildKeypad(l10n),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(AppLocalizations l10n) {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          [l10n.pinGateBack, '0', '←'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((label) => _key(label, l10n)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _key(String label, AppLocalizations l10n) {
    final isAction = label == '←' || label == l10n.pinGateBack;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          if (label == '←') {
            _onBackspace();
          } else if (label == l10n.pinGateBack) {
            context.go('/home');
          } else {
            _onKeyPressed(label);
          }
        },
        child: Container(
          width: 72,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isAction
                ? Colors.transparent
                : AppColors.pink.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.pink.withValues(alpha: isAction ? 0 : 0.4),
                width: 2),
            boxShadow: isAction
                ? null
                : const [
                    BoxShadow(
                        color: AppColors.pinkDark,
                        offset: Offset(0, 4),
                        blurRadius: 0),
                  ],
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: label == '←' ? 26 : 22,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              )),
        ),
      ),
    );
  }
}

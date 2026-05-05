import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_switcher.dart';

class PinGateScreen extends StatefulWidget {
  const PinGateScreen({super.key});

  @override
  State<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends State<PinGateScreen> {
  String _pin = '';
  static const String _correctPin = '1234';

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
      setState(() => _pin = '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pinGateWrongPin),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.darkPurple,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: 16,
              right: 16,
              child: LanguageSwitcher(),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.admin_panel_settings,
                      size: 48, color: AppColors.primaryPink),
                  const SizedBox(height: 24),
                  Text(
                    l10n.pinGateTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < _pin.length
                              ? AppColors.primaryPink
                              : AppColors.white.withValues(alpha: 0.3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 48),
                  _buildKeypad(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          [l10n.pinGateBack, '0', '←'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((label) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 80,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (label == '←') {
                        _onBackspace();
                      } else if (label == l10n.pinGateBack) {
                        context.go('/home');
                      } else {
                        _onKeyPressed(label);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: label == '←' || label == l10n.pinGateBack
                          ? Colors.transparent
                          : AppColors.lightPinkBg.withValues(alpha: 0.2),
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: label == '←' ? 24 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

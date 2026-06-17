import 'package:flutter/material.dart';

/// Kid-friendly palette inspired by the Hoc Vui design system.
/// Hot pink, candy pastels, playful purples. Designed for ages 5-7.
class AppColors {
  AppColors._();

  // Brand
  static const Color pink = Color(0xFFFF6B9D);
  static const Color pinkDark = Color(0xFFC0266B);
  static const Color pinkSoft = Color(0xFFFFE0EC);
  static const Color pinkBg = Color(0xFFFFF5FA);

  // Purple
  static const Color deepPurple = Color(0xFF2D1B4E);
  static const Color mutedPurple = Color(0xFF6B5B95);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleDark = Color(0xFF5B21B6);

  // Backgrounds
  static const Color cream = Color(0xFFFFF8E1);
  static const Color warmCream = Color(0xFFFFF8E1);
  static const Color sky = Color(0xFFE0F2FE);
  static const Color skyBlue = Color(0xFFA5D8FF);
  static const Color grayBg = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE9D5FF);

  // Status
  static const Color green = Color(0xFF22C55E);
  static const Color greenSoft = Color(0xFFDCFCE7);
  static const Color orange = Color(0xFFFF9A3D);
  static const Color orangeSoft = Color(0xFFFFF3E0);
  static const Color orangeText = Color(0xFFE65100);
  static const Color yellow = Color(0xFFFDE047);
  static const Color red = Color(0xFFEF4444);
  static const Color mint = Color(0xFF86EFAC);

  // Persona
  static const Color achieverBg = Color(0xFFFFF3E0);
  static const Color achieverText = Color(0xFFE65100);
  static const Color gamerBg = Color(0xFFE8F5E9);
  static const Color gamerText = Color(0xFF2E7D32);
  static const Color gamerGreen = Color(0xFF2E7D32);
  static const Color strugglerBg = Color(0xFFE3F2FD);
  static const Color strugglerText = Color(0xFF1565C0);
  static const Color silentBg = Color(0xFFF3E5F5);
  static const Color silentText = Color(0xFF7B1FA2);

  // Backwards-compat aliases (pre-rename). Keep until callers are migrated.
  static const Color primaryPink = pink;
  static const Color darkPurple = deepPurple;
  static const Color lightPinkBg = pinkBg;
  static const Color mutedPurpleLegacy = mutedPurple;
  static const Color warmCreamLegacy = cream;
  static const Color lightBlueBg = sky;
  static const Color grayBgLegacy = grayBg;
  static const Color darkText = Color(0xFF4A4A6A);
  static const Color mutedText = Color(0xFF888888);
  static const Color white = Color(0xFFFFFFFF);
  static const Color successGreen = green;
  static const Color dividerLegacy = divider;
}

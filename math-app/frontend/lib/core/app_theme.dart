import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Kid-friendly design system. Rounded display + body fonts.
/// Big rounded shapes, 3D "bubble" shadows, soft pastel palette.
///
/// Note: previously used the `google_fonts` package (Baloo 2 + Nunito)
/// but it crashes on Flutter 3.44 web due to a FontWeight const-eval bug
/// in the package's const map. Replaced with system font families that
/// are close visual matches: 'Baloo 2' (if installed) → rounded sans,
/// falling back to the platform default rounded sans-serif.
class AppTheme {
  AppTheme._();

  /// Display font: rounded, heavy. Falls back to system sans if the
  /// named family isn't available (Flutter resolves gracefully).
  static const String _displayFamily = 'Baloo 2';
  static const String _bodyFamily = 'Nunito';

  static TextStyle get _display => TextStyle(
        fontFamily: _displayFamily,
        fontWeight: FontWeight.w800,
        color: AppColors.deepPurple,
      );

  static TextStyle get _body => TextStyle(
        fontFamily: _bodyFamily,
        fontWeight: FontWeight.w600,
        color: AppColors.deepPurple,
      );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.pink,
        secondary: AppColors.purple,
        surface: AppColors.deepPurple,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.pink,
        secondary: AppColors.purple,
        surface: AppColors.pinkBg,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.deepPurple,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.pinkBg,
      textTheme: base.textTheme.apply(
        fontFamily: _bodyFamily,
        bodyColor: AppColors.deepPurple,
        displayColor: AppColors.deepPurple,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.deepPurple),
        titleTextStyle: _display.copyWith(fontSize: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: AppColors.white,
          minimumSize: const Size(140, 52),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: _body.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          elevation: 0,
        ).copyWith(
          // 3D press: shadow + translate on press
          backgroundColor:
              WidgetStateProperty.resolveWith<Color>((s) => AppColors.pink),
          shadowColor:
              WidgetStateProperty.resolveWith<Color>((s) => AppColors.pinkDark),
          elevation: WidgetStateProperty.resolveWith<double>(
              (s) => s.contains(WidgetState.pressed) ? 2 : 6),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepPurple,
          minimumSize: const Size(140, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: _body.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
          side: const BorderSide(color: AppColors.divider, width: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.deepPurple,
          textStyle: _body.copyWith(fontSize: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.pink, width: 2),
        ),
        hintStyle: TextStyle(
            fontFamily: _bodyFamily,
            color: AppColors.mutedText,
            fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.pink,
        linearTrackColor: AppColors.divider,
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.divider, thickness: 1),
    );
  }

  /// Build a display text style.
  static TextStyle display(
      {double size = 28, FontWeight weight = FontWeight.w800, Color? color}) {
    return _display.copyWith(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.deepPurple);
  }

  /// Build a body text style.
  static TextStyle body(
      {double size = 16, FontWeight weight = FontWeight.w600, Color? color}) {
    return _body.copyWith(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.deepPurple);
  }
}
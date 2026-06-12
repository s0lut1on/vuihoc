import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:math_app/l10n/app_localizations.dart';
import 'package:math_app/screens/welcome_screen.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  Widget localizedApp(Widget home) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('vi')],
        locale: const Locale('vi'),
        home: home,
      ),
    );
  }

  testWidgets('WelcomeScreen renders mascot and welcome text',
      (WidgetTester tester) async {
    await tester.pumpWidget(localizedApp(const WelcomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Xin chào, bé yêu!'), findsOneWidget);
    expect(find.text('Hãy cùng học vui nhé! Chọn cách học của bé.'),
        findsOneWidget);
    expect(find.textContaining('🐸'), findsOneWidget);
  });

  testWidgets('WelcomeScreen shows 4 persona cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(localizedApp(const WelcomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Học giỏi'), findsOneWidget);
    expect(find.text('Thích chơi game'), findsOneWidget);
    expect(find.text('Cần động viên'), findsOneWidget);
    expect(find.text('Nhút nhát'), findsOneWidget);
  });

  testWidgets('Start button is disabled until persona selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(localizedApp(const WelcomeScreen()));
    await tester.pumpAndSettle();

    final buttonFinder = find.widgetWithText(ElevatedButton, 'Bắt đầu học!');
    expect(buttonFinder, findsOneWidget);

    final button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNull);
  });

  testWidgets('LanguageSwitcher widget is present',
      (WidgetTester tester) async {
    await tester.pumpWidget(localizedApp(const WelcomeScreen()));
    await tester.pumpAndSettle();

    // LanguageSwitcher should be present as a widget (flag emoji text)
    expect(find.text('🇻🇳'), findsOneWidget);
  });
}

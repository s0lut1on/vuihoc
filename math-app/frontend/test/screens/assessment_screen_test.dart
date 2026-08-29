import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:math_app/l10n/app_localizations.dart';
import 'package:math_app/screens/assessment_screen.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('AssessmentScreen renders first question and options',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('vi')],
          locale: const Locale('vi'),
          home: const AssessmentScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Screen is rendered
    expect(find.byType(AssessmentScreen), findsOneWidget);

    // Progress bar is visible
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // At least 3 option cards visible (first question has 3 options)
    expect(find.byType(GestureDetector), findsAtLeast(3));
  });

  testWidgets('AssessmentScreen shows question icon and text',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('vi')],
          locale: const Locale('vi'),
          home: const AssessmentScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // First question icon (🔢) should be visible
    expect(find.text('🔢'), findsOneWidget);

    // Close button (X icon) should be visible
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('AssessmentScreen advances to next question on tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('vi')],
          locale: const Locale('vi'),
          home: const AssessmentScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // First question icon is 🔢
    expect(find.text('🔢'), findsOneWidget);

    // Tap first option (🔟 — "Đếm đến 10")
    await tester.tap(find.text('🔟'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    // Should advance to second question (icon 🔤)
    expect(find.text('🔤'), findsOneWidget);
  });

  testWidgets('AssessmentScreen shows skip button after answering',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('vi')],
          locale: const Locale('vi'),
          home: const AssessmentScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // No skip TextButton before answering
    expect(find.byType(TextButton), findsNothing);

    // Tap first option
    await tester.tap(find.text('🔟'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    // After advancing to Q2, skip button should be visible (answeredCount > 0)
    expect(find.byType(TextButton), findsOneWidget);
  });

  testWidgets('AssessmentScreen renders with English locale',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('vi')],
          locale: const Locale('en'),
          home: const AssessmentScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Screen renders without crashing in English
    expect(find.byType(AssessmentScreen), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
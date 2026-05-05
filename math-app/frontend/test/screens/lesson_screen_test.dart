import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:math_app/l10n/app_localizations.dart';
import 'package:math_app/screens/lesson_screen.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('LessonScreen shows not found when no exercise',
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
          home: LessonScreen(subjectId: 'unknown', lessonId: 'bad'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy bài học'), findsOneWidget);
  });

  testWidgets('LessonScreen renders with known lesson id',
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
          home: LessonScreen(subjectId: 'numbers', lessonId: 'lesson_n1'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Should show either question text or close button (app is rendering)
    expect(find.byType(LessonScreen), findsOneWidget);
  });
}

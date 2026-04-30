import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_app/screens/lesson_screen.dart';

void main() {
  testWidgets('LessonScreen shows loading initially',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: LessonScreen(subjectId: 'numbers', lessonId: 'l1'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('LessonScreen shows not found when no exercise',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: LessonScreen(subjectId: 'unknown', lessonId: 'bad'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Không tìm thấy bài học'), findsOneWidget);
  });
}

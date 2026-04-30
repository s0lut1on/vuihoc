import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/screens/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen renders mascot and welcome text',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const WelcomeScreen(),
        ),
      ),
    );

    expect(find.text('Xin chào, bé yêu!'), findsOneWidget);
    expect(find.text('Hãy cùng học Toán vui nhé!'), findsOneWidget);
    expect(find.textContaining('🐸'), findsOneWidget);
  });

  testWidgets('WelcomeScreen shows 4 persona cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const WelcomeScreen(),
        ),
      ),
    );

    expect(find.text('Học giỏi'), findsOneWidget);
    expect(find.text('Thích chơi game'), findsOneWidget);
    expect(find.text('Cần động viên'), findsOneWidget);
    expect(find.text('Nhút nhát'), findsOneWidget);
  });

  testWidgets('Start button is disabled until persona selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const WelcomeScreen(),
        ),
      ),
    );

    final buttonFinder = find.widgetWithText(ElevatedButton, 'Bắt đầu học!');
    expect(buttonFinder, findsOneWidget);

    final button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNull);
  });

  testWidgets('Language toggle switches between vi and en',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const WelcomeScreen(),
        ),
      ),
    );

    expect(find.text('🇻🇳'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);

    await tester.ensureVisible(find.text('🇻🇳'));
    await tester.tap(find.text('🇻🇳'));
    await tester.pumpAndSettle();

    expect(find.text('🇬🇧'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });
}

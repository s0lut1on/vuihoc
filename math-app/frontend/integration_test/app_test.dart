import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:math_app/main.dart' as app;
import 'package:math_app/screens/assessment_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end app test', () {
    testWidgets('full onboarding flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // On WelcomeScreen
      expect(find.text('Xin chao, be yeu!'), findsOneWidget);

      // Select persona
      await tester.tap(find.text('Hoc gioi'));
      await tester.pumpAndSettle();

      // Start learning
      await tester.tap(find.widgetWithText(ElevatedButton, 'Bat dau hoc!'));
      await tester.pumpAndSettle();

      // Should navigate to AssessmentScreen
      expect(find.byType(AssessmentScreen), findsOneWidget);
    });

    testWidgets('language switch flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Xin chao, be yeu!'), findsOneWidget);

      // Tap language toggle
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.text('Hello, little friend!'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/widgets/clock_face.dart';

void main() {
  group('ClockFace.tryParse', () {
    test('returns valid clock for "clock|3|15"', () {
      final clock = ClockFace.tryParse('clock|3|15');
      expect(clock, isNotNull);
      expect(clock!.hour, 3);
      expect(clock.minute, 15);
    });

    test('returns null for non-clock string', () {
      expect(ClockFace.tryParse('hello'), isNull);
    });

    test('returns null for wrong part count', () {
      expect(ClockFace.tryParse('clock|3'), isNull);
      expect(ClockFace.tryParse('clock|3|15|extra'), isNull);
    });

    test('returns null for non-numeric parts', () {
      expect(ClockFace.tryParse('clock|a|b'), isNull);
    });

    test('handles midnight edge case', () {
      final clock = ClockFace.tryParse('clock|0|0');
      expect(clock, isNotNull);
      expect(clock!.hour, 0);
      expect(clock.minute, 0);
    });

    test('handles hour 12 and minute 59', () {
      final clock = ClockFace.tryParse('clock|12|59');
      expect(clock, isNotNull);
      expect(clock!.hour, 12);
      expect(clock.minute, 59);
    });
  });

  group('ClockFace widget', () {
    testWidgets('renders CustomPaint without error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClockFace(hour: 3, minute: 15),
          ),
        ),
      );
      expect(find.byType(ClockFace), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ClockFace),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses correct size', (WidgetTester tester) async {
      const size = 200.0;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClockFace(hour: 10, minute: 30, size: size),
          ),
        ),
      );
      final clock = tester.widget<ClockFace>(find.byType(ClockFace));
      expect(clock.size, size);
    });
  });
}

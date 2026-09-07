import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/l10n/app_localizations.dart';
import 'package:math_app/widgets/matching_exercise.dart';
import 'package:math_app/widgets/ordering_exercise.dart';
import 'package:math_app/widgets/text_input_widget.dart';

Widget _wrap(Widget child) {
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
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('MatchingExercise', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        _wrap(MatchingExercise(
          exercise: {
            'options': ['1', '2', 'one', 'two'],
            'question_vi': 'Ghép đôi',
          },
          onAnswered: (_) {},
        )),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MatchingExercise), findsOneWidget);
    });

    testWidgets('shows left and right options', (tester) async {
      await tester.pumpWidget(
        _wrap(MatchingExercise(
          exercise: {
            'options': ['cat', 'dog', 'mèo', 'chó'],
            'question_vi': 'Ghép đôi',
          },
          onAnswered: (_) {},
        )),
      );
      await tester.pumpAndSettle();
      expect(find.text('cat'), findsOneWidget);
      expect(find.text('dog'), findsOneWidget);
      expect(find.textContaining('mèo'), findsOneWidget);
      expect(find.textContaining('chó'), findsOneWidget);
    });

    testWidgets('shows invalid message for odd options', (tester) async {
      await tester.pumpWidget(
        _wrap(MatchingExercise(
          exercise: {
            'options': ['a', 'b', 'c'],
          },
          onAnswered: (_) {},
        )),
      );
      await tester.pumpAndSettle();
      expect(find.text('Invalid matching exercise'), findsOneWidget);
    });
  });

  group('OrderingExercise', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        _wrap(OrderingExercise(
          exercise: {
            'options': ['I', 'am', 'happy'],
            'question_vi': 'Sắp xếp câu',
          },
          onAnswered: (_) {},
        )),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OrderingExercise), findsOneWidget);
    });

    testWidgets('shows word pool', (tester) async {
      await tester.pumpWidget(
        _wrap(OrderingExercise(
          exercise: {
            'options': ['hello', 'world'],
            'question_vi': 'Sắp xếp',
          },
          onAnswered: (_) {},
        )),
      );
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
      expect(find.text('world'), findsOneWidget);
    });
  });

  group('TextInputWidget', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        _wrap(TextInputWidget(
          exerciseId: 'ex1',
          expectedText: 'hello',
          hintVi: 'Gõ từ hello',
          hintEn: 'Type hello',
          diacriticSensitive: false,
          validationMode: 'exact',
          onAnswered: (_) {},
        )),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextInputWidget), findsOneWidget);
    });

    testWidgets('shows text input field', (tester) async {
      await tester.pumpWidget(
        _wrap(TextInputWidget(
          exerciseId: 'ex1',
          expectedText: 'chào',
          hintVi: 'Gõ từ chào',
          hintEn: 'Type chao',
          diacriticSensitive: true,
          validationMode: 'exact',
          onAnswered: (_) {},
        )),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
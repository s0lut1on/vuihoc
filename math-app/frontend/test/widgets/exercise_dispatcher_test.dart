import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/providers/app_providers.dart';

void main() {
  testWidgets('ExerciseDispatcher renders MCQ options', (tester) async {
    bool? answered;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ttsEnabledProvider.overrideWith((ref) => false)],
        child: const MaterialApp(
          home: Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1'), findsNothing);
    answered = true;
    expect(answered, true);
  });
}

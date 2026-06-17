import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/l10n/app_localizations.dart';
import 'package:math_app/widgets/paywall_modal.dart';

void main() {
  Widget buildModal({required VoidCallback onClose}) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      locale: const Locale('vi'),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => PaywallModal(onClose: onClose),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('PaywallModal renders title and description',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildModal(onClose: () {}));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Bạn đã học đủ bài hôm nay'), findsOneWidget);
    expect(
        find.textContaining('Tài khoản miễn phí được học tối đa 50 bài'), findsOneWidget);
  });

  testWidgets('PaywallModal has close and understand buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildModal(onClose: () {}));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Đã hiểu'), findsOneWidget);
    expect(find.text('Đóng'), findsOneWidget);
  });

  testWidgets('tapping Close calls onClose', (WidgetTester tester) async {
    int counter = 0;
    await tester.pumpWidget(buildModal(onClose: () => counter++));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(counter, 1);
  });

  testWidgets('tapping Got it calls onClose', (WidgetTester tester) async {
    int counter = 0;
    await tester.pumpWidget(buildModal(onClose: () => counter++));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đã hiểu'));
    await tester.pumpAndSettle();
    expect(counter, 1);
  });
}

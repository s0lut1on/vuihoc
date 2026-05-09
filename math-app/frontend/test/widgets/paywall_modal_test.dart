import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/widgets/paywall_modal.dart';

void main() {
  Widget buildModal({required VoidCallback onClose}) {
    return MaterialApp(
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
    expect(find.textContaining('Tài khoản miễn phí'), findsOneWidget);
  });

  testWidgets('PaywallModal has close and understand buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildModal(onClose: () {}));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Đã hiểu'), findsOneWidget);
    expect(find.text('Đóng'), findsOneWidget);
  });

  testWidgets('tapping Đóng calls onClose', (WidgetTester tester) async {
    int counter = 0;
    await tester.pumpWidget(buildModal(onClose: () => counter++));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(counter, 1);
  });

  testWidgets('tapping Đã hiểu calls onClose', (WidgetTester tester) async {
    int counter = 0;
    await tester.pumpWidget(buildModal(onClose: () => counter++));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Đã hiểu'));
    await tester.pumpAndSettle();
    expect(counter, 1);
  });
}

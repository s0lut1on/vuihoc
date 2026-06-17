import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../lib/widgets/offline_banner.dart';
import '../../lib/l10n/app_localizations.dart';

void main() {
  Widget localizedApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: child,
    );
  }

  testWidgets('OfflineBanner shows offline message', (tester) async {
    await tester
        .pumpWidget(localizedApp(const Scaffold(body: OfflineBanner())));
    await tester.pumpAndSettle();

    expect(find.textContaining('offline'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
  });

  testWidgets('OfflineBanner uses MaterialBanner', (tester) async {
    await tester
        .pumpWidget(localizedApp(const Scaffold(body: OfflineBanner())));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialBanner), findsOneWidget);
  });
}

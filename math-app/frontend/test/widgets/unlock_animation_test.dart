import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../lib/widgets/unlock_animation_overlay.dart';
import '../../lib/l10n/app_localizations.dart';

Widget _wrapped(Widget child) {
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

void main() {
  testWidgets('UnlockAnimationOverlay shows unlock text and dismisses', (tester) async {
    bool dismissed = false;

    await tester.pumpWidget(_wrapped(
      UnlockAnimationOverlay(
        titleVi: 'Số học',
        titleEn: 'Numbers',
        accentColor: Colors.blue,
        onDismiss: () => dismissed = true,
      ),
    ));
    await tester.pump();

    expect(find.textContaining('Unlocked'), findsOneWidget);
    expect(find.textContaining('Tap to continue'), findsOneWidget);
    expect(dismissed, false);

    await tester.tap(find.byType(UnlockAnimationOverlay));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    expect(dismissed, true);
  });

  testWidgets('UnlockAnimationOverlay auto-dismisses after timeout', (tester) async {
    bool dismissed = false;

    await tester.pumpWidget(_wrapped(
      UnlockAnimationOverlay(
        titleVi: 'Hình học',
        titleEn: 'Geometry',
        accentColor: Colors.green,
        onDismiss: () => dismissed = true,
      ),
    ));
    await tester.pump();

    expect(dismissed, false);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 100));

    expect(dismissed, true);
  });
}

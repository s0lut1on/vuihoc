import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/l10n/app_localizations.dart';
import 'package:math_app/services/api_service.dart';
import 'package:math_app/widgets/profile_widget.dart';
import '../helpers/mock_dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget localizedApp(Widget child) {
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

  group('ProfileWidget', () {
    setUp(() {
      final mockDio = createMockDio(mockAuthResponse());
      ApiService().initialize(dio: mockDio);
    });

    testWidgets('renders avatar and name when user is loaded', (tester) async {
      await tester.pumpWidget(localizedApp(const ProfileWidget()));
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('Bé Test'), findsOneWidget);
    });

    testWidgets('tap opens dropdown menu with profile/settings/logout',
        (tester) async {
      await tester.pumpWidget(localizedApp(const ProfileWidget()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ProfileWidget));
      await tester.pumpAndSettle();

      expect(find.text('Hồ sơ'), findsOneWidget);
      expect(find.text('Cài đặt'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
    });

    testWidgets('logout item has red color', (tester) async {
      await tester.pumpWidget(localizedApp(const ProfileWidget()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ProfileWidget));
      await tester.pumpAndSettle();

      final logoutText = tester.widget<Text>(find.text('Đăng xuất'));
      expect((logoutText.style?.color), Colors.red);
    });
  });
}

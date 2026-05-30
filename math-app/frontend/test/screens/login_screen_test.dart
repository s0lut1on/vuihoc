import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:math_app/l10n/app_localizations.dart';
import 'package:math_app/screens/login_screen.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_login_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  Widget localizedApp(Widget home) {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => home),
        GoRoute(
            path: '/welcome',
            builder: (_, __) => const Scaffold(body: Text('Welcome Page'))),
        GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: Text('Home Page'))),
      ],
    );

    return ProviderScope(
      child: MaterialApp.router(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('vi')],
        locale: const Locale('vi'),
        routerDelegate: router.routerDelegate,
        routeInformationParser: router.routeInformationParser,
        routeInformationProvider: router.routeInformationProvider,
      ),
    );
  }

  testWidgets('LoginScreen renders mascot and title',
      (WidgetTester tester) async {
    await tester.pumpWidget(localizedApp(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('🐸'), findsOneWidget);
    expect(find.text('Chào mừng bạn!'), findsOneWidget);
    expect(find.text('Hãy chọn cách để bắt đầu học toán nhé'), findsOneWidget);
  });

  testWidgets('LoginScreen shows Google Sign-In button',
      (WidgetTester tester) async {
    await tester.pumpWidget(localizedApp(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập với Google'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
  });

  testWidgets('LoginScreen shows guest login button',
      (WidgetTester tester) async {
    await tester.pumpWidget(localizedApp(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Tiếp tục không đăng nhập'), findsOneWidget);
  });

  testWidgets('LoginScreen shows divider text', (WidgetTester tester) async {
    await tester.pumpWidget(localizedApp(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('hoặc'), findsOneWidget);
  });
}

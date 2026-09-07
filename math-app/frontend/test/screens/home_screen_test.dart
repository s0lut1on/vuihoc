import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:math_app/l10n/app_localizations.dart';
import 'package:math_app/screens/home_screen.dart';

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
      home: child,
    ),
  );
}

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_home_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('HomeScreen renders without crashing', (tester) async {
    setViewport(tester);
    await tester.pumpWidget(_wrap(const HomeScreen()));
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (_) {}
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('HomeScreen shows app title in nav bar', (tester) async {
    setViewport(tester);
    await tester.pumpWidget(_wrap(const HomeScreen()));
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (_) {}
    expect(find.text('Học Vui'), findsOneWidget);
  });

  testWidgets('HomeScreen shows subject section heading', (tester) async {
    setViewport(tester);
    await tester.pumpWidget(_wrap(const HomeScreen()));
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (_) {}
    expect(find.textContaining('Chủ đề'), findsWidgets);
  });

  testWidgets('HomeScreen shows continue card button', (tester) async {
    setViewport(tester);
    await tester.pumpWidget(_wrap(const HomeScreen()));
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (_) {}
    expect(find.textContaining('Học tiếp'), findsOneWidget);
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/app_theme.dart';
import 'core/app_router.dart';
import 'providers/app_providers.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  ApiService().initialize();

  final storedLocale = await _loadLocale();
  final token = await _loadToken();
  if (token != null) {
    ApiService().setToken(token);
  }

  final didAutoSignIn =
      token != null ? await AuthService().silentSignIn() : false;

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => storedLocale),
      ],
      child: MathApp(autoSignedIn: didAutoSignIn, locale: storedLocale),
    ),
  );
}

Future<Locale> _loadLocale() async {
  final box = await Hive.openBox('settings');
  final locale = box.get('locale', defaultValue: 'vi_VN') as String;
  if (locale == 'en_US') return const Locale('en', 'US');
  return const Locale('vi', 'VN');
}

Future<String?> _loadToken() async {
  final box = await Hive.openBox('auth');
  return box.get('token') as String?;
}

class MathApp extends StatelessWidget {
  final bool autoSignedIn;
  final Locale locale;

  const MathApp({
    super.key,
    this.autoSignedIn = false,
    this.locale = const Locale('vi', 'VN'),
  });

  @override
  Widget build(BuildContext context) {
    final router = AppRouter(initialSignedIn: autoSignedIn);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Math Learning App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}

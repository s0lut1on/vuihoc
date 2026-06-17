import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/app_theme.dart';
import 'core/app_router.dart';
import 'providers/app_providers.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('offline_cache');
  await Hive.openBox('pending_sync');
  ConnectivityService().init();

  final storedLocale = await _loadLocale();
  final ttsEnabled = await _loadTtsEnabled();
  var token = await _loadToken();

  // Screenshot/demo mode: bypass auth when URL contains ?demo=true.
  // Useful for taking screenshots of protected screens without a backend.
  if (token == null && _isDemoMode()) {
    token = 'demo-token-no-network';
    ApiService().setToken(token);
    AuthService().tokenNotifier.value = token;
  }

  if (token != null) {
    ApiService().setToken(token);
    AuthService().tokenNotifier.value = token;
  }

  final didAutoSignIn =
      token != null ? await AuthService().silentSignIn() : false;

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => storedLocale),
        ttsEnabledProvider.overrideWith((ref) => ttsEnabled),
      ],
      child: MathApp(autoSignedIn: didAutoSignIn),
    ),
  );
}

bool _isDemoMode() {
  if (!kIsWeb) return false;
  // ignore: avoid_web_libraries_in_flutter
  return Uri.base.queryParameters.containsKey('demo');
}

Future<Locale> _loadLocale() async {
  final box = await Hive.openBox('settings');
  final locale = box.get('locale', defaultValue: 'vi') as String;
  if (locale.startsWith('en')) return const Locale('en', 'GB');
  return const Locale('vi', 'VN');
}

Future<String?> _loadToken() async {
  final box = await Hive.openBox('auth');
  return box.get('token') as String?;
}

Future<bool> _loadTtsEnabled() async {
  final box = await Hive.openBox('settings');
  return box.get('ttsEnabled', defaultValue: true) as bool;
}

class MathApp extends ConsumerStatefulWidget {
  final bool autoSignedIn;

  const MathApp({
    super.key,
    this.autoSignedIn = false,
  });

  @override
  ConsumerState<MathApp> createState() => _MathAppState();
}

class _MathAppState extends ConsumerState<MathApp> {
  late final AppRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter(initialSignedIn: widget.autoSignedIn);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    // Auto-extract user_id from /auth/me so guest users also get a userId
    ref.listen(currentUserProvider, (prev, next) {
      final userData = next.valueOrNull;
      final userId = userData?['id'] as String?;
      if (userId != null && userId.isNotEmpty) {
        ref.read(userIdProvider.notifier).state = userId;
      }
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Learning Fun',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerDelegate: _router.routerDelegate,
      routeInformationParser: _router.routeInformationParser,
      routeInformationProvider: _router.routeInformationProvider,
    );
  }
}

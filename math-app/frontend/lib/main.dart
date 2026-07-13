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
import 'services/local_storage_service.dart';
import 'l10n/app_localizations.dart';
import 'data/pricing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phase 2: defer slow I/O so the first frame paints sooner.
  //
  // Before: sequential awaits for PricingConfig, Hive init+openBox (×2),
  // 3 Hive reads, and silentSignIn all block runApp. ~200-400ms added
  // before the first frame.
  //
  // After: PricingConfig is awaited (needed for the pricing screen to
  // render). Hive init + openBox run in parallel via unawaited Future.
  // tokenNotifier is set from the loaded token so the router sees the
  // user as signed-in immediately. silentSignIn validates the token
  // in the background and updates auth state if the token is invalid.
  //
  // Trade-off: a user with a stale token might briefly see /home
  // before being redirected to /login when silentSignIn completes.
  // This is a few-frame flash at most — acceptable for the startup
  // time savings.
  await PricingConfig.load();

  // Fire-and-forget Hive init + non-essential box opens. These run
  // in parallel with runApp. The settings/auth boxes are opened
  // lazily on first use by _loadLocale/_loadToken/etc.
  unawaited(_initHive());

  // Load the token from the auth box. This also sets it on the ApiService
  // so the first API calls after runApp have the auth header.
  final token = await _loadToken();

  // Demo mode bypass for screenshots.
  if (token == null && _isDemoMode()) {
    AuthService().tokenNotifier.value = 'demo-token-no-network';
    ApiService().setToken('demo-token-no-network');
  } else if (token != null) {
    AuthService().tokenNotifier.value = token;
    ApiService().setToken(token);
    // currentUserProvider (in app_providers.dart) is a FutureProvider
    // that calls /api/auth/me when first watched (typically from the
    // home screen). It handles the initial auth validation. We do NOT
    // call silentSignIn here because that would cause a duplicate
    // /me call. The token refresh timer is set up lazily by the
    // ApiService interceptor on the first 401 response.
  }

  // Load the remaining settings (fast Hive reads) for the provider
  // overrides. These run synchronously because runApp needs the
  // values to set up ProviderScope overrides.
  final storedLocale = await _loadLocale();
  final ttsEnabled = await _loadTtsEnabled();
  final unlockAnimEnabled =
      await LocalStorageService.getUnlockAnimationsEnabled();

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => storedLocale),
        ttsEnabledProvider.overrideWith((ref) => ttsEnabled),
        unlockAnimationsEnabledProvider
            .overrideWith((ref) => unlockAnimEnabled),
      ],
      child: const MathApp(),
    ),
  );
}

/// Hive init + non-essential box opens. Runs in the background after
/// runApp. The settings + auth boxes open lazily on first use.
Future<void> _initHive() async {
  try {
    await Hive.initFlutter();
    await Hive.openBox('offline_cache');
    await Hive.openBox('pending_sync');
    ConnectivityService().init();
  } catch (e) {
    // Hive init failure shouldn't crash the app — the boxes that fail
    // to open will throw on first use. Log and continue.
    debugPrint('Hive init failed: $e');
  }
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
  const MathApp({super.key});

  @override
  ConsumerState<MathApp> createState() => _MathAppState();
}

class _MathAppState extends ConsumerState<MathApp> {
  late final AppRouter _router;

  @override
  void initState() {
    super.initState();
    // tokenNotifier is set in main() before runApp, so initialSignedIn
    // just reflects whether a token is present. silentSignIn runs
    // in the background and will update auth state if the token is
    // invalid.
    _router = AppRouter(initialSignedIn: AuthService().tokenNotifier.value != null);
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

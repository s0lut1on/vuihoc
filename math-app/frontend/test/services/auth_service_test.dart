import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:math_app/services/api_service.dart';
import 'package:math_app/services/auth_service.dart';

class MockDioAdapter extends Mock implements HttpClientAdapter {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  late AuthService authService;
  late MockDioAdapter mockAdapter;
  late Dio testDio;

  setUp(() async {
    authService = AuthService();
    mockAdapter = MockDioAdapter();
    testDio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
    testDio.httpClientAdapter = mockAdapter;

    ApiService().initialize(dio: testDio);

    final tempDir = await Directory.systemTemp.createTemp('hive_auth_test');
    Hive.init(tempDir.path);

    // Mock google_sign_in platform channel
    const channel = MethodChannel('plugins.flutter.io/google_sign_in');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'init') return null;
      if (call.method == 'signInSilently') return null;
      if (call.method == 'signOut') return null;
      if (call.method == 'isSignedIn') return false;
      return null;
    });
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    const channel = MethodChannel('plugins.flutter.io/google_sign_in');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AuthService', () {
    test('signInAsGuest returns true and stores token on success', () async {
      final response = {
        'success': true,
        'data': {
          'access_token': 'guest-token-abc',
          'token_type': 'Bearer',
          'expires_in': 31536000,
        }
      };

      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(response),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );

      final result = await authService.signInAsGuest();
      expect(result, true);
      expect(await authService.isSignedIn(), true);
    });

    test('signInAsGuest returns false on API failure', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({'success': false, 'error': 'Server error'}),
          500,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );

      final result = await authService.signInAsGuest();
      expect(result, false);
      expect(await authService.isSignedIn(), false);
    });

    test('signOut clears token and returns not signed in', () async {
      final response = {
        'success': true,
        'data': {
          'access_token': 'guest-token-abc',
          'token_type': 'Bearer',
          'expires_in': 31536000,
        }
      };

      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(response),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );

      await authService.signInAsGuest();
      expect(await authService.isSignedIn(), true);

      await authService.signOut();
      expect(await authService.isSignedIn(), false);
    });

    test('silentSignIn returns true when token is stored', () async {
      final response = {
        'success': true,
        'data': {
          'access_token': 'guest-token-abc',
          'token_type': 'Bearer',
          'expires_in': 31536000,
        }
      };

      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(response),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );

      await authService.signInAsGuest();

      // silentSignIn should find the stored token
      final result = await authService.silentSignIn();
      expect(result, true);
    });

    test('silentSignIn returns false when no token stored', () async {
      final result = await authService.silentSignIn();
      expect(result, false);
    });

    test('getCurrentUser returns user data on success', () async {
      final meResponse = {
        'success': true,
        'data': {
          'id': 'user-123',
          'email': 'test@example.com',
          'name': 'Test User',
          'picture': 'https://example.com/pic.jpg',
          'given_name': 'Test',
        }
      };

      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(meResponse),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );

      final user = await authService.getCurrentUser();
      expect(user, isNotNull);
      expect(user?['name'], 'Test User');
      expect(user?['email'], 'test@example.com');
    });

    test('getCurrentUser returns null on failure', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({'success': false, 'error': 'Unauthorized'}),
          401,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );

      final user = await authService.getCurrentUser();
      expect(user, isNull);
    });

    test('refreshTokenSilently for guest re-issues /auth/guest and persists new token', () async {
      // First call: initial guest sign-in
      var callCount = 0;
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async {
          callCount++;
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'access_token': 'guest-token-$callCount',
                'token_type': 'Bearer',
                'expires_in': 31536000,
              }
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        },
      );

      await authService.signInAsGuest();
      expect(ApiService().token, 'guest-token-1');

      final refreshed = await authService.refreshTokenSilently();
      expect(refreshed, 'guest-token-2');
      expect(ApiService().token, 'guest-token-2');
      expect(callCount, greaterThanOrEqualTo(2));
    });

    test('refreshTokenSilently returns null when refresh fails', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({'success': false, 'error': 'Server error'}),
          500,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );

      await authService.signInAsGuest();
      final refreshed = await authService.refreshTokenSilently();
      expect(refreshed, isNull);
    });

    test('concurrent refreshTokenSilently calls coalesce to a single network call', () async {
      var guestCalls = 0;
      // First call: guest sign-in. Subsequent calls: refresh.
      // We block the refresh call on a Completer to verify coalescing.
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async {
          guestCalls++;
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'access_token': 'coalesced-token',
                'token_type': 'Bearer',
                'expires_in': 31536000,
              }
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        },
      );

      await authService.signInAsGuest();
      final callsBefore = guestCalls;

      final results = await Future.wait([
        authService.refreshTokenSilently(),
        authService.refreshTokenSilently(),
        authService.refreshTokenSilently(),
      ]);
      expect(results, ['coalesced-token', 'coalesced-token', 'coalesced-token']);
      // Only one extra /auth/guest call despite three concurrent refreshes.
      expect(guestCalls - callsBefore, 1);
    });

    test('signOut clears token_type from storage', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              'access_token': 'guest-token-abc',
              'token_type': 'Bearer',
              'expires_in': 31536000,
            }
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );

      await authService.signInAsGuest();
      final box = await Hive.openBox('auth');
      expect(box.get('token_type'), 'guest');

      await authService.signOut();
      expect(box.get('token_type'), isNull);
      expect(box.get('token'), isNull);
    });
  });
}

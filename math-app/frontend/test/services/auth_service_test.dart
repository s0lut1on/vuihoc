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
  });
}

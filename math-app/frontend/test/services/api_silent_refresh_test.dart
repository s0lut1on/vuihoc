import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:math_app/services/api_service.dart';
import 'package:math_app/utils/jwt_utils.dart';

class MockDioAdapter extends Mock implements HttpClientAdapter {}

class FakeRequestOptions extends Fake implements RequestOptions {}

/// Build a JWT whose exp is `secondsFromNow` in the future.
String _jwtWithExp(int secondsFromNow) {
  String b64(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + secondsFromNow;
  return '${b64({'alg': 'none'})}.${b64({'sub': 'u1', 'exp': exp})}.sig';
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  group('ApiService silent refresh', () {
    late ApiService api;
    late MockDioAdapter mockAdapter;
    late Dio testDio;

    setUp(() {
      api = ApiService();
      mockAdapter = MockDioAdapter();
      testDio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
      testDio.httpClientAdapter = mockAdapter;
      api.initialize(dio: testDio);
    });

    test('pre-flight does not refresh when token has plenty of time left',
        () async {
      api.setToken(_jwtWithExp(3600));
      var refreshCalls = 0;
      api.setTokenRefresher(() async {
        refreshCalls++;
        return _jwtWithExp(3600);
      });

      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({'success': true, 'data': {}}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        ),
      );

      await api.get('/content/subjects', queryParams: {'grade': 2});
      expect(refreshCalls, 0);
    });

    test('pre-flight skips refresh for /auth/ paths', () async {
      api.setToken(_jwtWithExp(10));
      var refreshCalls = 0;
      api.setTokenRefresher(() async {
        refreshCalls++;
        return _jwtWithExp(3600);
      });

      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {'access_token': 'x'}
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        ),
      );

      await api.post('/auth/guest', data: {});
      expect(refreshCalls, 0);
    });

    test('401 triggers refresh and retries the request once', () async {
      // Fresh token: pre-flight does NOT fire. Only the 401 retry triggers refresh.
      api.setToken(_jwtWithExp(3600));
      var refreshCalls = 0;
      api.setTokenRefresher(() async {
        refreshCalls++;
        api.setToken(_jwtWithExp(3600));
        return _jwtWithExp(3600);
      });

      // First call: 401. Second call (retry): 200.
      var fetchCount = 0;
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async {
          fetchCount++;
          if (fetchCount == 1) {
            return ResponseBody.fromString(
              jsonEncode({'success': false, 'error': 'Token expired'}),
              401,
              headers: {
                Headers.contentTypeHeader: ['application/json']
              },
            );
          }
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {'grade': 2}
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json']
            },
          );
        },
      );

      final result =
          await api.get('/content/subjects', queryParams: {'grade': 2});
      expect(result['success'], true);
      expect(result['data']['grade'], 2);
      expect(refreshCalls, 1);
      expect(fetchCount, 2); // original + one retry
    });

    test('401 retry gives up after one attempt', () async {
      // Fresh token: pre-flight skipped. Server always 401.
      api.setToken(_jwtWithExp(3600));
      var refreshCalls = 0;
      api.setTokenRefresher(() async {
        refreshCalls++;
        api.setToken(_jwtWithExp(3600));
        return _jwtWithExp(3600);
      });

      // Always 401. Should not infinite-loop.
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({'success': false, 'error': 'Token expired'}),
          401,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        ),
      );

      Object? caught;
      try {
        await api.get('/content/subjects', queryParams: {'grade': 2});
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<ApiException>());
      expect(refreshCalls, 1);
    });

    test('no refresh when refresher is null (default)', () async {
      api.setToken(_jwtWithExp(10));
      api.setTokenRefresher(null);

      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({'success': true, 'data': {}}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        ),
      );

      await api.get('/content/subjects', queryParams: {'grade': 2});
      // Just verify no crash and request goes through.
      verify(() => mockAdapter.fetch(any(), any(), any())).called(1);
    });

    test('JwtUtil.isExpiringSoon returns true for expiring-soon token', () {
      final token = _jwtWithExp(30);
      expect(JwtUtil.isExpiringSoon(token), true);
    });
  });
}

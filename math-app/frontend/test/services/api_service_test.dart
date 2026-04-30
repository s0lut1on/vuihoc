import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:math_app/services/api_service.dart';

class MockDioAdapter extends Mock implements HttpClientAdapter {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  late ApiService apiService;
  late MockDioAdapter mockAdapter;
  late Dio testDio;

  setUp(() {
    apiService = ApiService();
    mockAdapter = MockDioAdapter();
    testDio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
    testDio.httpClientAdapter = mockAdapter;

    when(() => mockAdapter.fetch(any(), any(), any()))
        .thenAnswer((_) async => ResponseBody.fromString(
              jsonEncode({'success': true, 'data': {}}),
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            ));

    apiService.initialize(dio: testDio);
  });

  group('ApiService', () {
    test('get returns parsed response', () async {
      final response = {
        'success': true,
        'data': {'lesson_count': 10}
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

      final result = await apiService.get('/content/curriculum');
      expect(result['success'], true);
      expect(result['data']['lesson_count'], 10);
    });

    test('post with data returns success', () async {
      final response = {
        'success': true,
        'data': {'id': 'u1'}
      };

      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(response),
          201,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );

      final result = await apiService.post('/auth/register', data: {
        'email': 'test@example.com',
        'password': '123456',
      });
      expect(result['success'], true);
      expect(result['data']['id'], 'u1');
    });

    test('throws ApiException on error response', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({'success': false, 'error': 'Invalid credentials'}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );

      expect(
        () => apiService.get('/auth/me'),
        throwsA(isA<ApiException>()),
      );
    });

    test('setToken and clearToken work', () {
      apiService.setToken('test-token');
      apiService.clearToken();
      expect(() => apiService.clearToken(), returnsNormally);
    });
  });
}

import 'package:dio/dio.dart';

/// Mock interceptor that intercepts Dio requests and returns predefined responses.
class MockDioInterceptor extends Interceptor {
  final Map<String, dynamic> _responses;

  MockDioInterceptor(this._responses);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    if (_responses.containsKey(path)) {
      final resp = _responses[path];
      handler.resolve(
        Response(
          requestOptions: options,
          data: resp['data'],
          statusCode: resp['statusCode'] ?? 200,
        ),
      );
      return;
    }
    handler.reject(
      DioException(
        requestOptions: options,
        error: 'No mock for $path',
      ),
      true,
    );
  }
}

Dio createMockDio(Map<String, dynamic> responses) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
  dio.interceptors.add(MockDioInterceptor(responses));
  return dio;
}

Map<String, dynamic> mockCurriculumResponse() => {
      '/content/curriculum': {
        'statusCode': 200,
        'data': {
          'success': true,
          'data': [
            {
              'subject_id': 'numbers',
              'subject_vi': 'So hoc',
              'subject_en': 'Numbers',
              'lessons': [
                {
                  'id': 'lesson_001',
                  'title_vi': 'Dem den 10',
                  'title_en': 'Count to 10',
                  'difficulty': 1,
                  'exercises': [
                    {
                      'id': 'ex_001',
                      'question_vi': 'Dem co bao nhieu qua tao?',
                      'question_en': 'How many apples?',
                      'options': ['3', '5', '4'],
                      'correct': 1,
                      'visual': 'apples_5',
                      'hint_vi': 'Hay chi vao tung qua tao va dem!',
                      'hint_en': 'Point at each apple and count!',
                    }
                  ]
                }
              ]
            }
          ]
        }
      }
    };

Map<String, dynamic> mockAuthResponse() => {
      '/auth/register': {
        'statusCode': 200,
        'data': {
          'success': true,
          'data': {
            'access_token': 'fake-token-123',
            'token_type': 'Bearer',
            'expires_in': 86400,
          }
        }
      },
      '/auth/guest': {
        'statusCode': 200,
        'data': {
          'success': true,
          'data': {
            'access_token': 'guest-token-456',
            'token_type': 'Bearer',
            'expires_in': 31536000,
          }
        }
      },
      '/auth/me': {
        'statusCode': 200,
        'data': {
          'success': true,
          'data': {
            'id': 'u-test',
            'email': 'test@example.com',
            'name': 'Be Test',
            'persona': 'achiever',
            'avatar': '🐸',
            'locale': 'vi_VN',
            'created_at': '2024-01-15T00:00:00Z',
          }
        }
      }
    };

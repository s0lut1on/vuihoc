import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:math_app/services/api_service.dart';
import 'package:math_app/services/progress_api.dart';

class MockDioAdapter extends Mock implements HttpClientAdapter {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  late MockDioAdapter mockAdapter;
  late Dio testDio;

  setUp(() {
    mockAdapter = MockDioAdapter();
    testDio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
    testDio.httpClientAdapter = mockAdapter;
    ApiService().initialize(dio: testDio);
  });

  group('ProgressApi.getDailyLimit', () {
    test('returns limit data on success', () async {
      final response = {
        'success': true,
        'data': {
          'count': 5,
          'limit': 50,
          'has_reached_limit': false,
          'tier': 'free'
        }
      };

      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(response),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        ),
      );

      final result = await ProgressApi.getDailyLimit('user-123');
      expect(result, isNotNull);
      expect(result!['count'], 5);
      expect(result['limit'], 50);
      expect(result['has_reached_limit'], false);
    });

    test('returns null on failure', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({'success': false, 'error': 'Server error'}),
          500,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        ),
      );

      final result = await ProgressApi.getDailyLimit('user-123');
      expect(result, isNull);
    });
  });

  group('ProgressApi.updateProgress', () {
    test('returns true on success', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({'success': true, 'data': {}}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        ),
      );

      final result = await ProgressApi.updateProgress(
        userId: 'user-123',
        lessonId: 'lesson_001',
        stars: 3,
        completed: true,
      );
      expect(result, true);
    });

    test('returns false on failure', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({'success': false, 'error': 'Invalid'}),
          400,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        ),
      );

      final result = await ProgressApi.updateProgress(
        userId: 'user-123',
        lessonId: 'lesson_001',
        stars: 3,
        completed: true,
      );
      expect(result, false);
    });
  });

  group('ProgressApi.getUserProgress', () {
    test('returns progress list on success', () async {
      final response = {
        'success': true,
        'data': [
          {
            'user_id': 'user-123',
            'lesson_id': 'lesson_001',
            'stars': 3,
            'completed': true
          }
        ]
      };

      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(response),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        ),
      );

      final result = await ProgressApi.getUserProgress('user-123');
      expect(result.length, 1);
      expect(result.first['lesson_id'], 'lesson_001');
    });

    test('returns empty list on failure', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenThrow(Exception());

      final result = await ProgressApi.getUserProgress('user-123');
      expect(result, isEmpty);
    });
  });

  group('ProgressApi.checkHealth', () {
    test('returns true when service is healthy', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {'status': 'ok'}
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        ),
      );

      final result = await ProgressApi.checkHealth();
      expect(result, true);
    });

    test('returns false on error', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenThrow(Exception());

      final result = await ProgressApi.checkHealth();
      expect(result, false);
    });
  });

  group('ProgressApi.submitExerciseResult', () {
    test('returns true on success', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({'success': true, 'data': {}}),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        ),
      );

      final result = await ProgressApi.submitExerciseResult(
        userId: 'user-1', exerciseId: 'ex-1', lessonId: 'l-1', isCorrect: true,
      );
      expect(result, true);
    });

    test('returns false on failure', () async {
      when(() => mockAdapter.fetch(any(), any(), any()))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '/review')));

      final result = await ProgressApi.submitExerciseResult(
        userId: 'u', exerciseId: 'e', lessonId: 'l', isCorrect: false,
      );
      expect(result, false);
    });
  });

  group('ProgressApi.getReviewSession', () {
    test('returns exercises on success', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              'exercises': [
                {'exercise_id': 'e1', 'lesson_id': 'l1', 'wrong_count': 2},
                {'exercise_id': 'e2', 'lesson_id': 'l2', 'wrong_count': 1},
              ],
            },
          }),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        ),
      );

      final result = await ProgressApi.getReviewSession('u1');
      expect(result.length, 2);
      expect(result[0]['exercise_id'], 'e1');
      expect(result[1]['wrong_count'], 1);
    });

    test('returns empty on failure', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenThrow(Exception());

      final result = await ProgressApi.getReviewSession('u1');
      expect(result, isEmpty);
    });
  });
}

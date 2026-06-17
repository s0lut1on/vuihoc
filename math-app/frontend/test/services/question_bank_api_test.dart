import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:math_app/services/question_bank_api.dart';
import 'package:math_app/services/api_service.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  late MockHttpClientAdapter mockAdapter;
  late Dio testDio;

  setUp(() {
    mockAdapter = MockHttpClientAdapter();
    testDio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
    testDio.httpClientAdapter = mockAdapter;
    ApiService().initialize(dio: testDio);
  });

  group('QuestionBankApi.getHint', () {
    test('returns hint from API on success', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              'hint': 'Count carefully! 🔢',
              'hint_en': 'Count carefully! 🔢',
              'from_cache': false,
            },
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        ),
      );

      final hint = await QuestionBankApi.getHint(
        exerciseId: 'ex1',
        questionText: 'What is 2+2?',
        answerHistory: ['3'],
        expectedAnswer: '4',
        isVietnamese: false,
        userId: 'test-user',
      );

      expect(hint, 'Count carefully! 🔢');
    });

    test('returns null on network error', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenThrow(
          DioException(requestOptions: RequestOptions(path: '/hint')));

      final hint = await QuestionBankApi.getHint(
        exerciseId: 'ex1',
        questionText: 'What is 2+2?',
        answerHistory: ['3'],
        expectedAnswer: '4',
        isVietnamese: false,
        userId: 'test-user',
      );

      expect(hint, isNull);
    });

    test('includes exercise_id and is_vietnamese in payload', () async {
      dynamic capturedData;
      when(() => mockAdapter.fetch(any(), any(), any()))
          .thenAnswer((inv) async {
        final req = inv.positionalArguments[0] as RequestOptions;
        capturedData = req.data;
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              'hint': 'Thử lại nhé!',
              'hint_en': 'Try again!',
              'from_cache': false
            },
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        );
      });

      await QuestionBankApi.getHint(
        exerciseId: 'ex99',
        questionText: '1+1=?',
        answerHistory: ['2', '0'],
        expectedAnswer: '2',
        isVietnamese: true,
        userId: 'test-user',
      );

      expect(capturedData, isNotNull);
      expect(capturedData['exercise_id'], 'ex99');
      expect(capturedData['is_vietnamese'], true);
      expect(capturedData['answer_history'], ['2', '0']);
      expect(capturedData['user_id'], 'test-user');
    });

    test('returns null on non-200 response', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({'success': false, 'error': 'Server error'}),
          500,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        ),
      );

      final hint = await QuestionBankApi.getHint(
        exerciseId: 'ex1',
        questionText: 'What?',
        answerHistory: [],
        expectedAnswer: 'x',
        isVietnamese: false,
        userId: 'test-user',
      );

      expect(hint, isNull);
    });
  });
}

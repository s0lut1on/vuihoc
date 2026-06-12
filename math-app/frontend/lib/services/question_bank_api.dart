import 'api_service.dart';

class QuestionBankApi {
  static final _api = ApiService();

  static Future<String?> getHint({
    required String exerciseId,
    required String questionText,
    required List<String> answerHistory,
    required String expectedAnswer,
    required bool isVietnamese,
  }) async {
    try {
      final response = await _api.post('/questions/hint', data: {
        'exercise_id': exerciseId,
        'question_text': questionText,
        'answer_history': answerHistory,
        'expected_answer': expectedAnswer,
        'is_vietnamese': isVietnamese,
      });
      final data = response['data'] as Map<String, dynamic>?;
      final hint = data?['hint'] as String?;
      return hint;
    } catch (e) {
      return null;
    }
  }
}

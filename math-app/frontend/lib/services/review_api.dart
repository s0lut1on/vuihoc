import 'api_service.dart';

class ReviewApi {
  static final _api = ApiService.withBaseUrl('/api/questions');

  /// Record a wrong answer for the current user.
  static Future<bool> recordWrong({
    required String userId,
    required String exerciseId,
    required String lessonId,
    required String subjectId,
    required String questionVi,
    required String questionEn,
    String? hintVi,
    String? hintEn,
    required List<String> options,
    required int correctIndex,
  }) async {
    try {
      await _api.post('/review/$userId', data: {
        'exercise_id': exerciseId,
        'lesson_id': lessonId,
        'subject_id': subjectId,
        'question_vi': questionVi,
        'question_en': questionEn,
        'hint_vi': hintVi,
        'hint_en': hintEn,
        'options': options,
        'correct_index': correctIndex,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetch review entries for a user.
  static Future<List<Map<String, dynamic>>> getReview(String userId) async {
    try {
      final response = await _api.get('/review/$userId');
      final data = response['data'] as Map<String, dynamic>?;
      final entries = data?['entries'] as List<dynamic>? ?? [];
      return entries.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  /// Clear a resolved wrong answer.
  static Future<bool> clearWrong({
    required String userId,
    required String exerciseId,
  }) async {
    try {
      await _api.delete('/review/$userId/$exerciseId');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get count of wrong answers for a user.
  static Future<int> getWrongAnswerCount(String userId) async {
    try {
      final response = await _api.get('/review/$userId');
      final data = response['data'] as Map<String, dynamic>?;
      final entries = data?['entries'] as List<dynamic>? ?? [];
      return entries.length;
    } catch (_) {
      return 0;
    }
  }
}

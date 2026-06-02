import 'api_service.dart';

class LanguageApi {
  static final _api = ApiService.withBaseUrl('/api/language');

  static Future<List<Map<String, dynamic>>> getCurriculum() async {
    try {
      final response = await _api.get('/curriculum');
      final data = response['data'] as Map<String, dynamic>?;
      final curriculum = data?['curriculum'] as List<dynamic>? ?? [];
      return curriculum.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getLesson(String lessonId) async {
    try {
      final response = await _api.get('/lesson/$lessonId');
      return response['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> validateText(String exerciseId, String userText) async {
    try {
      final response = await _api.post('/validate', data: {
        'exercise_id': exerciseId,
        'user_text': userText,
      });
      final data = response['data'] as Map<String, dynamic>?;
      return data?['is_correct'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateProgress({
    required String userId,
    required String lessonId,
    required int stars,
    required bool completed,
  }) async {
    try {
      await _api.post('/progress', data: {
        'user_id': userId,
        'lesson_id': lessonId,
        'stars': stars,
        'completed': completed,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkHealth() async {
    try {
      final response = await _api.get('/health');
      return response['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }
}

import 'api_service.dart';

class ProgressApi {
  static final _api = ApiService();

  static Future<Map<String, dynamic>?> getProgress() async {
    try {
      final response = await _api.get('/progress');
      return response['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
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
      final response = await _api.get('/progress/health');
      return response['success'] == true;
    } catch (_) {
      return false;
    }
  }
}

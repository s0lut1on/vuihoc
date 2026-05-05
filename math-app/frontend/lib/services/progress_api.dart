import 'api_service.dart';

class ProgressApi {
  static final _api = ApiService();

  /// Load all progress rows for a specific user (completed lessons + stars).
  static Future<List<Map<String, dynamic>>> getUserProgress(
      String userId) async {
    try {
      final response = await _api.get('/progress/$userId');
      final data = response['data'] as List<dynamic>? ?? [];
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  /// Load streak info for a specific user.
  static Future<Map<String, dynamic>?> getUserStreak(String userId) async {
    try {
      final response = await _api.get('/progress/streak/$userId');
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

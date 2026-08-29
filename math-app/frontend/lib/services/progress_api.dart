import 'api_service.dart';
import 'package:hive/hive.dart';
import 'connectivity_service.dart';

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
  static Future<Map<String, dynamic>?> getStreak(String userId) async {
    try {
      final response = await _api.get('/progress/streak/$userId');
      return response['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Load daily limit info for a specific user.
  static Future<Map<String, dynamic>?> getDailyLimit(String userId) async {
    try {
      final response = await _api.get('/progress/daily-limit/$userId');
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

  static Future<bool> submitExerciseResult({
    required String userId,
    required String exerciseId,
    required String lessonId,
    required bool isCorrect,
  }) async {
    try {
      await _api.post('/progress/review', data: {
        'user_id': userId,
        'exercise_id': exerciseId,
        'lesson_id': lessonId,
        'is_correct': isCorrect,
      });
      return true;
    } catch (_) {
      final online = await ConnectivityService.isOnline;
      if (!online) {
        final box = Hive.box('pending_sync');
        final key = '${DateTime.now().millisecondsSinceEpoch}_exercise';
        box.put(key, {
          'type': 'exercise',
          'userId': userId,
          'exerciseId': exerciseId,
          'lessonId': lessonId,
          'isCorrect': isCorrect,
        });
      }
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getReviewSession(
      String userId) async {
    try {
      final response = await _api.get('/progress/review/$userId');
      final data = response['data'] as Map<String, dynamic>?;
      final exercises = data?['exercises'] as List<dynamic>? ?? [];
      return exercises.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
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

  static Future<bool> submitSubjectScore({
    required String userId,
    required String subjectId,
    required int correctCount,
    required int totalTimeMs,
    required int score,
    required String name,
    required String avatar,
  }) async {
    try {
      await _api.post('/progress/score', data: {
        'user_id': userId,
        'subject_id': subjectId,
        'correct_count': correctCount,
        'total_time_ms': totalTimeMs,
        'score': score,
        'name': name,
        'avatar': avatar,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserScore(String userId) async {
    try {
      final res = await _api.get('/progress/score/$userId');
      return res['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}

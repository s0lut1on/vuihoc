import 'api_service.dart';
import 'package:hive/hive.dart';
import 'connectivity_service.dart';

class LanguageApi {
  static final _api = ApiService.withBaseUrl('/api/language');
  static Box _offlineCache() => Hive.box('offline_cache');

  static Future<List<Map<String, dynamic>>> getCurriculum({int grade = 1, String? subjectId}) async {
    final cacheKey = 'curriculum:${subjectId ?? 'all'}:$grade';
    try {
      final queryParams = 'grade=$grade${subjectId != null ? '&subject_id=$subjectId' : ''}';
      final response = await _api.get('/curriculum?$queryParams');
      final data = response['data'] as Map<String, dynamic>?;
      final curriculum = data?['curriculum'] as List<dynamic>? ?? [];
      final result = curriculum.map((e) => e as Map<String, dynamic>).toList();
      try {
        _offlineCache().put(cacheKey, result);
      } catch (_) {}
      return result;
    } catch (_) {
      final cached = _offlineCache().get(cacheKey);
      if (cached is List) {
        return cached.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSubSubjects({required String subjectId, int grade = 1}) async {
    try {
      final response = await _api.get('/sub-subjects?subject_id=$subjectId&grade=$grade');
      final data = response['data'] as Map<String, dynamic>?;
      final subSubjects = data?['sub_subjects'] as List<dynamic>? ?? [];
      return subSubjects.map((e) => e as Map<String, dynamic>).toList();
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
      final online = await ConnectivityService.isOnline;
      if (!online) {
        _queueSyncEntry('progress', {
          'userId': userId,
          'lessonId': lessonId,
          'stars': stars,
        });
      }
      return false;
    }
  }

  static void _queueSyncEntry(String type, Map<String, dynamic> data) {
    final box = Hive.box('pending_sync');
    final key = '${DateTime.now().millisecondsSinceEpoch}_${type}';
    box.put(key, {'type': type, ...data});
  }

  static Future<Map<String, dynamic>?> getDetailedProgress({required String userId, String? subjectId}) async {
    try {
      final query = subjectId != null ? '?subject_id=$subjectId' : '';
      final response = await _api.get('/progress/detailed/$userId$query');
      return response['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
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

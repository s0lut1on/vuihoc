import '../models/lesson_model.dart';
import 'api_service.dart';

class ContentApi {
  static final _api = ApiService();

  /// Lightweight per-subject lesson list. Replaces the old
  /// `getCurriculum` (which fetched 1,720+ lessons + exercises as a
  /// single 808KB payload just to filter client-side for one
  /// subject). The new endpoint returns only the lessons for ONE
  /// subject — ~90KB, ~5x faster. Exercises are fetched on-demand
  /// by the lesson screen via `get_lesson`.
  static Future<List<ApiLesson>> getSubjectLessons(
      String subjectId, int grade) async {
    try {
      final response =
          await _api.get('/content/subject/$subjectId/lessons?grade=$grade');
      final data = response['data'] as List<dynamic>;
      return data
          .map((l) => ApiLesson.fromJson(l as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch a single lesson by id (includes its exercises). Used by
  /// the lesson screen to load exactly one lesson + its exercises,
  /// instead of fetching the full 808KB curriculum to filter
  /// client-side for one id. Backed by `GET /api/content/lesson/:id`
  /// which already exists on the content service.
  static Future<ApiLesson?> getLesson(String lessonId) async {
    try {
      final response =
          await _api.get('/content/lesson/$lessonId');
      final data = response['data'];
      if (data == null) return null;
      return ApiLesson.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getSubjects({int grade = 1}) async {
    try {
      final response = await _api.get('/content/subjects?grade=$grade');
      final data = response['data'] as List<dynamic>;
      return data.map((s) {
        final json = s as Map<String, dynamic>;
        return <String, dynamic>{
          'id': json['id'] ?? '',
          'nameVi': json['name_vi'] ?? '',
          'nameEn': json['name_en'] ?? '',
          'icon': json['icon'] ?? '📚',
          'color': _parseColor(json['color'] ?? '#FFE8F0'),
          'lessonCount': json['lesson_count'] ?? 0,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static int _parseColor(String hex) {
    return int.tryParse(hex.replaceFirst('#', '0xFF')) ?? 0xFFFFE8F0;
  }

  static Future<bool> checkHealth() async {
    try {
      final response = await _api.get('/content/health');
      return response['success'] == true;
    } catch (_) {
      return false;
    }
  }
}

import '../models/lesson_model.dart';
import 'api_service.dart';

class ContentApi {
  static final _api = ApiService();

  static Future<List<ApiLesson>> getCurriculum({int grade = 1}) async {
    try {
      final response = await _api.get('/content/curriculum?grade=$grade');
      final data = response['data'] as List<dynamic>;
      return data
          .map((s) {
            final subject = s as Map<String, dynamic>;
            final lessons = subject['lessons'] as List<dynamic>;
            return lessons.map((l) {
              final lesson = l as Map<String, dynamic>;
              lesson['subject_id'] = subject['subject_id'];
              return ApiLesson.fromJson(lesson);
            }).toList();
          })
          .expand((l) => l)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Lightweight per-subject lesson list. Replaces `getCurriculum` for
  /// the subject screen — returns just lesson metadata for ONE subject
  /// (no exercise data), avoiding the 808KB denormalized curriculum
  /// payload. Exercises are fetched on-demand by the lesson screen
  /// via `get_lesson`. ~9x smaller payload, ~5x faster.
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

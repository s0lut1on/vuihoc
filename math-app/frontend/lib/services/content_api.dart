import '../models/lesson_model.dart';
import 'api_service.dart';

class ContentApi {
  static final _api = ApiService();

  static Future<List<ApiLesson>> getCurriculum() async {
    try {
      final response = await _api.get('/content/curriculum');
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

  static Future<List<Map<String, dynamic>>> getSubjects() async {
    try {
      final response = await _api.get('/content/subjects');
      final data = response['data'] as List<dynamic>;
      return data.map((s) => s as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
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

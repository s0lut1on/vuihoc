import 'api_service.dart';

class AchievementService {
  static final _api = ApiService();

  static Future<List<Map<String, dynamic>>> getAchievements(
      String userId) async {
    try {
      final response = await _api.get('/progress/achievements/$userId');
      final data = response['data'] as List<dynamic>? ?? [];
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> markRead(String userId, String badgeType) async {
    try {
      await _api.post('/progress/achievements/$userId/$badgeType/mark-read');
      return true;
    } catch (_) {
      return false;
    }
  }
}

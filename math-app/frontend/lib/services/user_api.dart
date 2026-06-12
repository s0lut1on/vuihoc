import '../models/user_model.dart';
import 'api_service.dart';

class UserApi {
  static final _api = ApiService();

  static Future<User> getUser() async {
    final response = await _api.get('/users');
    final data = response['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  static Future<User> createUser({
    required String name,
    required String persona,
    String locale = 'vi_VN',
    int grade = 1,
  }) async {
    final response = await _api.post('/users', data: {
      'name': name,
      'persona': persona,
      'locale': locale,
      'grade': grade,
    });
    final data = response['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  static Future<User> updateGrade(int grade) async {
    final response = await _api.post('/users/grade', data: {'grade': grade});
    final data = response['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  static Future<bool> checkHealth() async {
    try {
      final response = await _api.get('/users/health');
      return response['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> joinClassroom(String code) async {
    try {
      await _api.post('/users/classroom/join', data: {'classroom_code': code});
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> leaveClassroom() async {
    try {
      await _api.post('/users/classroom/leave');
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final response = await _api.get('/users/classroom/leaderboard');
      final data = response['data'] as List<dynamic>? ?? [];
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }
}

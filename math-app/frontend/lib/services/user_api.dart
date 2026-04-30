import '../models/user_model.dart';
import 'api_service.dart';

class UserApi {
  static final _api = ApiService();

  static Future<User> getUser(String userId) async {
    final response = await _api.get('/users/$userId');
    final data = response['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  static Future<User> createUser({
    required String name,
    required String persona,
    String locale = 'vi_VN',
  }) async {
    final response = await _api.post('/users', data: {
      'name': name,
      'persona': persona,
      'locale': locale,
    });
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
}

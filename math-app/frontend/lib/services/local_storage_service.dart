import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';
import '../models/persona_model.dart';

class LocalStorageService {
  static const String _userBox = 'userBox';
  static const String _settingsBox = 'settingsBox';

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    // Register adapters here if custom objects are stored
  }

  static Future<void> saveUser(User user) async {
    final box = await Hive.openBox(_userBox);
    await box.put('user', {
      'uid': user.id,
      'name': user.name,
      'persona': user.persona.name,
      'avatar': user.avatar,
      'totalLessons': user.totalLessons,
      'totalStars': user.totalStars,
      'streakDays': user.streakDays,
      'gems': user.gems,
      'locale': user.locale,
    });
  }

  static Future<User?> getUser() async {
    final box = await Hive.openBox(_userBox);
    final data = box.get('user') as Map?;
    if (data == null) return null;
    return User(
      id: data['uid'],
      name: data['name'],
      persona: Persona.values.byName(data['persona']),
      avatar: data['avatar'],
      totalLessons: data['totalLessons'],
      totalStars: data['totalStars'],
      streakDays: data['streakDays'],
      gems: data['gems'],
      locale: data['locale'],
      createdAt: DateTime.now(),
    );
  }

  static Future<void> saveOnboardingComplete() async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('onboardingComplete', true);
  }

  static Future<bool> isOnboardingComplete() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('onboardingComplete', defaultValue: false);
  }

  static Future<void> saveTtsEnabled(bool enabled) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('ttsEnabled', enabled);
  }

  static Future<bool> getTtsEnabled() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('ttsEnabled', defaultValue: true);
  }

  static Future<void> saveLocale(String locale) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('locale', locale);
  }

  static Future<String> getLocale() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('locale', defaultValue: 'vi_VN');
  }
}

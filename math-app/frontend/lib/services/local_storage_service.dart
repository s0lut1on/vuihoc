import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';
import '../models/persona_model.dart';

class LocalStorageService {
  static const String _userBox = 'userBox';
  static const String _settingsBox = 'settingsBox';

  static Future<void> init() async {
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
    }
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

  /// Whether unlock-celebration animations should play. Parents can disable
  /// from the dashboard to reduce overstimulation. Default: true.
  static Future<void> saveUnlockAnimationsEnabled(bool enabled) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('unlockAnimationsEnabled', enabled);
  }

  static Future<bool> getUnlockAnimationsEnabled() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('unlockAnimationsEnabled', defaultValue: true);
  }

  // Plan 5: parent email preferences. Persisted locally so the dashboard
  // round-trips even before the backend `/api/user/email-preferences`
  // endpoint ships. The backend delivery itself is a separate task
  // (cron + SendGrid). For now, this is the user-entered data.
  static Future<void> saveParentEmail(String email) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('parentEmail', email);
  }

  static Future<String> getParentEmail() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('parentEmail', defaultValue: '') as String;
  }

  static Future<void> saveEmailFrequency(String freq) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('emailFrequency', freq);
  }

  static Future<String> getEmailFrequency() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('emailFrequency', defaultValue: 'never') as String;
  }

  /// Phase C: "Nhắc tôi sau" banner on home.
  /// Stores the timestamp of the last dismiss. The banner re-shows after
  /// 24h. We store the timestamp (int millis since epoch) rather than a
  /// boolean so we can compute the elapsed duration in app-local time.
  static Future<void> savePricingBannerDismissedAt(DateTime at) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('pricingBannerDismissedAt', at.millisecondsSinceEpoch);
  }

  static Future<DateTime?> getPricingBannerDismissedAt() async {
    final box = await Hive.openBox(_settingsBox);
    final v = box.get('pricingBannerDismissedAt');
    if (v == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(v as int);
  }

  static Future<void> saveSoundMuted(bool muted) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('soundMuted', muted);
  }

  static Future<bool> getSoundMuted() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('soundMuted', defaultValue: false) as bool;
  }
}

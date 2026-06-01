import 'package:hive/hive.dart';
import '../models/wrong_answer_model.dart';

/// Persists wrong-answer entries locally for review.
///
/// Uses the same `_settingsBox` as other preferences so we don't create an
/// extra Hive box just for this feature.
class WrongAnswerStorage {
  static const String _settingsBox = 'settingsBox';
  static const String _wrongAnswersKey = 'wrongAnswers';

  /// Load all stored wrong answers.
  static Future<List<WrongAnswer>> load() async {
    final box = await Hive.openBox(_settingsBox);
    final raw = box
        .get(_wrongAnswersKey, defaultValue: <Map<String, dynamic>>[]) as List;
    return raw
        .cast<Map<dynamic, dynamic>>()
        .map((m) => WrongAnswer.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  /// Save the entire list of wrong answers.
  static Future<void> saveAll(List<WrongAnswer> list) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put(
      _wrongAnswersKey,
      list.map((e) => e.toJson()).toList(),
    );
  }

  /// Record a wrong answer (or increment the counter if it already exists).
  static Future<void> record(WrongAnswer entry) async {
    final list = await load();
    final idx = list.indexWhere((e) => e.exerciseId == entry.exerciseId);
    if (idx >= 0) {
      list[idx] = list[idx].increment();
    } else {
      list.add(entry);
    }
    await saveAll(list);
  }

  /// Remove a resolved wrong answer.
  static Future<void> remove(String exerciseId) async {
    final list = await load();
    list.removeWhere((e) => e.exerciseId == exerciseId);
    await saveAll(list);
  }

  /// Get the count of stored wrong answers.
  static Future<int> getCount() async {
    final list = await load();
    return list.length;
  }
}

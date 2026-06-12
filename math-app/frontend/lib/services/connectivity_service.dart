import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../services/language_api.dart';
import '../services/progress_api.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _controller.stream;

  static Future<bool> get isOnline async {
    try {
      final results = await Connectivity().checkConnectivity();
      return !results.contains(ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  void init() {
    _connectivity.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      _controller.add(online);
      if (online) _flushPendingSync();
    });
  }

  Future<void> _flushPendingSync() async {
    final box = Hive.box('pending_sync');
    final keys = box.keys.toList()..sort();
    for (final key in keys) {
      final entry = box.get(key) as Map<dynamic, dynamic>?;
      if (entry == null) continue;
      final type = entry['type'] as String?;
      if (type == 'progress') {
        final userId = entry['userId'] as String;
        final lessonId = entry['lessonId'] as String;
        final stars = entry['stars'] as int;
        final success = await LanguageApi.updateProgress(
          userId: userId,
          lessonId: lessonId,
          stars: stars,
          completed: true,
        );
        if (success) box.delete(key);
      } else if (type == 'exercise') {
        final userId = entry['userId'] as String;
        final exerciseId = entry['exerciseId'] as String;
        final lessonId = entry['lessonId'] as String;
        final isCorrect = entry['isCorrect'] as bool;
        final success = await ProgressApi.submitExerciseResult(
          userId: userId,
          exerciseId: exerciseId,
          lessonId: lessonId,
          isCorrect: isCorrect,
        );
        if (success) box.delete(key);
      }
    }
  }

  void dispose() {
    _controller.close();
  }
}

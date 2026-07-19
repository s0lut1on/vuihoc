import 'dart:html' as html;
import 'dart:convert';
import 'api_service.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  static const String _queueKey = 'offline_progress_queue';

  void queueProgressUpdate({
    required String userId,
    required String lessonId,
    required int stars,
    required bool completed,
  }) {
    final storage = html.window.localStorage;
    final existing = storage[_queueKey];
    final List<Map<String, dynamic>> queue;
    if (existing != null && existing.isNotEmpty) {
      queue = List<Map<String, dynamic>>.from(jsonDecode(existing));
    } else {
      queue = [];
    }
    queue.add({
      'user_id': userId,
      'lesson_id': lessonId,
      'stars': stars,
      'completed': completed,
      'queued_at': DateTime.now().toIso8601String(),
    });
    storage[_queueKey] = jsonEncode(queue);
  }

  List<Map<String, dynamic>> getPendingItems() {
    final storage = html.window.localStorage;
    final existing = storage[_queueKey];
    if (existing == null || existing.isEmpty) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(existing));
    } catch (_) {
      return [];
    }
  }

  void clearQueue() {
    html.window.localStorage.remove(_queueKey);
  }

  void removeItem(int index) {
    final items = getPendingItems();
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      html.window.localStorage[_queueKey] = jsonEncode(items);
    }
  }

  Future<bool> syncPending() async {
    final items = getPendingItems();
    if (items.isEmpty) return true;

    final List<Map<String, dynamic>> batchItems = items.map((item) => {
      'lesson_id': item['lesson_id'],
      'stars': item['stars'],
      'completed': item['completed'],
    }).toList();

    if (batchItems.isEmpty) return true;

    try {
      final userId = items.first['user_id'];
      await ApiService().post('/progress/batch', body: {
        'user_id': userId,
        'items': batchItems,
      });
      clearQueue();
      return true;
    } catch (e) {
      return false;
    }
  }
}

import 'package:hive/hive.dart';

const String _cacheBoxName = 'offline_cache';

Box _box() => Hive.box(_cacheBoxName);

/// Result wrapper so callers can distinguish "got it from cache" from
/// "got it from network" — useful for telemetry and UI hints.
class CachedResult<T> {
  final T? value;
  final bool fromCache;
  const CachedResult(this.value, {this.fromCache = false});
}

/// Cache-first fetch with TTL. On network failure, returns the cached value
/// (if not expired) and sets [fromCache] = true.
///
/// Designed for read-only endpoints. Writes go through the pending_sync
/// queue in `connectivity_service.dart` (a separate concern).
///
/// Storage: Hive box `offline_cache`, key = `cache:<key>`, value = JSON-like
/// map with shape:
/// ```
/// { "value": <T>, "savedAt": <iso-8601> }
/// ```
Future<CachedResult<T>> withCache<T>({
  required String key,
  required Duration ttl,
  required Future<T> Function() network,
}) async {
  final hiveKey = 'cache:$key';
  final box = _box();

  // Try network first.
  try {
    final fresh = await network();
    try {
      await box.put(hiveKey, {
        'value': fresh,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Box may be closed in tests; non-fatal.
    }
    return CachedResult(fresh);
  } catch (_) {
    // Network failed: try cache.
    final entry = box.get(hiveKey);
    if (entry is Map) {
      final value = entry['value'] as T?;
      final savedAtStr = entry['savedAt'] as String?;
      if (value != null && savedAtStr != null) {
        final savedAt = DateTime.tryParse(savedAtStr);
        if (savedAt != null) {
          final age = DateTime.now().toUtc().difference(savedAt);
          if (age <= ttl) {
            return CachedResult(value, fromCache: true);
          }
        }
      }
    }
    return const CachedResult(null);
  }
}

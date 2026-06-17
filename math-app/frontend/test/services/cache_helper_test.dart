import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:math_app/services/cache_helper.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cache_helper_test');
    Hive.init(tempDir.path);
    await Hive.openBox('offline_cache');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  setUp(() async {
    // Wipe box between tests for isolation
    await Hive.box('offline_cache').clear();
  });

  group('withCache', () {
    test('returns network result on success', () async {
      var networkCalls = 0;
      final result = await withCache<String>(
        key: 'test',
        ttl: const Duration(minutes: 5),
        network: () async {
          networkCalls++;
          return 'fresh';
        },
      );
      expect(result.value, 'fresh');
      expect(result.fromCache, isFalse);
      expect(networkCalls, 1);
    });

    test('caches result and returns cached on second call (when network fails)', () async {
      var networkCalls = 0;
      // First call: network works
      final first = await withCache<String>(
        key: 'k',
        ttl: const Duration(minutes: 5),
        network: () async {
          networkCalls++;
          return 'primed';
        },
      );
      expect(first.fromCache, isFalse);

      // Second call: network fails, but we should get the cached value
      final second = await withCache<String>(
        key: 'k',
        ttl: const Duration(minutes: 5),
        network: () async => throw Exception('offline'),
      );
      expect(second.value, 'primed');
      expect(second.fromCache, isTrue);
      expect(networkCalls, 1, reason: 'second call should not hit network');
    });

    test('returns cached value on network failure', () async {
      await withCache<String>(
        key: 'k2',
        ttl: const Duration(minutes: 5),
        network: () async => 'primed',
      );
      final result = await withCache<String>(
        key: 'k2',
        ttl: const Duration(minutes: 5),
        network: () async => throw Exception('offline'),
      );
      expect(result.value, 'primed');
      expect(result.fromCache, isTrue);
    });

    test('falls back to cache when network throws, no cache = null/empty', () async {
      final result = await withCache<String>(
        key: 'never-seen',
        ttl: const Duration(minutes: 5),
        network: () async => throw Exception('offline'),
      );
      // No cache, no network → value is null (caller decides fallback)
      expect(result.value, isNull);
      expect(result.fromCache, isFalse);
    });

    test('expired cache is treated as miss', () async {
      // We can't actually wait 1s in a unit test cheaply, so verify the
      // path: a TTL of 0 means everything expires.
      await withCache<String>(
        key: 'exp',
        ttl: const Duration(milliseconds: 1),
        network: () async => 'v',
      );
      // Sleep just past TTL.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      var networkCalls = 0;
      final result = await withCache<String>(
        key: 'exp',
        ttl: const Duration(milliseconds: 1),
        network: () async {
          networkCalls++;
          return 'v2';
        },
      );
      expect(result.value, 'v2');
      expect(result.fromCache, isFalse);
      expect(networkCalls, 1);
    });

    test('works with Map values', () async {
      final result = await withCache<Map<String, dynamic>>(
        key: 'map-k',
        ttl: const Duration(minutes: 5),
        network: () async => {'a': 1, 'b': 2},
      );
      expect(result.value, {'a': 1, 'b': 2});
    });

    test('bypassing cache uses a fresh key on each call', () async {
      var calls = 0;
      for (var i = 0; i < 3; i++) {
        await withCache<int>(
          key: 'k$i',
          ttl: const Duration(minutes: 5),
          network: () async {
            calls++;
            return i;
          },
        );
      }
      expect(calls, 3);
    });
  });
}

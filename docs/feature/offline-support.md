# Offline Support

The app uses Hive for local caching and a pending-sync queue so some actions survive temporary loss of connectivity.

## Files

- `math-app/frontend/lib/services/local_storage_service.dart`
- `math-app/frontend/lib/services/cache_helper.dart`
- `math-app/frontend/lib/services/connectivity_service.dart`
- `math-app/frontend/lib/services/offline_sync_service.dart`
- `math-app/frontend/lib/services/language_api.dart`
- `math-app/frontend/lib/services/progress_api.dart`

## Hive Boxes

- `auth` — token and token type.
- `settings` — locale, TTS, sound, unlock animations, parent email, pricing banner dismiss time, onboarding complete.
- `offline_cache` — cached read-only API responses with TTL and build-version invalidation.
- `pending_sync` — queued writes when offline.

## Cache-First Reads

- `withCache<T>()` in `cache_helper.dart` tries network first, then falls back to cached data if it is within TTL.
- Cache is cleared when `kBuildVersion` changes to avoid stale schemas.
- Used by `LanguageApi` for curriculum, sub-subjects, and lessons.

## Pending Sync Queue

- When a write API fails while offline, the request is stored in `pending_sync`.
- Types: `progress` (language), `exercise` (progress review).
- `OfflineSyncService.syncPending()` flushes queued progress as a batch to `/api/progress/batch`.

## Connectivity Awareness

- `ConnectivityService` tracks online/offline state.
- `OfflineBanner` is shown in `LanguageLessonScreen` when offline.

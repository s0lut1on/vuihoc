# Plan: Offline Exercise Cache

## Problem
Kids in Vietnam often have intermittent mobile data or WiFi. Loading exercises from `api/language/curriculum` fails offline, causing app crash or blank screen.

## Goal
Cache the last visited subject's curriculum + exercises in the browser so the user can continue practicing offline. Sync progress when connectivity returns.

## Scope

### MVP (2-3 days)
- **Frontend**: Use `flutter_cache_manager` + custom Hive box `offline_cache`:
  - Key: `curriculum:{subject_id}:{grade}`
  - Value: JSON of full curriculum response (lessons + exercises).
  - TTL: 7 days.
- **Frontend**: Modify `LanguageApiService.getCurriculum()`:
  - Try network first.
  - On failure, read from Hive cache.
  - On success, write to Hive cache.
- **Frontend**: Modify `LanguageApiService.submitProgress()`:
  - If offline, queue submission in Hive `pending_sync` box.
  - On app resume / connectivity restored, flush queue via background sync.
- **Frontend**: Add offline banner to `HomeScreen` and `LanguageLessonScreen` when `ConnectivityResult.none`.

### V2
- Service Worker (PWA) for full asset caching (images, audio from MinIO).
- Background sync API for automatic queue flush.

## Affected Files

### Frontend
- `math-app/frontend/lib/services/language_api.dart` — add cache read/write + offline queue
- `math-app/frontend/lib/services/connectivity_service.dart` — new, wraps `connectivity_plus`
- `math-app/frontend/lib/screens/home_screen.dart` — offline banner
- `math-app/frontend/lib/screens/language_lesson_screen.dart` — offline banner + disable submit if no queue
- `math-app/frontend/lib/main.dart` — initialize Hive boxes at startup

### Backend
- None (queue flush hits existing endpoints).

## Effort Estimate
- **Frontend**: 2 days (cache logic + queue + UI banners)
- **Testing**: 1 day (Chrome DevTools network throttling, airplane mode)

## Risks
- Stale curriculum: if admin edits exercises while user is offline, cached version is outdated. Acceptable for MVP (7d TTL).
- Queue order matters: must replay submissions in sequence or progress percentages will be wrong.

## Success Criteria
- [ ] User opens app with WiFi off; last visited subject's lessons load from cache.
- [ ] User completes exercise offline; score saved locally.
- [ ] User reconnects; pending scores sync and reflect in `ParentDashboardScreen`.

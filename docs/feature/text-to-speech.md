# Text-to-Speech (TTS)

The app can read questions aloud to young learners. TTS is toggleable in profile settings and uses the Web Speech API on web builds.

## Files

- `math-app/frontend/lib/services/tts_service.dart`
- `math-app/frontend/lib/services/tts_service_web.dart`
- `math-app/frontend/lib/services/tts_service_stub.dart`
- `math-app/frontend/lib/screens/profile_screen.dart`
- `math-app/frontend/lib/screens/lesson_screen.dart`
- `math-app/frontend/lib/screens/language_lesson_screen.dart`

## Web TTS

- Uses `html.window.speechSynthesis`.
- Waits up to 2 seconds for Chrome voices to load.
- Selects voice by exact `lang` match, then prefix match, then contains match.
- Speaks at rate 0.9, pitch 1.0, volume 1.0.
- Supports `vi-VN` and `en-GB`.

## Stub TTS

- No-op implementation used on mobile, desktop, and VM tests.
- `isSupported` returns `false`.

## Controls

- Profile screen has a toggle to enable/disable TTS (default: enabled).
- `ttsEnabledProvider` holds the runtime state.
- `LocalStorageService.saveTtsEnabled` persists the preference in Hive.

## Triggers

- Math lesson: speaker button in the header reads the current question.
- Language lesson: auto-reads the next question after advancing, if TTS is enabled.

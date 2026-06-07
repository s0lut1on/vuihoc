# Plan: Text-to-Speech for Language Exercises

## Problem
`listen_select` exercises currently require manual audio file hosting (MinIO). Typing exercises have no audio feedback for young learners who can't read yet.

## Goal
Use browser `speechSynthesis` API (free, offline-capable) to read exercise prompts and answer options aloud, reducing dependency on pre-recorded audio files.

## Scope

### MVP (1 day)
- **Frontend**: Create `TtsService` (`lib/services/tts_service.dart`):
  - Detects browser support (`window.speechSynthesis != null`).
  - Voices: prefer `vi-VN` for Vietnamese, `en-US` for English.
  - Method `speak(String text, String lang)`.
  - Debounce: cancel previous utterance if new one requested.
- **Frontend**: Integrate into exercise widgets:
  - `ListenSelectExercise` — auto-play prompt on load + replay button.
  - `TypingExercise` — speaker icon next to prompt text.
  - `MatchingExercise` — optional: speak card text on tap (toggle in settings).
- **Frontend**: Add TTS toggle in `SettingsScreen` (disable for classrooms / quiet mode).

### V2
- Pre-generate and cache TTS utterances in IndexedDB for offline use.
- Fallback to backend-generated audio (AWS Polly / MinIO pre-rendered) if browser TTS unavailable.

## Affected Files

### Frontend
- `math-app/frontend/lib/services/tts_service.dart` — new
- `math-app/frontend/lib/widgets/listen_select_exercise.dart` — add auto-play + replay
- `math-app/frontend/lib/widgets/typing_exercise.dart` — add speaker icon
- `math-app/frontend/lib/widgets/matching_exercise.dart` — optional speak on tap
- `math-app/frontend/lib/screens/settings_screen.dart` — TTS toggle

### Backend
- None.

## Effort Estimate
- **Frontend**: 0.5 day (service + integration into 3 widgets)
- **Testing**: 0.5 day (cross-browser voice availability varies)

## Risks
- `speechSynthesis` voices are OS-dependent; Linux servers (headless) won't have voices, but users will on their devices.
- Some mobile browsers (iOS Safari) limit TTS to user gestures — use `ElevatedButton.onPressed` to trigger, not `initState`.

## Success Criteria
- [ ] Vietnamese prompt is spoken aloud when a `listen_select` exercise loads.
- [ ] User can tap a speaker icon in `typing_exercise` to hear the prompt.
- [ ] TTS gracefully no-ops in unsupported browsers without errors.

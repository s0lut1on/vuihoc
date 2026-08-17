# Plan: Sound Effects + Background Music

## Problem
The app is silent except for TTS reading questions aloud. Kids 5-7 respond strongly to audio feedback — correct answer dings, celebratory fanfares, button clicks. The absence makes the app feel flat compared to competitors (Monkey Math, VioEdu).

## Goal
Add layered audio system:
1. **SFX**: Correct/wrong answer sounds, lesson complete fanfare, achievement unlock
2. **UI sounds**: Button tap, page transition whoosh
3. **Background music**: Optional looping study music (classical / lofi)

Each with independent volume control. Background music off by default. SFX on by default.

## Scope

### MVP — Frontend only (2-3 days)

**Audio assets**:
- Source: royalty-free SFX packs (Mixkit, ZapSplat, Pixabay)
- Format: MP3 (broad compatibility, small size)
- Files (estimate ~500KB total):
  - `correct.mp3` — 2 variants (short ding ~1s, longer chime ~2s)
  - `wrong.mp3` — gentle buzz ~1s
  - `complete.mp3` — celebration fanfare ~3s
  - `tap.mp3` — soft UI click ~0.3s
  - `achievement.mp3` — unlock sound ~2s
  - `bg_study.mp3` — lofi loop ~60s (optional, ~2MB)
  - `bg_playful.mp3` — upbeat loop ~60s (optional, ~2MB)

**Audio service** (`audioplayers` package already in `pubspec.yaml`):
```dart
class AudioService {
  static final _instance = AudioService._();
  factory AudioService() => _instance;

  bool sfxEnabled = true;
  bool musicEnabled = false;
  double sfxVolume = 0.7;
  double musicVolume = 0.3;

  final _cache = <String, AudioPlayer>{};
  AudioPlayer? _bgMusic;

  Future<void> playSfx(String name) async { ... }
  Future<void> startMusic(String track) async { ... }
  void stopMusic() { ... }
}
```

**Integration points** (add SFX calls):

| Screen | Event | Sound |
|--------|-------|-------|
| `LessonScreen` | Correct answer | `correct.mp3` |
| `LessonScreen` | Wrong answer | `wrong.mp3` |
| `LessonScreen` | Lesson complete | `complete.mp3` |
| `CelebrationScreen` | Stars appear | `achievement.mp3` (per star) |
| `AchievementScreen` | New badge | `achievement.mp3` |
| `Button` widgets | Tap | `tap.mp3` |
| `BubbleButton` | Press | `tap.mp3` |

**Settings UI**:
- Add "Âm thanh" section in `ProfileScreen` below TTS toggle
- Switches for: SFX, Background music
- Sliders for: SFX volume, Music volume
- Store in Hive `settings` box (reuse `LocalStorageService`)

**Background music**:
- Plays only on home screen + subject screen
- Pauses during lessons
- Auto-stops on lesson completion
- Toggle persists across sessions
- Different tracks per subject (optional V2):
  - Numbers → playful upbeat
  - Geometry → calm study
  - Logic → mysterious
  - Vietnamese → traditional melody

**Free vs Premium**:
- Free: SFX only (correct, wrong, complete), no background music
- Premium: Full SFX set (achievement, tap, varied correct), background music, track per subject

### Backend — none required
All audio is client-side. No streaming needed. Assets bundled in Flutter app.

## Affected Files

### Frontend
- `math-app/frontend/assets/audio/` — new directory with MP3 files
- `math-app/frontend/pubspec.yaml` — add audio assets to `flutter.assets`
- `math-app/frontend/lib/services/audio_service.dart` — new, AudioService singleton
- `math-app/frontend/lib/services/local_storage_service.dart` — add sfx/music prefs
- `math-app/frontend/lib/screens/lesson_screen.dart` — add SFX calls on answer
- `math-app/frontend/lib/screens/celebration_screen.dart` — add completion fanfare
- `math-app/frontend/lib/screens/achievement_screen.dart` — add unlock sound
- `math-app/frontend/lib/screens/home_screen.dart` — start/stop background music
- `math-app/frontend/lib/screens/profile_screen.dart` — audio settings section
- `math-app/frontend/lib/screens/subject_screen.dart` — start/stop background music
- `math-app/frontend/lib/providers/app_providers.dart` — `sfxEnabledProvider`, `musicEnabledProvider`
- `math-app/frontend/lib/widgets/bubble_button.dart` — optional tap sound

## Effort Estimate
- **Frontend**: 2-3 days (service + integration + assets)
- **Backend**: 0 days
- **Testing**: 0.5 day
- **Total**: ~3 days

## Risks
- Audio files bloat app size. MP3 at 128kbps keeps each file under 100KB (except bg music ~2MB). Total: ~5MB.
- Web audio autoplay blocked by browsers. Need user gesture first (already happens on login/lesson start).
- Multiple AudioPlayer instances can conflict. Use singleton pool with max 2 simultaneous.

## Success Criteria
- [ ] Correct answer plays short cheerful ding
- [ ] Wrong answer plays gentle buzz
- [ ] Lesson complete plays fanfare
- [ ] SFX toggle works (on/off)
- [ ] Background music plays on home screen when enabled
- [ ] Music pauses during lesson, resumes after
- [ ] Settings persist across app restarts
- [ ] No audio plays before first user tap (respects browser autoplay policy)

# Expansion Plan: Vietnamese & English Language Subjects
## WITH Full Audio, Speaking, and Typing Support

## User Requirement (Non-Negotiable)
Language exercises must support:
1. **Audio playback** (TTS for listening)
2. **Audio input** (Student speaks, system evaluates via STT)
3. **Typing text** (Free text input with validation)

Not just multiple choice.

---

## Architectural Decision

### New Backend Service: `language-service`

| Layer | Current Math | New Language | Rationale |
|-------|-------------|--------------|-----------|
| **Framework** | Rust (Axum) | **Python (FastAPI)** | Python has the best ecosystem for: STT (Whisper), TTS (gTTS, cloud), NLP (diacritic handling, grammar), audio processing (librosa, pydub). |
| **Database** | `content_db` (lessons/exercises) | **`language_db`** (new PostgreSQL) | Language exercises have different schema (audio_url, expected_text, exercise_type enum, pronunciation_phonemes). |
| **Users/Auth** | `user_db` + JWT | **Shared** | Same `users` table. Same JWT secret. `auth_middleware` imported from shared Rust crate or reimplemented in Python. |
| **Progress** | `progress_db` (math progress) | **`language_progress` table** in `language_db` | Math and language progress are independent. Can aggregate later. |
| **Storage** | MinIO (media assets) | **Shared MinIO** | New bucket `audio-files/` for TTS-generated MP3s + user recordings. |
| **Proxy** | Traefik | **Shared Traefik** | New route: `Host(\`sekklings.com\`) && PathPrefix(\`/api/language/\`)` → `language-service`. |

### Why Separate Service?
- **Different scaling needs:** Audio processing is CPU-heavy; language service can scale independently
- **Tech fit:** Python is objectively better for ML/NLP than Rust (ecosystem maturity)
- **Team isolation:** Language curriculum authors can work on Python without touching Rust math code
- **Failure isolation:** Language service crash doesn't break math progress tracking

---

## Database Schema: `language_db`

### Table: `language_subjects`
```sql
CREATE TABLE language_subjects (
    id VARCHAR(50) PRIMARY KEY,
    name_vi VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NOT NULL,
    icon VARCHAR(10) DEFAULT '📚',
    color VARCHAR(50) DEFAULT '#FFEBEE',
    display_order INT DEFAULT 0,
    target_language VARCHAR(10) NOT NULL, -- 'vi' or 'en'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO language_subjects (id, name_vi, name_en, icon, color, display_order, target_language) VALUES
('vietnamese', 'Tiếng Việt', 'Vietnamese', '🇻🇳', '#FFEBEE', 1, 'vi'),
('english', 'Tiếng Anh', 'English', '🇬🇧', '#E8EAF6', 2, 'en');
```

### Table: `language_lessons`
```sql
CREATE TABLE language_lessons (
    id VARCHAR(50) PRIMARY KEY,
    subject_id VARCHAR(50) NOT NULL REFERENCES language_subjects(id) ON DELETE CASCADE,
    title_vi VARCHAR(255) NOT NULL,
    title_en VARCHAR(255) NOT NULL,
    description_vi TEXT,
    description_en TEXT,
    lesson_order INT NOT NULL DEFAULT 1,
    difficulty INT NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 3),
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table: `language_exercises`
```sql
CREATE TABLE language_exercises (
    id VARCHAR(50) PRIMARY KEY,
    lesson_id VARCHAR(50) NOT NULL REFERENCES language_lessons(id) ON DELETE CASCADE,
    
    -- Exercise taxonomy
    exercise_type VARCHAR(20) NOT NULL CHECK (exercise_type IN (
        'audio_mcq',      -- Listen to audio, pick text answer
        'dictation',      -- Listen to audio, type what you hear
        'speaking',       -- Listen to prompt, record yourself, STT evaluates
        'typing',         -- Type text answer (spelling, sentence, etc.)
        'repeat'          -- Listen and repeat (pronunciation scoring)
    )),
    
    -- Questions (bilingual)
    question_vi TEXT NOT NULL,
    question_en TEXT NOT NULL,
    
    -- For audio_mcq: text options + correct index
    options TEXT[] DEFAULT '{}',
    correct_index INT DEFAULT 0,
    
    -- For typing/dictation/speaking: expected answer
    expected_text VARCHAR(500),
    -- Text matching tolerance: exact, contains, or edit distance
    validation_mode VARCHAR(20) DEFAULT 'exact' CHECK (validation_mode IN ('exact', 'contains', 'levenshtein')),
    -- For levenshtein: max allowed distance (0 = exact match)
    max_edit_distance INT DEFAULT 0,
    -- Case/diacritic sensitivity
    case_sensitive BOOLEAN DEFAULT FALSE,
    diacritic_sensitive BOOLEAN DEFAULT TRUE, -- critical for Vietnamese
    
    -- Audio: TTS-generated prompt audio
    audio_url VARCHAR(255), -- MinIO path: audio-files/vn/ba.mp3
    -- For repeat/speaking: reference audio to compare against
    reference_audio_url VARCHAR(255),
    
    -- Visual hint
    visual_asset VARCHAR(50) DEFAULT '', -- emoji or image path
    
    -- Hints
    hint_vi TEXT,
    hint_en TEXT,
    
    exercise_order INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_lang_exercises_lesson ON language_exercises(lesson_id);
CREATE INDEX idx_lang_exercises_type ON language_exercises(exercise_type);
```

### Table: `language_progress`
```sql
CREATE TABLE language_progress (
    user_id UUID NOT NULL,
    lesson_id VARCHAR(50) NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    stars INT DEFAULT 0,
    attempts INT DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, lesson_id)
);
```

### Table: `speech_submissions`
```sql
CREATE TABLE speech_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    exercise_id VARCHAR(50) NOT NULL,
    -- MinIO path to user-uploaded audio
    audio_url VARCHAR(255) NOT NULL,
    -- STT result
    transcribed_text VARCHAR(500),
    -- Confidence score 0.0-1.0
    confidence FLOAT,
    -- Whether it matched expected_text
    is_correct BOOLEAN,
    -- Pronunciation-specific score (for 'repeat' type)
    pronunciation_score FLOAT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## New Backend: `language-service` (Python + FastAPI)

### Project Layout
```
backend/language/
├── Dockerfile
├── requirements.txt
├── src/
│   ├── main.py              # FastAPI app, Traefik health check
│   ├── config.py            # DB URL, MinIO creds, JWT secret
│   ├── db.py                # SQLAlchemy async engine + session
│   ├── models.py            # SQLAlchemy table definitions
│   ├── schemas.py           # Pydantic request/response models
│   ├── auth.py              # JWT middleware (shared secret)
│   ├── router/
│   │   ├── curriculum.py    # GET subjects, lessons, exercises
│   │   ├── validate.py      # POST typing/dictation validation
│   │   ├── speech.py        # POST user audio → STT evaluation
│   │   ├── audio.py         # GET audio stream + POST TTS generation
│   │   └── progress.py      # GET/POST language progress
│   ├── services/
│   │   ├── stt.py           # Speech-to-text (Whisper or cloud)
│   │   ├── tts.py           # Text-to-speech (cloud API)
│   │   ├── audio_storage.py # MinIO upload/download
│   │   └── text_check.py    # Text validation (diacritics, edit distance)
│   └── migrations/          # Alembic migrations
└── tests/
```

### Tech Stack
```txt
# requirements.txt
fastapi==0.111.0
uvicorn[standard]==0.30.0
sqlalchemy[asyncio]==2.0.30
asyncpg==0.29.0
alembic==1.13.2
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.9
httpx==0.27.0
minio==7.2.7
# STT
openai-whisper==20231117  # or faster-whisper for performance
# TTS
gtts==2.5.1               # Google TTS free tier
# Audio processing
pydub==0.25.1
# NLP
unicodedata2==15.1.0      # Vietnamese normalization
# Deployment
gunicorn==23.0.0
```

### Key API Endpoints

```python
# router/curriculum.py
@router.get("/api/language/subjects")
async def get_language_subjects() -> ApiResponse[list[SubjectSummary]]:
    """Return vietnamese + english subjects."""

@router.get("/api/language/curriculum")
async def get_language_curriculum() -> ApiResponse[list[CurriculumSubject]]:
    """Return full language curriculum with exercises."""

@router.get("/api/language/lesson/{lesson_id}")
async def get_language_lesson(lesson_id: str) -> ApiResponse[LessonDetail]:
    """Return lesson + exercises."""

# router/audio.py
@router.post("/api/language/audio/tts")
async def generate_tts(
    text: str,
    language: str = "vi",  # or "en"
    voice: str | None = None
) -> ApiResponse[dict]:
    """Generate TTS audio, store in MinIO, return audio_url."""
    # Returns: {"audio_url": "https://sekklings.com/audio-files/vn/abc123.mp3"}

@router.get("/api/language/audio/{filename}")
async def stream_audio(filename: str):
    """Stream audio from MinIO with proper Content-Type."""

# router/validate.py
@router.post("/api/language/validate")
async def validate_text(
    exercise_id: str,
    user_text: str
) -> ApiResponse[ValidationResult]:
    """Validate typed/dictated text against expected_text."""
    # Returns: {"is_correct": true, "feedback": "Chính xác!", "distance": 0}

# router/speech.py
@router.post("/api/language/speech/evaluate")
async def evaluate_speech(
    exercise_id: str,
    audio: UploadFile = File(...)
) -> ApiResponse[SpeechResult]:
    """
    1. Save user audio to MinIO
    2. Run STT (Whisper) with language=vi or en
    3. Compare transcribed_text to expected_text
    4. Return: {transcribed, is_correct, confidence, pronunciation_score}
    """

# router/progress.py
@router.post("/api/language/progress")
async def update_language_progress(
    body: ProgressUpdate
) -> ApiResponse[LanguageProgress]:
    """Mirror of math progress service, but for language lessons."""
```

### Auth Strategy (Shared JWT)
```python
# auth.py
from jose import jwt, JWTError
from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

JWT_SECRET = os.environ["JWT_SECRET"]  # Same secret as Rust services
security = HTTPBearer()

async def require_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    token = credentials.credentials
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"], audience="math-app")
        return payload["sub"]  # user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

### Vietnamese Text Validation
```python
# services/text_check.py
import unicodedata

def validate_vietnamese(
    user_input: str,
    expected: str,
    mode: str = "exact",        # exact | contains | levenshtein
    case_sensitive: bool = False,
    diacritic_sensitive: bool = True,
    max_distance: int = 0
) -> dict:
    # 1. Unicode NFC normalization
    user = unicodedata.normalize('NFC', user_input.strip())
    exp = unicodedata.normalize('NFC', expected.strip())
    
    if not case_sensitive:
        user = user.lower()
        exp = exp.lower()
    
    if not diacritic_sensitive:
        # Remove diacritics for relaxed checking (e.g., spelling practice for beginners)
        user = remove_vietnamese_tones(user)
        exp = remove_vietnamese_tones(exp)
    
    if mode == "exact":
        is_correct = user == exp
    elif mode == "contains":
        is_correct = exp in user
    elif mode == "levenshtein":
        dist = levenshtein_distance(user, exp)
        is_correct = dist <= max_distance
    
    return {
        "is_correct": is_correct,
        "normalized_user": user,
        "distance": dist if mode == "levenshtein" else None,
        "feedback_vi": "Chính xác!" if is_correct else f"Đáp án đúng là: {expected}",
        "feedback_en": "Correct!" if is_correct else f"The answer is: {expected}",
    }

def remove_vietnamese_tones(text: str) -> str:
    # Map: ă→a, â→a, ê→e, ô→o, ơ→o, ư→u, đ→d, etc.
    ...
```

### STT Integration (OpenAI Whisper)
```python
# services/stt.py
import whisper
import io

model = whisper.load_model("base")  # or "small" for better accuracy, "tiny" for speed

async def transcribe_audio(audio_bytes: bytes, language: str) -> dict:
    # Save to temp file (Whisper requires file path)
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name
    
    result = model.transcribe(tmp_path, language=language)
    
    return {
        "text": result["text"].strip(),
        "confidence": result.get("confidence", 0.0),
        "language": result.get("language", language),
    }
```

**Alternative:** Use cloud STT (Google Cloud Speech-to-Text with `languageCode=vi-VN` or `en-US`) if self-hosting Whisper is too heavy for the VPS. Whisper base model is ~150MB and runs on CPU.

### TTS Integration (Google TTS)
```python
# services/tts.py
from gtts import gTTS
import tempfile
from .audio_storage import upload_to_minio

async def generate_tts(text: str, language: str) -> str:
    """Generate MP3, upload to MinIO, return public URL."""
    tts = gTTS(text=text, lang=language, slow=False)
    
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
        tts.save(tmp.name)
        # Upload to MinIO bucket 'audio-files'
        object_name = f"{language}/{uuid4()}.mp3"
        upload_to_minio("audio-files", object_name, tmp.name)
        return f"https://sekklings.com/api/language/audio/{object_name}"
```

**Alternative for Vietnamese:** Zalo AI TTS or FPT.ai TTS for higher quality Vietnamese voice.

---

## Shared Infrastructure Changes

### 1. Docker Compose Addition
```yaml
# docker-compose.yml (add to existing)
  language-service:
    build:
      context: ./backend/language
      dockerfile: Dockerfile
    environment:
      DATABASE_URL: postgres://lang_user:lang_pass@language-db:5432/language_db
      JWT_SECRET: ${JWT_SECRET}
      MINIO_ENDPOINT: minio:9000
      MINIO_ACCESS_KEY: ${MINIO_ACCESS_KEY}
      MINIO_SECRET_KEY: ${MINIO_SECRET_KEY}
      STT_PROVIDER: whisper  # or google_cloud
      TTS_PROVIDER: gtts     # or zalo_ai
    depends_on:
      - language-db
      - minio
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.language.rule=Host(\`sekklings.com\`) && PathPrefix(\`/api/language/\`)"
      - "traefik.http.routers.language.priority=100"
      - "traefik.http.services.language.loadbalancer.server.port=3000"

  language-db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: lang_user
      POSTGRES_PASSWORD: lang_pass
      POSTGRES_DB: language_db
    volumes:
      - language_db_data:/var/lib/postgresql/data
    labels:
      - "traefik.enable=false"

volumes:
  language_db_data:
```

### 2. MinIO Bucket Setup
```bash
# On first deploy
docker exec -it math-app-minio-1 mc mb minio/audio-files
docker exec -it math-app-minio-1 mc anonymous set download minio/audio-files
```

### 3. Traefik Route (No Priority Conflict)
```yaml
# docker-compose.prod.yml
# Existing routes remain untouched
# New route:
traefik.http.routers.language.rule: "Host(\`sekklings.com\`) && PathPrefix(\`/api/language/\`)"
traefik.http.routers.language.priority: "100"
```

---

## Frontend: New Exercise Widgets

### Project Layout
```
frontend/lib/widgets/exercise/
├── base_exercise.dart       # Abstract base: progress, hint, check button
├── audio_player.dart        # 🔊 play/pause button with progress indicator
├── audio_recorder.dart      # 🎤 record/stop button using MediaRecorder API
├── text_input.dart          # TextField with validation state (correct/incorrect)
└── exercise_dispatcher.dart # Routes exercise_type → widget
```

### 1. AudioPlayerWidget
```dart
// widgets/exercise/audio_player.dart
import 'dart:html' as html;

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final VoidCallback? onComplete;

  @override
  State createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  html.AudioElement? _audio;
  bool _isPlaying = false;

  void _play() {
    _audio ??= html.AudioElement(widget.audioUrl);
    _audio!.play();
    setState(() => _isPlaying = true);
    _audio!.onEnded.listen((_) => setState(() => _isPlaying = false));
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _play,
      icon: Icon(_isPlaying ? Icons.volume_up : Icons.play_arrow),
      label: Text(_isPlaying ? 'Đang phát...' : 'Nghe'),
    );
  }
}
```

### 2. AudioRecorderWidget
```dart
// widgets/exercise/audio_recorder.dart
import 'dart:html' as html;
import 'dart:typed_data';

class AudioRecorderWidget extends StatefulWidget {
  final Function(Uint8List audioBytes) onRecorded;

  @override
  State createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  html.MediaStream? _stream;
  html.MediaRecorder? _recorder;
  List<html.Blob> _chunks = [];
  bool _isRecording = false;

  Future<void> _startRecording() async {
    _stream = await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
    _recorder = html.MediaRecorder(_stream!);
    _recorder!.addEventListener('dataavailable', (event) {
      final blob = (event as html.BlobEvent).data;
      if (blob != null) _chunks.add(blob);
    });
    _recorder!.start();
    setState(() => _isRecording = true);
  }

  void _stopRecording() {
    _recorder!.stop();
    _stream!.getTracks().forEach((t) => t.stop());
    _recorder!.addEventListener('stop', (_) async {
      final blob = html.Blob(_chunks, 'audio/mp3');
      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob);
      await reader.onLoad.first;
      final bytes = reader.result as Uint8List;
      widget.onRecorded(bytes);
    });
    setState(() => _isRecording = false);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isRecording ? _stopRecording : _startRecording,
      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
      label: Text(_isRecording ? 'Dừng' : 'Nói'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isRecording ? Colors.red : Colors.pink,
      ),
    );
  }
}
```

### 3. TextInputWidget
```dart
// widgets/exercise/text_input.dart
class TextInputWidget extends StatefulWidget {
  final String expectedText;
  final bool diacriticSensitive;
  final bool caseSensitive;
  final Function(bool isCorrect, String userText) onSubmit;

  @override
  State createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  final _controller = TextEditingController();
  bool? _isCorrect;
  String? _feedback;

  void _check() {
    // Or call backend /api/language/validate for server-side checking
    final result = VietnameseTextValidator.validate(
      userInput: _controller.text,
      expected: widget.expectedText,
      diacriticSensitive: widget.diacriticSensitive,
      caseSensitive: widget.caseSensitive,
    );
    setState(() {
      _isCorrect = result.isCorrect;
      _feedback = result.feedbackVi;
    });
    widget.onSubmit(result.isCorrect, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Nhập câu trả lời...',
            border: OutlineInputBorder(),
            suffixIcon: _isCorrect == true
                ? Icon(Icons.check_circle, color: Colors.green)
                : _isCorrect == false
                    ? Icon(Icons.error, color: Colors.red)
                    : null,
          ),
        ),
        ElevatedButton(onPressed: _check, child: Text('Kiểm tra')),
        if (_feedback != null)
          Text(_feedback!, style: TextStyle(
            color: _isCorrect! ? Colors.green : Colors.red,
          )),
      ],
    );
  }
}
```

### 4. LessonScreen Exercise Dispatcher
```dart
// In lesson_screen.dart, replace monolithic _buildOptions
Widget _buildLanguageExercise(LanguageExercise ex) {
  switch (ex.exerciseType) {
    case 'audio_mcq':
      return Column(children: [
        AudioPlayerWidget(audioUrl: ex.audioUrl!),
        const SizedBox(height: 16),
        McqExerciseWidget(options: ex.options, correctIndex: ex.correctIndex, onSelect: _handleAnswer),
      ]);
    
    case 'dictation':
      return Column(children: [
        AudioPlayerWidget(audioUrl: ex.audioUrl!),
        const SizedBox(height: 16),
        TextInputWidget(
          expectedText: ex.expectedText!,
          onSubmit: (correct, text) => _handleTyping(ex, correct, text),
        ),
      ]);
    
    case 'speaking':
      return Column(children: [
        AudioPlayerWidget(audioUrl: ex.audioUrl!),
        const SizedBox(height: 16),
        Text(ex.questionVi, style: TextStyle(fontSize: 18)),
        const SizedBox(height: 16),
        AudioRecorderWidget(
          onRecorded: (bytes) => _handleSpeech(ex, bytes),
        ),
      ]);
    
    case 'typing':
      return TextInputWidget(
        expectedText: ex.expectedText!,
        diacriticSensitive: ex.diacriticSensitive,
        caseSensitive: ex.caseSensitive,
        onSubmit: (correct, text) => _handleTyping(ex, correct, text),
      );
    
    case 'repeat':
      return Column(children: [
        AudioPlayerWidget(audioUrl: ex.referenceAudioUrl!),
        const SizedBox(height: 16),
        AudioRecorderWidget(
          onRecorded: (bytes) => _handleSpeech(ex, bytes),
        ),
      ]);
    
    default:
      return McqExerciseWidget(/* fallback */);
  }
}
```

---

## Data Flow: Speaking Exercise

```
Student taps 🎤 → Browser MediaRecorder records audio (WebM/Opus)
↓
Frontend sends multipart/form-data to POST /api/language/speech/evaluate
  ├─ file: audio.webm
  ├─ exercise_id: ex_vn01_speak
  └─ user_id: (from JWT)
↓
language-service:
  1. Saves audio to MinIO: audio-files/submissions/uuid.webm
  2. Converts to MP3 (pydub)
  3. Runs Whisper STT: "ba" (language=vi)
  4. Compares to expected_text: "ba"
  5. Calculates pronunciation score (phoneme similarity)
  6. Saves to speech_submissions table
  7. Returns:
     {
       "transcribed_text": "ba",
       "is_correct": true,
       "confidence": 0.94,
       "pronunciation_score": 0.88,
       "feedback_vi": "Tuyệt vời! Bé phát âm rất chuẩn!",
       "feedback_en": "Great! Your pronunciation is very clear!"
     }
↓
Frontend shows feedback + stars earned
```

---

## Implementation Phases

### Phase 1: language-service Skeleton + DB (3 days)
1. Create `backend/language/` with FastAPI + SQLAlchemy + Alembic
2. Write `models.py` with all 5 tables
3. Generate first Alembic migration
4. Add `Dockerfile` + `requirements.txt`
5. Add to `docker-compose.yml` with `language-db`
6. Implement `auth.py` (JWT shared secret)
7. Implement `GET /api/language/health`
8. Run local: `make docker-dev`, verify service starts

### Phase 2: Static Curriculum Seed (2 days)
1. Write `seeds/vietnamese.sql` with 20 lessons + 60 exercises
2. Write `seeds/english.sql` with 20 lessons + 60 exercises
3. All exercises use pre-canned `audio_url` (we'll generate TTS in Phase 4)
4. Verify via Swagger UI at `/api/language/swagger-ui`

### Phase 3: Audio Pipeline (2 days)
1. Implement `services/tts.py` (gTTS or Zalo AI)
2. Implement `services/audio_storage.py` (MinIO upload/download)
3. Implement `POST /api/language/audio/tts` endpoint
4. Implement `GET /api/language/audio/{filename}` streaming endpoint
5. Generate sample TTS for 10 exercises, verify playback in browser

### Phase 4: Speech Evaluation (2 days)
1. Install Whisper (`pip install openai-whisper`)
2. Implement `services/stt.py` with Whisper
3. Implement `POST /api/language/speech/evaluate`
4. Test end-to-end: record audio in browser → upload → STT → validation
5. Verify Vietnamese diacritic handling in STT output

### Phase 5: Text Validation (1 day)
1. Implement `services/text_check.py` with NFC normalization
2. Implement `POST /api/language/validate`
3. Support all 3 modes: exact, contains, levenshtein
4. Test edge cases: `a` vs `ă` vs `â`, case-insensitive, diacritic-insensitive

### Phase 6: Frontend Exercise Widgets (4 days)
1. Create `AudioPlayerWidget` (html.AudioElement wrapper)
2. Create `AudioRecorderWidget` (MediaRecorder API)
3. Create `TextInputWidget` (TextField + local validation + backend fallback)
4. Create `ExerciseDispatcherWidget` (routes 5 exercise types)
5. Refactor `LessonScreen` to detect subject_id and use dispatcher for language subjects
6. Update `HomeScreen` + `SubjectScreen` with 2 new language subject cards
7. Add i18n strings for all new UI text

### Phase 7: Progress Integration (1 day)
1. Implement `language_progress` table
2. Implement `POST /api/language/progress` endpoint
3. Frontend: call language progress API on lesson completion
4. Parent Dashboard: show language progress alongside math progress

### Phase 8: E2E + Polish (2 days)
1. `make deploy` (ensure Flutter tests still pass)
2. Rust backend: ensure no regressions (language service is isolated)
3. E2E tests: add language subject navigation, audio playback, recording
4. Performance: Whisper model loading time (~5s cold start) — cache or prewarm
5. Edge cases: no mic permission, audio upload >5MB, STT timeout

**Total: 17 days** (can compress to 12 with parallel work: Phase 3+4+5 are independent backend work; Phase 6 frontend is parallel once API contracts are defined)

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| **Whisper too slow on VPS** | Use `tiny` or `base` model (~40MB, ~2s inference); or switch to Google Cloud Speech API |
| **Vietnamese STT accuracy** | Whisper is surprisingly good at Vietnamese; validate with 50 sample recordings before launch |
| **Browser mic permission denied** | Show friendly error: "Bé cần cho phép dùng micro để tập nói nhé" |
| **Audio files eat disk space** | MinIO lifecycle policy: delete submission audio after 30 days; keep TTS prompts forever |
| **Diacritic edge cases** | Extensive unit tests for `text_check.py` with all 29 Vietnamese letters |
| **JWT secret mismatch** | Document: both Rust and Python must read `JWT_SECRET` from same `.env` |
| **TTS cost (if using cloud)** | gTTS is free; Zalo AI has free tier. Cache TTS results in MinIO to avoid regeneration. |

---

## Deployment Impact

### What Changes
- `docker-compose.yml` + `docker-compose.prod.yml` — add `language-service` + `language-db`
- `.env.example` — add `STT_PROVIDER`, `TTS_PROVIDER`, `MINIO_*` (already present)
- `.github/workflows/deploy.yml` — add Docker build step for `language-service` image
- `Makefile` — add `build-language` target (optional)

### What Does NOT Change
- Existing Rust services (auth, user, content, progress, media, notification, question_bank) — untouched
- Math curriculum — untouched
- Math frontend screens — untouched
- `math-app` deploy pipeline — just +1 Docker image

---

## Decision: Tech Stack for language-service

| Component | Choice | Backup |
|-----------|--------|--------|
| **Framework** | FastAPI (Python) | None needed |
| **DB Driver** | SQLAlchemy 2.0 + asyncpg | None needed |
| **STT** | Whisper `base` model (self-hosted) | Google Cloud Speech-to-Text |
| **TTS** | gTTS (free, Google) | Zalo AI TTS (higher quality VN voice) |
| **Audio Storage** | MinIO (shared) | None needed |
| **Validation** | Python `unicodedata` + custom logic | None needed |
| **Auth** | `python-jose` with shared JWT secret | None needed |

---

## Next Action

If approved, I recommend starting **Phase 1 (language-service skeleton)** immediately. It is:
- **Isolated** — won't break existing math functionality
- **Validating** — get FastAPI + DB + Docker working first before writing curriculum
- **Parallelizable** — frontend team can work on widgets while backend implements STT/TTS

**Deliverable for Phase 1:** `docker compose up` shows `language-service` healthy at `/api/language/health`, and Traefik routes `/api/language/*` correctly.
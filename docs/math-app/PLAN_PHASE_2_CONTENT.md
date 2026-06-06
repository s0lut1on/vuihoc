# Phase 2 Detailed Plan: Real Lesson Content for Language Sub-Subjects

## Overview

Replace placeholder language lessons with interactive, pedagogically-sound exercises across 10 sub-subjects (5 Vietnamese + 5 English, Grade 1 only). This is the highest-effort, highest-impact phase.

| Metric | Target |
|--------|--------|
| Total lessons (Grade 1) | 100 (50 VN + 50 EN) |
| Exercises per lesson | 2-3 |
| Total exercises | ~250 |
| Exercise types | 5 |
| Supported grades | 1 (Grade 2/3 deferred) |

---

## Exercise Types

| # | Type | Description | Complexity | Frontend Widget |
|---|------|-------------|------------|-----------------|
| 1 | **multiple_choice** | Tap correct answer from 2-4 image/text cards | Low | `MultipleChoiceExercise` |
| 2 | **typing** | Type answer via on-screen keyboard or physical keyboard | Medium | `TypingExercise` |
| 3 | **matching** | Tap two cards to pair them (letter ↔ image, word ↔ word) | Medium | `MatchingExercise` |
| 4 | **listen_select** | Hear audio, tap matching card | Low | `ListenSelectExercise` |
| 5 | **ordering** | Drag or tap to arrange syllables/words in correct order | Medium | `OrderingExercise` |

**Deferred to v2**: `tracing` (CustomPaint letter tracing — high complexity, needs path data)

---

## Data Model Changes

### New: LanguageExerciseType Enum

```python
# backend/language/src/models.py
from enum import Enum as PyEnum
from sqlalchemy import Enum as SQLEnum

class ExerciseType(PyEnum):
    multiple_choice = "multiple_choice"
    typing = "typing"
    matching = "matching"
    listen_select = "listen_select"
    ordering = "ordering"
```

### Modified: LanguageExercise

```python
# backend/language/src/models.py
class LanguageExercise(Base):
    __tablename__ = "language_exercises"

    id = Column(String(50), primary_key=True)          # e.g., "vn_l01_e01"
    lesson_id = Column(String(50), ForeignKey("language_lessons.id"), nullable=False)
    type = Column(SQLEnum(ExerciseType), nullable=False)
    order = Column(Integer, default=0)

    # Questions (bilingual)
    question_vi = Column(String(500), nullable=False)
    question_en = Column(String(500), nullable=False)

    # Correct answer(s)
    # For multiple_choice/typing/listen_select: single string
    # For matching/ordering: JSON array
    correct_answer = Column(String(500), nullable=False)

    # Options (JSON)
    # multiple_choice: ["a", "ă", "â", "b"]
    # matching: {"left": ["a", "b"], "right": ["ảnh A", "ảnh B"]}
    # ordering: ["con", "mèo", "đen"]
    options = Column(JSON, nullable=True)

    # Media
    audio_url = Column(String(500), nullable=True)       # For listen_select
    image_url = Column(String(500), nullable=True)       # Optional image

    # Hints shown after wrong answer
    hint_vi = Column(String(300), nullable=True)
    hint_en = Column(String(300), nullable=True)

    # Metadata
    max_attempts = Column(Integer, default=3)
    points = Column(Integer, default=10)                  # Base points for correct

    lesson = relationship("LanguageLesson", back_populates="exercises")
```

### Modified: LanguageLesson (add relationship)

```python
class LanguageLesson(Base):
    __tablename__ = "language_lessons"
    # ... existing columns ...
    exercises = relationship("LanguageExercise", back_populates="lesson", order_by="LanguageExercise.order")
```

### New Pydantic Schemas

```python
# backend/language/src/schemas.py

class ExerciseOption(BaseModel):
    """For multiple choice / matching / ordering"""
    value: str
    image_url: Optional[str] = None
    audio_url: Optional[str] = None

class ApiExercise(BaseModel):
    id: str
    type: str  # "multiple_choice" | "typing" | "matching" | "listen_select" | "ordering"
    order: int
    question_vi: str
    question_en: str
    options: Optional[List[ExerciseOption]] = None
    audio_url: Optional[str] = None
    image_url: Optional[str] = None
    hint_vi: Optional[str] = None
    hint_en: Optional[str] = None
    max_attempts: int = 3

class LessonDetail(BaseModel):
    """Full lesson with exercises"""
    id: str
    title_vi: str
    title_en: str
    description_vi: Optional[str] = None
    description_en: Optional[str] = None
    subject_id: str
    sub_subject_id: Optional[str] = None
    grade: int
    order: int
    exercises: List[ApiExercise]
```

---

## API Changes

### Modified: GET /api/language/lesson/{lesson_id}

Currently returns lesson metadata. Extend to include exercises.

```python
@router.get("/lesson/{lesson_id}", response_model=ApiResponse)
async def get_lesson(lesson_id: str, db: AsyncSession = Depends(get_db)):
    # Fetch lesson
    lesson_result = await db.execute(
        select(LanguageLesson).where(LanguageLesson.id == lesson_id)
    )
    lesson = lesson_result.scalar_one_or_none()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")

    # Fetch exercises
    exercise_result = await db.execute(
        select(LanguageExercise).where(LanguageExercise.lesson_id == lesson_id)
        .order_by(LanguageExercise.order)
    )
    exercises = exercise_result.scalars().all()

    data = LessonDetail(
        id=lesson.id,
        title_vi=lesson.title_vi,
        title_en=lesson.title_en,
        description_vi=lesson.description_vi,
        description_en=lesson.description_en,
        subject_id=lesson.subject_id,
        sub_subject_id=lesson.sub_subject_id,
        grade=lesson.grade,
        order=lesson.order,
        exercises=[
            ApiExercise(
                id=e.id,
                type=e.type.value,
                order=e.order,
                question_vi=e.question_vi,
                question_en=e.question_en,
                options=[ExerciseOption(value=o) for o in e.options] if e.options else None,
                audio_url=e.audio_url,
                image_url=e.image_url,
                hint_vi=e.hint_vi,
                hint_en=e.hint_en,
                max_attempts=e.max_attempts,
            )
            for e in exercises
        ]
    )
    return ApiResponse(data=data.model_dump())
```

### Modified: POST /api/language/validate

Support all exercise types.

```python
@router.post("/validate", response_model=ApiResponse)
async def validate_answer(
    exercise_id: str = Body(...),
    user_answer: Union[str, List[str]] = Body(...),  # String or array
    db: AsyncSession = Depends(get_db)
):
    exercise = await db.get(LanguageExercise, exercise_id)
    if not exercise:
        raise HTTPException(status_code=404, detail="Exercise not found")

    is_correct = False

    if exercise.type == ExerciseType.multiple_choice:
        is_correct = str(user_answer).strip().lower() == exercise.correct_answer.strip().lower()

    elif exercise.type == ExerciseType.typing:
        # Allow diacritic-insensitive comparison for Vietnamese
        is_correct = normalize_vietnamese(str(user_answer)) == normalize_vietnamese(exercise.correct_answer)

    elif exercise.type == ExerciseType.matching:
        # user_answer: [["a", "ảnh A"], ["b", "ảnh B"]]
        correct_pairs = json.loads(exercise.correct_answer)  # [["a", "ảnh A"], ["b", "ảnh B"]]
        user_pairs = user_answer if isinstance(user_answer, list) else json.loads(user_answer)
        is_correct = sorted(user_pairs) == sorted(correct_pairs)

    elif exercise.type == ExerciseType.listen_select:
        is_correct = str(user_answer).strip().lower() == exercise.correct_answer.strip().lower()

    elif exercise.type == ExerciseType.ordering:
        correct_order = json.loads(exercise.correct_answer)  # ["con", "mèo", "đen"]
        user_order = user_answer if isinstance(user_answer, list) else json.loads(user_answer)
        is_correct = user_order == correct_order

    return ApiResponse(data={
        "is_correct": is_correct,
        "correct_answer": exercise.correct_answer,
        "hint_vi": exercise.hint_vi if not is_correct else None,
        "hint_en": exercise.hint_en if not is_correct else None,
    })
```

---

## Content Creation Strategy

### Approach: AI-Generate + Manual Review

1. **Generate content JSON** using a script with GPT-4 / Claude
2. **Review and fix** by hand (especially Vietnamese diacritics)
3. **Bulk insert** via SQL migration
4. **Generate audio** via gTTS (pre-generate to MinIO for speed)

### Content Generator Script (Python)

```python
# scripts/generate_language_content.py
# Input: sub_subject_id, grade, count
# Output: JSON array of {lesson, exercises[]}

LESSON_TEMPLATES = {
    "vn_letters": {
        "lessons": [
            {"title_vi": "Chữ cái a, ă, â", "title_en": "Letters a, ă, â",
             "exercises": [
                 {"type": "multiple_choice", "question": "Chọn chữ 'a'", "options": ["a", "ă", "â", "b"], "correct": "a"},
                 {"type": "typing", "question": "Gõ chữ 'ă'", "correct": "ă"},
                 {"type": "listen_select", "question": "Nghe và chọn", "audio": "a.mp3", "options": ["a", "ă", "â"], "correct": "a"},
             ]},
            # ... 9 more lessons
        ]
    }
}
```

### Audio Generation Pipeline

```python
# scripts/generate_audio.py
from gtts import gTTS
import os

WORDS = ["a", "ă", "â", "con mèo", "bông hoa", "This is a cat"]

for word in WORDS:
    # Vietnamese
    tts_vi = gTTS(text=word, lang='vi')
    tts_vi.save(f"audio/vi/{word}.mp3")

    # English
    tts_en = gTTS(text=word, lang='en')
    tts_en.save(f"audio/en/{word}.mp3")
```

Upload to MinIO, store URLs in `audio_url` column.

---

## Grade 1 Content Map

### Vietnamese (50 lessons, 10 per sub-subject)

| Sub-Subject | Lesson Topics | Exercise Types |
|-------------|---------------|----------------|
| **vn_letters** (10) | a-ă-â, e-ê, i-y, o-ô-ơ, u-ư, d-đ, b-c, l-m-n, p-q-r, s-t-v | multiple_choice, typing, listen_select |
| **vn_syllables** (10) | ba-be-bi, bo-bu-bă, đa-đi-đo, ca-co-cu, ga-go-gi, ha-hi-ho, la-li-lu, ma-mi-mu, na-ni-nu, sa-si-su | multiple_choice, ordering, listen_select |
| **vn_words** (10) | colors (màu), animals (động vật), family (gia đình), food (đồ ăn), school (trường học), body (cơ thể), nature (thiên nhiên), numbers (số), actions (hành động), adjectives (tính từ) | matching, multiple_choice, typing |
| **vn_sentences** (8) | "Đây là...", "Tôi thích...", "Có bao nhiêu...", "Màu gì...", "Ai đang...", "Ở đâu...", "Khi nào...", "Tại sao..." | ordering, typing, multiple_choice |
| **vn_reading** (2) | Short paragraph (5-7 sentences), Picture story comprehension | multiple_choice, listen_select |

### English (50 lessons, 10 per sub-subject)

| Sub-Subject | Lesson Topics | Exercise Types |
|-------------|---------------|----------------|
| **en_letters** (10) | A-D, E-H, I-L, M-P, Q-T, U-W, X-Z, Upper/Lower, Vowels, Consonants | multiple_choice, typing, listen_select |
| **en_phonics** (8) | C-A-T, D-O-G, B-A-T, P-I-G, S-U-N, R-U-N, B-I-G, H-O-T | ordering, listen_select, multiple_choice |
| **en_sight_words** (8) | the/a/I, you/is/are, go/come/have, see/look/find, play/run/jump, big/small/tall, red/blue/green, happy/sad/angry | matching, multiple_choice, typing |
| **en_sentences** (8) | "This is a...", "I like...", "How many...", "What color...", "Who is...", "Where is...", "When do...", "Why do..." | ordering, typing, multiple_choice |
| **en_reading** (2) | Short paragraph (5-7 sentences), Picture story comprehension | multiple_choice, listen_select |

---

## Frontend Changes

### Modified: LanguageLessonScreen

Current: Displays lesson content. Need to add exercise state machine.

```dart
class LanguageLessonScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String lessonId;

  const LanguageLessonScreen({required this.subjectId, required this.lessonId});
}

class _LanguageLessonScreenState extends ConsumerState<LanguageLessonScreen> {
  List<ApiExercise> _exercises = [];
  int _currentExerciseIndex = 0;
  int _attempts = 0;
  bool _showingHint = false;
  bool _isCorrect = false;

  // Exercise renderers
  Widget _buildExercise(ApiExercise exercise) {
    switch (exercise.type) {
      case 'multiple_choice':
        return MultipleChoiceExercise(
          exercise: exercise,
          onAnswer: _handleAnswer,
        );
      case 'typing':
        return TypingExercise(
          exercise: exercise,
          onAnswer: _handleAnswer,
        );
      case 'matching':
        return MatchingExercise(
          exercise: exercise,
          onAnswer: _handleAnswer,
        );
      case 'listen_select':
        return ListenSelectExercise(
          exercise: exercise,
          onAnswer: _handleAnswer,
        );
      case 'ordering':
        return OrderingExercise(
          exercise: exercise,
          onAnswer: _handleAnswer,
        );
      default:
        return Text('Unknown exercise type: ${exercise.type}');
    }
  }

  void _handleAnswer(dynamic answer) async {
    final exercise = _exercises[_currentExerciseIndex];
    final result = await LanguageApi.validateAnswer(exercise.id, answer);

    setState(() {
      _isCorrect = result['is_correct'];
      if (!_isCorrect) {
        _attempts++;
        _showingHint = _attempts >= 1; // Show hint after 1 wrong attempt
      }
    });

    if (_isCorrect) {
      _moveToNextExercise();
    }
  }

  void _moveToNextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _attempts = 0;
        _showingHint = false;
        _isCorrect = false;
      });
    } else {
      // Lesson complete → navigate to celebration
      context.go('/celebration?subjectId=${widget.subjectId}&lessonId=${widget.lessonId}');
    }
  }
}
```

### New Widget: MultipleChoiceExercise

```dart
class MultipleChoiceExercise extends StatelessWidget {
  final ApiExercise exercise;
  final Function(String) onAnswer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Question text (bilingual based on locale)
        Text(_resolveQuestion(exercise)),
        // Audio button if listen_select
        if (exercise.audio_url != null)
          AudioButton(url: exercise.audio_url!),
        // Option cards (2-4)
        Wrap(
          spacing: 16,
          children: exercise.options!.map((opt) => 
            GestureDetector(
              onTap: () => onAnswer(opt.value),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(opt.value, style: TextStyle(fontSize: 24)),
                ),
              ),
            ),
          ).toList(),
        ),
      ],
    );
  }
}
```

### New Widget: TypingExercise

```dart
class TypingExercise extends StatefulWidget {
  final ApiExercise exercise;
  final Function(String) onAnswer;

  @override
  _TypingExerciseState createState() => _TypingExerciseState();
}

class _TypingExerciseState extends State<TypingExercise> {
  String _input = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_resolveQuestion(widget.exercise)),
        // Display input
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(_input, style: TextStyle(fontSize: 32)),
        ),
        // On-screen keyboard (vietnamese/english adaptive)
        OnScreenKeyboard(
          language: widget.exercise.subject_id == 'vietnamese' ? 'vi' : 'en',
          onKeyTap: (key) => setState(() => _input += key),
          onBackspace: () => setState(() => _input = _input.substring(0, max(0, _input.length - 1))),
        ),
        // Submit button
        ElevatedButton(
          onPressed: () => widget.onAnswer(_input),
          child: Text('Kiểm tra / Check'),
        ),
      ],
    );
  }
}
```

### New Widget: MatchingExercise

```dart
class MatchingExercise extends StatefulWidget {
  final ApiExercise exercise;
  final Function(List<List<String>>) onAnswer;
}

// Logic: Display left column and right column
// User taps one from left, one from right → pair formed
// When all paired, submit
```

### New Widget: OrderingExercise

```dart
class OrderingExercise extends StatefulWidget {
  final ApiExercise exercise;
  final Function(List<String>) onAnswer;
}

// Logic: Show shuffled words as draggable/tappable chips
// User taps to add to answer row, taps in answer row to remove
// Submit when answer row has all words
```

### New Widget: ListenSelectExercise

```dart
class ListenSelectExercise extends StatelessWidget {
  final ApiExercise exercise;
  final Function(String) onAnswer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Big audio play button
        AudioButton(
          url: exercise.audio_url!,
          size: 80,
          autoPlay: true,
        ),
        // Option cards
        Wrap(
          children: exercise.options!.map((opt) => 
            GestureDetector(
              onTap: () => onAnswer(opt.value),
              child: Card(child: Text(opt.value)),
            ),
          ).toList(),
        ),
      ],
    );
  }
}
```

### Modified: CelebrationScreen

Add language-specific route handling:
- After language lesson completion, "Next lesson" button should navigate to next lesson within same sub-subject
- Show sub-subject progress: "Chữ cái: 8/10 bài" / "Letters: 8/10 lessons"

---

## Day-by-Day Breakdown

### Week 1: Backend Infrastructure + Content Generation

| Day | Task | Files | Deliverable |
|-----|------|-------|-------------|
| **1** | Add ExerciseType enum + LanguageExercise model | `models.py`, `schemas.py` | DB table created |
| **1** | Add exercises relationship to LanguageLesson | `models.py` | ORM relationship |
| **2** | Extend `/lesson/{id}` to include exercises | `curriculum.py` | API returns full lesson |
| **2** | Extend `/validate` for all exercise types | `curriculum.py` | Validation works |
| **3** | Write content generator script | `scripts/generate_vn_content.py` | 50 VN lessons JSON |
| **3** | Generate Vietnamese content (letters + syllables) | `scripts/` | 20 lessons ready |
| **4** | Generate Vietnamese content (words + sentences + reading) | `scripts/` | 30 lessons ready |
| **4** | Generate English content | `scripts/generate_en_content.py` | 50 EN lessons JSON |
| **5** | Review + fix Vietnamese diacritics | Manual | Content verified |
| **5** | Write migration SQL for all 100 lessons + exercises | `migrations/008_exercises.sql` | Ready to apply |

### Week 2: Frontend Exercise Widgets + Integration

| Day | Task | Files | Deliverable |
|-----|------|-------|-------------|
| **6** | MultipleChoiceExercise widget | `widgets/multiple_choice_exercise.dart` | Renders options, handles tap |
| **6** | TypingExercise + OnScreenKeyboard | `widgets/typing_exercise.dart`, `widgets/on_screen_keyboard.dart` | Keyboard renders, input captured |
| **7** | MatchingExercise widget | `widgets/matching_exercise.dart` | Pair matching logic |
| **7** | OrderingExercise widget | `widgets/ordering_exercise.dart` | Chip ordering |
| **8** | ListenSelectExercise + AudioButton | `widgets/listen_select_exercise.dart`, `widgets/audio_button.dart` | Audio plays, selection works |
| **8** | Integrate into LanguageLessonScreen | `language_lesson_screen.dart` | Exercise state machine |
| **9** | Exercise progress indicator + transitions | `language_lesson_screen.dart` | "Exercise 1 of 3" shows |
| **9** | Hint display + wrong answer feedback | `language_lesson_screen.dart` | Hint shown after wrong |
| **10** | CelebrationScreen language routing | `celebration_screen.dart` | "Next lesson" goes to next in sub-subject |

### Week 3: Audio, Polish, Testing

| Day | Task | Files | Deliverable |
|-----|------|-------|-------------|
| **11** | Audio generation pipeline | `scripts/generate_audio.py` | MP3 files for all exercises |
| **11** | Upload audio to MinIO | `scripts/upload_audio.py` | URLs stored in DB |
| **12** | Update DB audio URLs | `migrations/009_audio_urls.sql` | Exercises have audio |
| **12** | Mobile responsiveness pass | All exercise widgets | Works on 320px width |
| **13** | Integration testing: VN letters end-to-end | Manual | Complete lesson flow works |
| **13** | Integration testing: EN phonics end-to-end | Manual | Complete lesson flow works |
| **14** | Bug fixes from testing | Various | All critical issues fixed |
| **14** | Deploy to production | `docker-compose.prod.yml` | Live on sekklings.com |

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Vietnamese diacritic errors in content | High | High | Generate with GPT-4, manual review by native speaker |
| gTTS audio quality poor | Medium | Medium | Pre-generate, test with children, fallback to recorded audio if needed |
| Typing on mobile is hard for 5-year-olds | High | High | Make on-screen keyboard large, support tap-to-complete for early lessons |
| 100 lessons × 3 exercises = too much content | Medium | Medium | Start with 50 lessons (Grade 1 only), add Grade 2/3 later |
| Exercise widgets too complex | Medium | High | Build simple versions first, add animations/polish later |
| DB migration fails on production | Low | Critical | Test migration on staging DB first, have rollback script |

---

## Success Criteria

- [x] Child can tap "Vietnamese" → see 5 sub-subjects → tap "Chữ cái" → see 10 lessons → tap lesson → complete 2-3 exercises → see celebration
- [x] Same flow works for English
- [x] Wrong answers show hint, allow retry
- [x] Audio plays for listen_select exercises (via TTS fallback)
- [~] On-screen keyboard works on mobile (native keyboard used instead of dedicated widget)
- [x] All 100 Grade 1 lessons have at least 2 exercises (100 lessons, 266 exercises total)
- [~] No console errors during lesson flow (needs browser testing)
- [x] Production API response time < 500ms for lesson detail (~100ms)

---

## Files Modified/Created Summary

### Backend (12 files)
1. `backend/language/src/models.py` — Add ExerciseType enum, modify LanguageExercise
2. `backend/language/src/schemas.py` — Add ApiExercise, LessonDetail schemas
3. `backend/language/src/router/curriculum.py` — Extend /lesson/{id}, /validate
4. `backend/language/migrations/007_exercises.sql` — Create exercises table + seed 100 lessons
5. `backend/language/migrations/008_audio_urls.sql` — Add audio URLs
6. `scripts/generate_vn_content.py` — Vietnamese content generator
7. `scripts/generate_en_content.py` — English content generator
8. `scripts/generate_audio.py` — Audio generation
9. `scripts/upload_audio.py` — MinIO upload

### Frontend (12 files)
10. `frontend/lib/screens/language_lesson_screen.dart` — Exercise state machine
11. `frontend/lib/widgets/multiple_choice_exercise.dart` — New
12. `frontend/lib/widgets/typing_exercise.dart` — New
13. `frontend/lib/widgets/on_screen_keyboard.dart` — New
14. `frontend/lib/widgets/matching_exercise.dart` — New
15. `frontend/lib/widgets/ordering_exercise.dart` — New
16. `frontend/lib/widgets/listen_select_exercise.dart` — New
17. `frontend/lib/widgets/audio_button.dart` — New
18. `frontend/lib/screens/celebration_screen.dart` — Modify routing
19. `frontend/lib/services/language_api.dart` — Add validateAnswer method
20. `frontend/lib/models/exercise_model.dart` — New (or extend existing)

### DevOps (2 files)
21. `frontend/Dockerfile` — No changes expected
22. `docker-compose.prod.yml` — No changes expected

---

## Pre-Implementation Checklist

Before starting Phase 2:

- [ ] Phase 1 (Unlocking) is deployed and stable
- [ ] Parent dashboard mockups approved (for Phase 3 alignment)
- [ ] Audio generation budget approved (gTTS is free but slow; AWS Polly or ElevenLabs have costs)
- [ ] Native Vietnamese speaker available for 2-3 hours of content review
- [ ] Test device available (old Android phone or iPad for mobile testing)
- [ ] MinIO bucket for audio assets created

---

## Notes

- **Audio strategy**: For MVP, use gTTS (free) generated during build and stored in MinIO. For production quality later, switch to AWS Polly or record native speaker audio.
- **Keyboard layout**: Vietnamese needs tone marks. On-screen keyboard should show base letters + tone mark selector, or use dead-key style input.
- **Accessibility**: All exercise options should be large enough for small fingers (min 48×48dp tap target).
- **Offline support**: Not in scope for Phase 2. All audio and images load from CDN/MinIO.

# Plan: Language Sub-Subject Content, Unlocking & Parent Dashboard

## Overview

Three features that complete the language learning flow from curriculum navigation → content → progression → parent visibility.

| # | Feature | Effort | Risk | Value |
|---|---------|--------|------|-------|
| 1 | Real lesson content (Vietnamese + English) | High | Medium (content creation) | Critical |
| 2 | Sub-subject unlocking | Medium | Low | High |
| 3 | Parent dashboard breakdown | Medium | Low | High |

**Recommended order**: 2 → 1 → 3. Unlocking logic should exist before content arrives, and parent dashboard needs both to be meaningful.

---

## Feature 1: Real Lesson Content for Language Sub-Subjects

### What
Replace placeholder/empty lessons in Vietnamese and English sub-subjects with interactive exercises children can actually complete.

### Current State
- DB has 80 Vietnamese + 110 English lessons (grades 1-3)
- `LanguageLesson` and `LanguageExercise` tables exist
- `LanguageLessonScreen` exists in frontend but may not support all needed exercise types
- Only basic exercise types are implemented in the language service

### Deliverables

#### Backend
1. **Exercise type definitions** — add to `language/src/models.py`:
   - `multiple_choice` — select correct answer from 2-4 options
   - `typing` — type letters/words with TTS audio playback
   - `matching` — drag-and-drop or tap-to-pair (e.g., letter + image)
   - `listen_select` — hear audio, select matching word/image
   - `tracing` — trace letter shapes (Canvas-based, frontend-heavy)
   - `ordering` — arrange syllables/words in correct order

2. **Exercise validation** — extend `language/src/router/curriculum.py`:
   - `POST /api/language/validate` already exists, extend for new exercise types
   - Store correct answer hashes, acceptable variants (e.g., "a" vs "ă")
   - Add distractor generation for multiple choice

3. **Lesson seed data** — create migration or seed script:
   - Vietnamese (Grade 1): 10 lessons × 5 sub-subjects = 50 lessons
   - English (Grade 1): 10 lessons × 5 sub-subjects = 50 lessons
   - Each lesson: 2-3 exercises, progressive difficulty within sub-subject

#### Frontend
1. **Extend `LanguageLessonScreen`** to render new exercise types:
   - Multiple choice card grid
   - Typing input with on-screen keyboard (mobile-friendly)
   - Matching pairs with flip animation
   - Audio playback button with visual feedback

2. **Add exercise progress indicator** — show "Exercise 1 of 3" during lesson

3. **Celebration flow** — after last exercise, show stars + "Next lesson" button

### Data Model (proposed)

```
LanguageExercise:
  - id: str (e.g., "vn_l01_e01")
  - lesson_id: str (FK)
  - type: enum [multiple_choice, typing, matching, listen_select, ordering]
  - question_vi: str
  - question_en: str
  - correct_answer: str (or JSON for complex types)
  - options: JSON (for multiple_choice / matching)
  - audio_url: str (optional, for listen_select)
  - hint_vi: str
  - hint_en: str
  - order: int
```

### Content Plan (Grade 1)

| Sub-Subject | Vietnamese Lessons | English Lessons |
|-------------|-------------------|-----------------|
| Letters/Alphabet | 10: a-ă-â, o-ô-ơ, e-ê, u-ư, i-y, d-đ, b-c, l-m-n, p-q-r, s-t-v | 10: A-D, E-H, I-L, M-P, Q-T, U-W, X-Z, Upper/Lower case, Vowels, Consonants |
| Syllables/Phonics | 10: ba, be, bi, bo, bu, bă, bê, bơ, đa, đi | 8: C-A-T, D-O-G, B-A-T, P-I-G, S-U-N, R-U-N, B-I-G, H-O-T |
| Vocabulary/Sight Words | 10: colors, animals, family, food, school, body, nature, numbers (words), actions, adjectives | 8: the, a, I, you, is, are, go, come |
| Sentences | 8: "Đây là...", "Tôi thích...", "Có bao nhiêu...", "Màu gì...", "Ai đang...", "Ở đâu...", "Khi nào...", "Tại sao..." | 8: "This is a...", "I like...", "How many...", "What color...", "Who is...", "Where is...", "When do...", "Why do..." |
| Reading | 2: Short paragraph (5-7 sentences), Picture story comprehension | 2: Short paragraph, Picture story |

### Effort Estimate
- Backend exercise types + validation: 2-3 days
- Content creation (100 lessons × 2-3 exercises): 3-4 days
- Frontend exercise renderers: 3-4 days
- **Total: 8-11 days**

---

## Feature 2: Sequential Sub-Subject Unlocking

### What
Children must complete a threshold percentage of lessons in one sub-subject before the next sub-subject unlocks. This creates a guided learning path instead of showing everything at once.

### Current State
- All sub-subjects visible immediately
- `userProgressProvider` tracks completed lesson IDs
- No per-sub-subject completion logic

### Deliverables

#### Backend
1. **New endpoint** `GET /api/language/progress/sub-subjects`:
   - Input: `user_id`, `subject_id` (vietnamese/english), `grade`
   - Output: array of sub-subjects with `is_unlocked`, `completion_pct`, `stars_earned`
   - Unlock rule: previous sub-subject has ≥ 80% lessons completed
   - First sub-subject always unlocked

2. **Or extend existing** `/api/language/progress` to include sub-subject aggregation

3. **Progress tracking** — ensure `LanguageApi.updateProgress()` stores correctly

#### Frontend
1. **Update `SubjectScreen._buildSubSubjectList()`**:
   - Pass `isUnlocked` to each sub-subject card
   - Locked cards: overlay 🔒 icon, reduced opacity (0.5), disabled tap
   - Unlocked cards: full color, tap navigates to `/subject/:subjectId/:subSubjectId`

2. **Unlock animation** — when a sub-subject becomes unlocked (after completing a lesson):
   - Show brief confetti / star burst on the home screen or subject screen
   - Toast: "🎉 Ghép vần đã mở khóa!" / "🎉 Syllables unlocked!"

3. **Progress indicator on cards**:
   - Mini progress bar: "7/10" or circular percentage
   - Stars earned per sub-subject

### Unlock Rules (configurable)

```dart
static const double _unlockThreshold = 0.8; // 80%

bool isSubSubjectUnlocked(int index, List<Map<String, dynamic>> subSubjects) {
  if (index == 0) return true; // First always unlocked
  final prev = subSubjects[index - 1];
  final completed = prev['completed_lessons'] as int;
  final total = prev['lesson_count'] as int;
  return completed / total >= _unlockThreshold;
}
```

### Effort Estimate
- Backend progress aggregation: 1 day
- Frontend locked/unlocked UI: 1-2 days
- Unlock animation + toast: 0.5 day
- **Total: 2.5-3.5 days**

---

## Feature 3: Parent Dashboard Sub-Subject Breakdown

### What
Parents can see granular progress per sub-subject, not just per top-level subject. This helps them understand exactly where their child excels or struggles.

### Current State
- `ParentDashboardScreen` shows subject-level progress bars
- `PinGateScreen` guards access
- No sub-subject visibility

### Deliverables

#### Backend
1. **Extend progress API** to return sub-subject breakdown:
   - `GET /api/progress/detailed?user_id={id}` or extend existing
   - For each subject (math, vietnamese, english):
     - Sub-subjects array: name, total_lessons, completed_lessons, stars_earned, avg_attempts, last_active
   - Aggregate streak, daily activity, weak areas

2. **Time tracking** (optional, nice-to-have):
   - Track seconds spent per lesson
   - Aggregate per sub-subject, per day

#### Frontend
1. **New widget**: `SubSubjectProgressCard`:
   - Horizontal bar with % completion + color-coded (sub-subject color)
   - "⭐ 24/30 stars" text
   - "Last practiced: 2 days ago"
   - Tap to expand: list of recent lessons with star ratings

2. **Update `ParentDashboardScreen`**:
   - Replace or augment current subject-level bars
   - Collapsible sections: "Tiếng Việt ▼" → shows 5 sub-subject cards
   - Add toggle: "Show by subject / Show by sub-subject"

3. **Weak areas highlight**:
   - If completion < 50% and last active > 7 days → yellow warning card
   - If avg attempts > 3 per lesson → "Needs practice" badge

### Data Model

```json
{
  "subject_id": "vietnamese",
  "subject_name": "Tiếng Việt",
  "sub_subjects": [
    {
      "id": "vn_letters",
      "name_vi": "Chữ cái",
      "name_en": "Letters",
      "color": "#FFE0E0",
      "total_lessons": 10,
      "completed_lessons": 7,
      "stars_earned": 20,
      "max_stars": 30,
      "avg_attempts": 1.4,
      "last_active": "2026-06-03T10:00:00Z"
    }
  ]
}
```

### Effort Estimate
- Backend detailed progress aggregation: 1-2 days
- Frontend `SubSubjectProgressCard` widget: 1-2 days
- Dashboard layout + toggle: 1 day
- Weak areas logic: 0.5 day
- **Total: 3.5-5.5 days**

---

## Execution Order

| Phase | Feature | Duration | Dependencies |
|-------|---------|----------|------------|
| 1 | **Sub-subject unlocking** (Feature 2) | 3 days | None |
| 2 | **Real lesson content** (Feature 1) | 10 days | Phase 1 complete |
| 3 | **Parent dashboard** (Feature 3) | 4 days | Phase 1 + 2 |
| | **Total** | **~17 days** | |

## Files to Modify

### Feature 1 (Content)
- `math-app/backend/language/src/models.py` — add exercise types
- `math-app/backend/language/src/schemas.py` — exercise schemas
- `math-app/backend/language/src/router/curriculum.py` — validation logic
- `math-app/backend/language/migrations/007_exercises.sql` — seed data
- `math-app/frontend/lib/screens/language_lesson_screen.dart` — exercise renderers
- `math-app/frontend/lib/widgets/exercise/` — new exercise widgets

### Feature 2 (Unlocking)
- `math-app/backend/language/src/router/progress.py` (new or existing)
- `math-app/backend/language/src/schemas.py` — progress schemas
- `math-app/frontend/lib/screens/subject_screen.dart` — locked/unlocked cards
- `math-app/frontend/lib/screens/home_screen.dart` — unlock toast/animation

### Feature 3 (Dashboard)
- `math-app/backend/progress/src/router.rs` or `language/src/router/progress.py` — detailed endpoint
- `math-app/frontend/lib/screens/parent_dashboard_screen.dart` — layout update
- `math-app/frontend/lib/widgets/sub_subject_progress_card.dart` — new widget

## Open Questions

1. **Audio assets**: Do we generate TTS on-demand (current GTTS) or pre-generate and store in MinIO? Pre-generation is faster for children.
2. **Exercise difficulty**: Should exercises within a sub-subject get harder progressively, or stay uniform?
3. **Tracing exercises**: These need CustomPaint — is the complexity worth it for MVP, or defer to v2?
4. **Time tracking**: Add now or defer? Requires new DB column.
5. **Content creation**: Who creates the 100+ lessons? AI-assisted generation + manual review is fastest.

## Recommendation

Start **Feature 2 (Unlocking)** immediately — it's low risk, high value, and sets up the progression framework. Then build **Feature 1 (Content)** in parallel with content creation. **Feature 3 (Dashboard)** can be built while content is being created, since it only needs the progress data structures from Feature 2.

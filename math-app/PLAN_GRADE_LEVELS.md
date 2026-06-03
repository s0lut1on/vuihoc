# Implementation Plan: Grade Levels (Grade 2 + Grade 3)

## Overview

Add **Grade 2** (ages 7–8) and **Grade 3** (ages 8–9) to the existing **6 subjects**:
- **Math**: `numbers`, `geometry`, `measurement`, `logic` (in `content-service`)
- **Language**: `vietnamese`, `english` (in `language-service`)

**Architecture**: Same subjects, higher difficulty. The **6 subject cards on HomeScreen are always visible** regardless of grade. Only the lessons inside each subject change based on the user's grade.

**Example**: A Grade 2 user taps "Numbers" and sees 50 harder lessons (2-digit addition, multiplication). A Grade 1 user taps "Numbers" and sees the original 40 basic lessons. The subject card itself never changes.

**Lesson ID Convention**: All lesson IDs must include grade prefix to avoid primary key collisions:
- Grade 1: `g1_lesson_n01`, `g1_lesson_n02`... (existing IDs can remain as-is for backward compatibility)
- Grade 2: `g2_lesson_n01`, `g2_lesson_n02`...
- Grade 3: `g3_lesson_n01`, `g3_lesson_n02`...

---

## Subject Scope Per Grade

### Grade 1 (ages 5–7) — EXISTING
| Subject | Focus | Lessons |
|---------|-------|---------|
| Numbers | Counting, addition/subtraction 1–10, number recognition | 40 |
| Geometry | Basic 2D shapes, spatial awareness | 40 |
| Measurement | Length (long/short), weight (heavy/light), time (hour) | 40 |
| Logic | Simple patterns, sorting, matching | 40 |
| Vietnamese | Alphabet, simple words, pronunciation | 40 |
| English | ABCs, colors, numbers 1–20, greetings | 40 |
| **Total** | | **240** |

### Grade 2 (ages 7–8) — NEW
| Subject | Focus | Lessons |
|---------|-------|---------|
| Numbers | 2-digit +/- with carrying, multiplication tables (2×, 5×, 10×), simple word problems | 50 |
| Geometry | 3D shapes, symmetry, perimeter basics | 45 |
| Measurement | Length (cm/m), weight (kg/g), time (minutes, half-hour), money (VND) | 45 |
| Logic | Multi-step patterns, Venn diagrams, sorting by multiple criteria, basic Sudoku | 45 |
| Vietnamese | Compound words, sentence building, reading short passages, tone rules | 50 |
| English | Vocabulary expansion, simple grammar (he/she), short sentences, listening | 50 |
| **Total** | | **285** |

### Grade 3 (ages 8–9) — NEW
| Subject | Focus | Lessons |
|---------|-------|---------|
| Numbers | Multiplication/division, fractions basics, decimals, 3-digit +/- | 55 |
| Geometry | Area basics, angles, coordinates, mirror symmetry | 50 |
| Measurement | Volume (L/mL), area (cm²), time (quarter-hour, elapsed time), speed basics | 50 |
| Logic | Multi-step reasoning, set theory basics, logical operators (AND/OR), chess puzzles | 50 |
| Vietnamese | Paragraph reading, grammar rules, writing composition, synonyms/antonyms | 55 |
| English | Past tense, plural forms, longer reading passages, conversation practice | 55 |
| **Total** | | **315** |

**Grand Total: 240 (G1) + 285 (G2) + 315 (G3) = 840 lessons**

---

## Phase 1: Database Schema (1–2 days)

### 1.1 Content Service Migrations

**File:** `backend/content/migrations/005_grade_levels.sql`

```sql
-- Add grade range to subjects table (controls which grades see this subject card)
ALTER TABLE subjects ADD COLUMN IF NOT EXISTS grade_min INT NOT NULL DEFAULT 1;
ALTER TABLE subjects ADD COLUMN IF NOT EXISTS grade_max INT NOT NULL DEFAULT 1;

-- Add grade column to lessons (controls which lessons load for this grade)
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS grade INT NOT NULL DEFAULT 1;

-- Create index for grade filtering
CREATE INDEX IF NOT EXISTS idx_lessons_grade ON lessons(grade);

-- Backfill existing data
UPDATE subjects SET grade_min = 1, grade_max = 3 WHERE id IN ('numbers', 'geometry', 'measurement', 'logic');
UPDATE lessons SET grade = 1;

-- IMPORTANT: lesson_order must be filtered by grade
-- Without WHERE grade = X, ORDER BY lesson_order mixes all grades!
-- Example query: SELECT * FROM lessons WHERE subject_id = 'numbers' AND grade = 2 ORDER BY lesson_order
```

**File:** `backend/content/migrations/006_grade2_curriculum.sql`
```sql
-- Generate Grade 2 lessons for each math subject
-- (Auto-generated via script from structured curriculum definition)
```

**File:** `backend/content/migrations/007_grade3_curriculum.sql`
```sql
-- Generate Grade 3 lessons for each math subject
```

### 1.2 Language Service Migrations

**File:** `backend/language/migrations/002_grade_levels.sql`

```sql
-- Add grade column to language tables
ALTER TABLE language_subjects ADD COLUMN IF NOT EXISTS grade_min INT NOT NULL DEFAULT 1;
ALTER TABLE language_subjects ADD COLUMN IF NOT EXISTS grade_max INT NOT NULL DEFAULT 1;

ALTER TABLE language_lessons ADD COLUMN IF NOT EXISTS grade INT NOT NULL DEFAULT 1;

-- Create index
CREATE INDEX IF NOT EXISTS idx_language_lessons_grade ON language_lessons(grade);

-- Backfill
UPDATE language_subjects SET grade_min = 1, grade_max = 3 WHERE id IN ('vietnamese', 'english');
UPDATE language_lessons SET grade = 1;
```

**File:** `backend/language/migrations/003_grade2_curriculum.sql`
**File:** `backend/language/migrations/004_grade3_curriculum.sql`

### 1.3 User Service Migration

**File:** `backend/user/migrations/xxx_user_grade.sql`

```sql
-- Add grade to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS grade INT NOT NULL DEFAULT 1;
CREATE INDEX IF NOT EXISTS idx_users_grade ON users(grade);
```

---

## Phase 2: Backend API Changes (1–2 days)

### 2.1 Content Service

**Filter by grade:**
```
GET /api/content/subjects?grade=2
GET /api/content/curriculum?grade=2
GET /api/content/lessons?subject=numbers&grade=2
```

Implementation: Add optional `grade` query param to existing endpoints. Default to 1 if omitted for backward compatibility.

```rust
// In curriculum handler
let grade = query_params.grade.unwrap_or(1);
let lessons = sqlx::query_as::<_, Lesson>(
    "SELECT * FROM lessons WHERE subject_id = $1 AND grade = $2 ORDER BY lesson_order"
)
.bind(subject_id)
.bind(grade)
.fetch_all(&pool)
.await?;
```

### 2.2 Language Service

**Filter by grade:**
```
GET /api/language/subjects?grade=2
GET /api/language/curriculum?grade=2
GET /api/language/lessons?subject=vietnamese&grade=2
```

Same pattern: optional `grade` query param, default to 1.

### 2.3 User Service — Grade Management

```
GET /api/users/me              -- include grade field in response
PATCH /api/users/:id/grade     -- admin/parent can bump grade
GET /api/users/progress?grade=2 -- optional grade-specific progress
```

---

## Phase 3: Question Bank — Grade 2 & 3 Templates (2–3 days)

### Grade 2 Templates
**Directory:** `backend/question_bank/templates/grade2/`

| Template | Example |
|----------|---------|
| `addition_carry.jinja` | "{{a}} + {{b}} = ?" (where sum > 10, requires carrying) |
| `subtraction_borrow.jinja` | "{{a}} - {{b}} = ?" (requires borrowing) |
| `multiplication_intro.jinja` | "2 × {{a}} = ?" (times tables 2, 5, 10) |
| `money_total.jinja` | "💵 + 🪙 = ?đ" (coin arithmetic) |
| `time_half_hour.jinja` | "Clock shows __:30, what time is it?" |
| `length_compare.jinja` | "Which is longer: {{a}}cm or {{b}}cm?" |
| `pattern_next.jinja` | "1, 3, 5, __, __" (multi-step patterns) |
| `venn_sort.jinja` | "Drag animals to correct Venn circle" |

### Grade 3 Templates
**Directory:** `backend/question_bank/templates/grade3/`

| Template | Example |
|----------|---------|
| `multiplication_full.jinja` | "{{a}} × {{b}} = ?" (all tables 1–10) |
| `division_intro.jinja` | "{{a}} ÷ {{b}} = ?" |
| `fraction_visual.jinja` | "What fraction is shaded?" |
| `decimal_intro.jinja` | "0.{{a}} + 0.{{b}} = ?" |
| `area_rectangle.jinja` | "Area = {{length}}cm × {{width}}cm" |
| `volume_liter.jinja` | "Which holds more: {{a}}L or {{b}}L?" |
| `elapsed_time.jinja` | "Class starts at 8:15, ends at 9:00. How long?" |
| `logic_and_or.jinja` | "All fruit is sweet AND red. Is an apple fruit?" |
| `chess_puzzle.jinja" | "Knight to mate in 2 moves" |

**Difficulty mapping:**
- Grade 1: `difficulty = 1`
- Grade 2: `difficulty = 2`
- Grade 3: `difficulty = 3`

---

## Phase 4: Frontend Changes (2–3 days)

### 4.1 Grade Selection in Onboarding

**After** persona selection in `WelcomeScreen`, add grade selection:

```dart
// welcome_screen.dart
Column(
  children: [
    Text("Bé học lớp mấy?"),
    Row(
      children: [
        _gradeButton(1, "Lớp 1 (5-7 tuổi)"),
        _gradeButton(2, "Lớp 2 (7-8 tuổi)"),
        _gradeButton(3, "Lớp 3 (8-9 tuổi)"),
      ],
    ),
  ],
)
```

Store selected grade in `createUser()` call.

### 4.2 l10n Strings

Add to `app_en.arb` and `app_vi.arb`:
```arb
"grade1Label": "Grade 1 (Ages 5-7)",
"grade2Label": "Grade 2 (Ages 7-8)",
"grade3Label": "Grade 3 (Ages 8-9)",
"gradeSelectTitle": "Which grade is your child in?",
"gradeSwitchButton": "Switch Grade",
"gradeLocked": "Complete {percent}% of Grade 1 to unlock",
"gradeProgressTitle": "Grade {grade} Progress"
```

```arb
"grade1Label": "Lớp 1 (5-7 tuổi)",
"grade2Label": "Lớp 2 (7-8 tuổi)",
"grade3Label": "Lớp 3 (8-9 tuổi)",
"gradeSelectTitle": "Bé học lớp mấy?",
"gradeSwitchButton": "Chuyển lớp",
"gradeLocked": "Hoàn thành {percent}% bài lớp 1 để mở khóa",
"gradeProgressTitle": "Tiến độ lớp {grade}"
```

### 4.3 Dynamic Subject Loading (RECOMMENDED)

Replace hardcoded `_subjects` list with grade-aware fetching:

```dart
// In HomeScreen or new SubjectProvider
final userGrade = ref.watch(userProvider).value?.grade ?? 1;

// Fetch subjects for user's grade from BOTH services
final subjectsAsync = ref.watch(gradedSubjectsProvider(userGrade));
```

**Provider implementation:**
```dart
final gradedSubjectsProvider = FutureProvider.family<List<Subject>, int>((ref, grade) async {
  final mathSubjects = await ContentApi.getSubjects(grade: grade);
  final langSubjects = await LanguageApi.getSubjects(grade: grade);
  return [...mathSubjects, ...langSubjects];
});
```

If keeping hardcoded list: add `gradeRange` metadata to each subject:
```dart
static const List<Map<String, dynamic>> _subjects = [
  {
    'id': 'numbers',
    'icon': '🔢',
    'nameVi': 'So hoc',
    'nameEn': 'Numbers',
    'color': 0xFFFFE8F0,
    'gradeMin': 1,
    'gradeMax': 3,
  },
  // ... etc
];
```

### 4.4 SubjectScreen Grade Filter

```dart
// subject_screen.dart
final userGrade = ref.watch(userProvider).value?.grade ?? 1;

// Existing routing stays the same
if (widget.subjectId == 'vietnamese' || widget.subjectId == 'english') {
  _lessons = await LanguageApi.getCurriculum(subjectId: widget.subjectId, grade: userGrade);
} else {
  _lessons = await ContentApi.getCurriculum(subjectId: widget.subjectId, grade: userGrade);
}
```

### 4.4 Settings — Grade Switch (for parents)

Add to `ProfileScreen` or `SettingsScreen`:
```dart
ListTile(
  leading: Icon(Icons.school),
  title: Text("Lớp học"),
  trailing: DropdownButton<int>(
    value: userGrade,
    items: [
      DropdownMenuItem(child: Text("Lớp 1"), value: 1),
      DropdownMenuItem(child: Text("Lớp 2"), value: 2),
      DropdownMenuItem(child: Text("Lớp 3"), value: 3),
    ],
    onChanged: (grade) {
      if (grade != null) {
        UserApi.updateGrade(grade);
        ref.invalidate(subjectsProvider);
      }
    },
  ),
)
```

### 4.5 Locking Lower Grades (Optional)

**Existing users behavior**: All existing users default to `grade = 1`. They can freely switch grades via Settings. No lock mechanism required unless specified.

If implementing grade lock:
- Show warning: "Bé nên hoàn thành 80% lớp 2 trước khi học lớp 3"
- OR: Allow switching but show "recommended grade" indicator
- Decision: **Free switching** (no lock) for maximum flexibility

---

## Phase 5: Curriculum Data Generation (4–5 days)

### 5.1 Auto-Generate SQL Scripts

Write Python generator script that reads from structured YAML/JSON curriculum definitions and outputs SQL INSERT statements.

**File:** `scripts/generate_curriculum.py`

**Input:** `curriculum/grade2_math.yaml`
```yaml
subjects:
  - id: numbers
    lessons:
      - id: g2_n01
        title_vi: "Cộng 2 chữ số (có nhớ)"
        title_en: "2-digit addition (with carrying)"
        grade: 2
        difficulty: 2
        exercises:
          - template: addition_carry.jinja
            params: { a: 25, b: 38 }
      - id: g2_n02
        ...
```

**Output:** `backend/content/migrations/006_grade2_curriculum.sql`

### 5.2 Migration Checklist

- [ ] Grade 2 math: 170 lessons (numbers: 50 + geometry: 45 + measurement: 45 + logic: 45)
- [ ] Grade 2 language: 100 lessons (vietnamese: 50 + english: 50)
- [ ] Grade 3 math: 205 lessons (numbers: 55 + geometry: 50 + measurement: 50 + logic: 50)
- [ ] Grade 3 language: 110 lessons (vietnamese: 55 + english: 55)
- [ ] Total new: 585 lessons

---

## Phase 6: Progress & Unlocking (1 day)

### 6.1 Per-Grade Progress

Option A (Recommended): **Unified progress across grades**
- Completing a Grade 2 `numbers` lesson adds to the same "Numbers" progress bar
- Total "lessons learned" counts across all grades
- This rewards advancing and simplifies UI

Option B: **Separate progress per grade**
- "Numbers Grade 1: 35/40"
- "Numbers Grade 2: 12/50"
- More complex but precise

### 6.2 Lesson Unlocking Within Grades

Within each grade, lessons unlock sequentially:
- Grade 2 `numbers` Lesson 2 unlocks after Lesson 1 is completed
- Cross-grade: Grade 3 does NOT require Grade 2 completion (user can switch freely)

### 6.3 Subject Completion Milestones

After completing 80% of a subject in a grade, show:
- "🎉 Numbers Grade 2 complete! Ready for Grade 3!"
- "⭐ New achievement: Numbers Master (Grade 2)"

---

## Phase 7: E2E Testing (1–2 days)

### Test Scenarios
1. **Grade switching**: User starts in Grade 2, sees harder lessons
2. **Subject API**: `GET /api/content/curriculum?subject=numbers&grade=2` returns Grade 2 lessons only
3. **Progress tracking**: Completing Grade 2 lesson increments total progress
4. **Onboarding flow**: New user selects Grade 2 during signup
5. **Parent switch**: Parent changes grade in settings, UI updates
6. **Language service**: Vietnamese Grade 2 lessons load correctly
7. **Backward compatibility**: Default grade = 1, existing users unaffected

---

## Implementation Order

| Order | Phase | Work | Effort | Files |
|-------|-------|------|--------|-------|
| 1 | **Phase 1** | Schema migrations (content + language + user) | 1–2 days | `005_grade_levels.sql`, `002_grade_levels.sql` |
| 2 | **Phase 2** | Backend API changes (grade query param) | 1–2 days | `content/src/`, `language/src/`, `user/src/` |
| 3 | **Phase 5** | Generate Grade 2 curriculum data | 2–3 days | `006_grade2_curriculum.sql`, `003_grade2_curriculum.sql` |
| 4 | **Phase 5** | Generate Grade 3 curriculum data | 2–3 days | `007_grade3_curriculum.sql`, `004_grade3_curriculum.sql` |
| 5 | **Phase 3** | Question Bank templates (G2 + G3) | 2–3 days | `templates/grade2/`, `templates/grade3/` |
| 6 | **Phase 4** | Frontend: onboarding + HomeScreen + SubjectScreen | 2–3 days | `home_screen.dart`, `subject_screen.dart`, `welcome_screen.dart` |
| 7 | **Phase 6** | Progress aggregation + unlocking logic | 1 day | `progress-service` or frontend |
| 8 | **Phase 7** | E2E tests | 1–2 days | `e2e/tests/grade_levels.spec.ts` |

**Total effort: ~12–19 days**
**Recommended team split:**
- Backend: Phase 1 + 2 + 3 (5–7 days)
- Curriculum writer: Phase 5 (4–6 days, parallel)
- Frontend: Phase 4 (2–3 days, starts after Phase 2)
- QA: Phase 7 (1–2 days, after all above)

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| 585 new lessons = massive SQL files | Build time, review difficulty | Use generator script; split into per-subject SQL files |
| Grade migration breaks existing users | High | `DEFAULT 1` ensures backward compatibility; test with existing user data |
| Frontend subject list grows large | UX | Implement dynamic fetching; add horizontal scroll or category tabs |
| Two services to update (content + language) | Double work | Same pattern in both; copy-paste with table name changes |
| Question Bank templates for G2/G3 are complex | Quality | Start with G2 templates, validate with teachers before G3 |

---

## Post-Implementation

### Monitoring
- Track how many users switch grades
- Measure completion rates per grade
- Monitor API response times with grade filter (ensure index is used)

### Future Extensions
- Grade 4–5 (ages 9–11): Multiplication/division mastery, fractions, geometry angles
- Adaptive difficulty within a grade (BKT already exists in question_bank)
- Grade-specific achievements and certificates

---

## Appendix: Curriculum Content Outline

### Grade 2 Numbers (50 lessons)
1. L1–L10: 2-digit addition with carrying
2. L11–L20: 2-digit subtraction with borrowing
3. L21–L30: Times tables (2×, 5×, 10×)
4. L31–L40: Word problems (shopping, grouping)
5. L41–L50: Mixed practice + introduction to division

### Grade 2 Vietnamese (50 lessons)
1. L1–L10: Compound words (trường học, bàn ghế)
2. L11–L20: Sentence building (Subject + Verb)
3. L21–L30: Reading short passages (2–3 sentences)
4. L31–L40: Tone practice (hỏi/ngã distinction)
5. L41–L50: Writing practice (copy sentences)

### Grade 3 Numbers (55 lessons)
1. L1–L15: Multiplication tables 1–10
2. L16–L25: Division with remainders
3. L26–L35: Fractions basics (1/2, 1/4, 3/4)
4. L36–L45: Decimals (0.1, 0.5, 1.25)
5. L46–L55: 3-digit addition/subtraction

### Grade 3 Vietnamese (55 lessons)
1. L1–L15: Paragraph reading (5–10 sentences)
2. L16–L25: Grammar: parts of speech
3. L26–L35: Writing: describe a picture
4. L36–L45: Synonyms and antonyms
5. L46–L55: Dictation practice

*(Complete YAML curriculum definitions TBD — can be generated once approved)*

# Expansion Plans: New Subject + New Grade

## Context
- **Math curriculum** (content-service, Rust/Axum): 4 subjects × ~40 lessons = 1,710 lessons for **Grade 1** (ages 5–7)
  - Existing math subjects: `numbers`, `geometry`, `measurement`, `logic`
- **Language curriculum** (language-service, FastAPI): 2 subjects × 40 lessons = 80 lessons
  - Existing language subjects: `vietnamese`, `english`
- **Architecture**: Dual-service setup
  - `content-service`: Math subjects with MiniJinja + meval question generation
  - `language-service`: Language subjects with its own `language_subjects`, `language_lessons`, `language_exercises` tables + TTS/validation
  - `SubjectScreen` switches API based on subject ID (`vietnamese`/`english` → `LanguageApi`, others → `ContentApi`)
- Frontend: `HomeScreen` shows **6** subject cards; `SubjectScreen` routes to correct service
- Question generation: MiniJinja + meval (question_bank-service) for math; direct DB exercises for language

---

## Plan A: Add New Subject to Grade 1

### Candidate: `money` — Money & Currency 💰
**Why:** Highly practical, visual, culturally relevant (VND), fills a gap between numbers and real-world application.

### Scope
`money` is a **math subject**, so it lives in `content-service` alongside the existing 4 subjects. No need for a new microservice.

| Layer | Work |
|-------|------|
| **DB** | Add `money` to `content-service.subjects` table; insert 40 lessons + ~80 exercises |
| **Backend** | Add `money` templates to question_bank (new MiniJinja templates for coin arithmetic) |
| **Frontend** | Add **7th** subject card to `HomeScreen`; update `_subjectIds` list; add i18n strings; no `SubjectScreen` changes needed |
| **E2E** | Add subject navigation test for `/subject/money` |

### Service Boundary Note
When adding a new subject, decide **which service** it belongs to:
- **`content-service`**: Math subjects (numbers, geometry, measurement, logic, money, fractions, etc.) that use MiniJinja + question_bank
- **`language-service`**: Language subjects (vietnamese, english, ...) that use direct DB exercises with typing/audio/tts

Do NOT create a new service for every subject. Services own **domain verticals**, not individual subjects.

### DB Migration (`backend/content/migrations/004_money_subject.sql`)
```sql
-- 1. Insert subject
INSERT INTO subjects (id, name_vi, name_en, icon, color, display_order)
VALUES ('money', 'Tiền tệ', 'Money', '💰', '#FFF8E1', 5);

-- 2. Insert 40 lessons (BEGINNER → ADVANCED)
-- L1-L10: Coin recognition (1k, 2k, 5k, 10k VND)
-- L11-L20: Counting total value
-- L21-L30: Making change (simple)
-- L31-L40: Word problems (buying snacks)

-- 3. Insert exercises with template params
-- Type: money|total|options, money|change|options
```

### Question Bank Templates (`backend/question_bank/templates/money/`)
New templates:
- `coin_total.jinja`: "Tổng giá trị: {{a}}đ + {{b}}đ = ?"
- `coin_change.jinja`: "Cho {{amount}}đ, mua món {{price}}đ, thối lại ?"
- `coin_visual.jinja`: Show emoji coins (💵, 🪙) and ask total

### Frontend Changes
`home_screen.dart` currently has 6 subjects. Add `money` as the **7th**:

```dart
static const List<String> _subjectIds = [
  'numbers', 'geometry', 'measurement', 'logic',
  'vietnamese', 'english', 'money'
];

static const List<Map<String, dynamic>> _subjects = [
  {'icon': '🔢', 'nameVi': 'So hoc', 'nameEn': 'Numbers', 'color': 0xFFFFE8F0},
  {'icon': '📐', 'nameVi': 'Hinh hoc', 'nameEn': 'Geometry', 'color': 0xFFE8F5E9},
  {'icon': '📏', 'nameVi': 'Do luong', 'nameEn': 'Measurement', 'color': 0xFFFFF3E0},
  {'icon': '🧩', 'nameVi': 'Tu duy', 'nameEn': 'Logic', 'color': 0xFFE3F2FD},
  {'icon': '🇻🇳', 'nameVi': 'Tiếng Việt', 'nameEn': 'Vietnamese', 'color': 0xFFFFEBEE},
  {'icon': '🇬🇧', 'nameVi': 'Tiếng Anh', 'nameEn': 'English', 'color': 0xFFE8EAF6},
  {'icon': '💰', 'nameVi': 'Tien te', 'nameEn': 'Money', 'color': 0xFFFFF8E1},
];
```

Also add `_resolveSubjectTitle` case:
```dart
case 'money':
  return l10n.parentDashboardSubjectMoney;
```

### i18n Strings
```arb
"parentDashboardSubjectMoney": "Tiền tệ / Money",
```

### Effort: 2–3 days
### Risk: Low — purely additive, no schema changes to existing tables

---

## Plan B: Extend to Grade 2 (ages 7–8)

### Scope
This is a **multi-phase** effort to introduce grade levels into the platform.

### Phase 1: Schema Changes (1–2 days)
**Content Service migration:** `backend/content/migrations/005_grade_levels.sql`

```sql
-- 1. Add grade column to subjects (nullable, default 1)
ALTER TABLE subjects ADD COLUMN IF NOT EXISTS grade INT NOT NULL DEFAULT 1;

-- 2. Add grade column to lessons
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS grade INT NOT NULL DEFAULT 1;

-- 3. Add grade column to users
ALTER TABLE users ADD COLUMN IF NOT EXISTS grade INT NOT NULL DEFAULT 1;

-- 4. Backfill existing data
UPDATE subjects SET grade = 1;
UPDATE lessons SET grade = 1;
```

**Language Service migration:** `backend/language/migrations/002_grade_column.sql`

```sql
-- Language subjects also need grade awareness
ALTER TABLE language_subjects ADD COLUMN IF NOT EXISTS grade INT NOT NULL DEFAULT 1;
ALTER TABLE language_lessons ADD COLUMN IF NOT EXISTS grade INT NOT NULL DEFAULT 1;
UPDATE language_subjects SET grade = 1;
UPDATE language_lessons SET grade = 1;
```

**Rationale:** Grade levels span both services. A Grade 2 user may study advanced math AND advanced Vietnamese. Both databases must support filtering.

### Phase 2: Grade 2 Curriculum (3–4 days)
**New subjects for Grade 2:**

| Subject | ID | Service | Icon | Lessons | Focus |
|---------|-----|---------|------|---------|-------|
| Advanced Numbers | `numbers_g2` | content | 🔢 | 50 | 2-digit +/-, intro multiplication (2×, 5×, 10×) |
| Advanced Geometry | `geometry_g2` | content | 📐 | 40 | 3D shapes, symmetry, perimeter |
| Advanced Measurement | `measurement_g2` | content | 📏 | 40 | Length (cm/m), weight (kg/g), time (minutes) |
| Advanced Logic | `logic_g2` | content | 🧩 | 40 | Multi-step patterns, Venn diagrams, sorting |
| Advanced Vietnamese | `vietnamese_g2` | language | 🇻🇳 | 40 | Compound words, sentence building, reading |
| Advanced English | `english_g2` | language | 🇬🇧 | 40 | Vocabulary expansion, simple grammar, reading |

**Question Bank:** New difficulty tier `difficulty=3` for grade 2.
- Multiplication templates: `mult|{{a}}×{{b}}|options`
- Word problem templates with 2-step reasoning
- Language exercises: longer passages, listening comprehension

### Phase 3: API Changes (1–2 days)
**Content Service:**
- `GET /api/content/subjects?grade=2` — filter by grade
- `GET /api/content/curriculum?grade=2` — filter by grade
- `GET /api/content/lesson/:id` — unchanged

**Language Service:**
- `GET /api/language/subjects?grade=2` — filter by grade
- `GET /api/language/curriculum?grade=2` — filter by grade
- `GET /api/language/lesson/:id` — unchanged

**User Service:**
- `PATCH /api/users/:id/grade` — admin/parent can bump grade
- `GET /api/users/:id` — returns `grade` field

### Phase 4: Frontend Changes (2–3 days)

#### Onboarding Flow
- **AssessmentScreen**: After persona selection, ask age/grade (simple 2 buttons: "Lớp 1 / Grade 1" vs "Lớp 2 / Grade 2")
- Store grade in backend during `createUser`

#### HomeScreen
- Show subjects **filtered by user's grade** from **both services**
- Query both `GET /api/content/subjects?grade={userGrade}` and `GET /api/language/subjects?grade={userGrade}`
- Merge results into `_subjects` list dynamically (or keep hardcoded list with grade metadata)
- Add "Switch Grade" button in Settings (for parents)

#### SubjectScreen
- **Unchanged routing logic** — still switches API by subject ID:
  - `vietnamese`/`english` → `LanguageApi.getCurriculum()`
  - All others → `ContentApi.getCurriculum()`
- Grade is implicit in the subject ID (e.g., `numbers_g2` vs `numbers`)

#### Frontend Architecture Note
Consider fetching subjects dynamically per-user instead of hardcoding `_subjects`:
```dart
final subjectsAsync = ref.watch(subjectsProvider(userGrade));
subjectsAsync.when(
  data: (subjects) => _buildSubjectGrid(subjects),
  loading: () => const CircularProgressIndicator(),
);
```
This avoids manual `_subjects` hardcoding every time a new subject is added.

#### Progress Isolation Strategy
**Option A (Recommended):** Progress is **not grade-isolated**. Completing `numbers_g2` lessons counts toward total progress. This is simpler and rewards kids for advancing.

**Option B:** Separate progress per grade. More complex; requires `progress.grade` column.

### Phase 5: Parent Dashboard (1 day)
- Show current grade
- "Promote to Grade 2" button (unlocks after 80% of Grade 1 completed)
- Grade-level stats: "Grade 1: 45/50 lessons complete"

### i18n Strings
```arb
"grade1Label": "Lớp 1 (5-7 tuổi)",
"grade2Label": "Lớp 2 (7-8 tuổi)",
"gradeSelectTitle": "Bé học lớp mấy?",
"gradeSwitchButton": "Chuyển lớp",
"gradeLocked": "Hoàn thành {percent}% bài lớp 1 để mở khóa",
"gradeProgressTitle": "Tiến độ lớp {grade}",
```

### Effort: 7–10 days total
### Risk: Medium — schema migration touches 3 tables; frontend filtering logic; curriculum generation is large

---

## Implementation Order Recommendation

| Order | Plan | Effort | Impact | Reason |
|-------|------|--------|--------|--------|
| 1 | **Plan A** (Money subject) | 2–3 days | High | Low risk, immediate user value, teaches real-world skills |
| 2 | **Plan B Phase 1+2** (Grade 2 schema + curriculum) | 4–5 days | Very High | Unlocks entire new user segment (7–8 year olds) |
| 3 | **Plan B Phase 3+4** (API + frontend grade selector) | 3–4 days | High | Completes the grade 2 experience |
| 4 | **Plan B Phase 5** (Parent dashboard) | 1 day | Medium | Nice-to-have admin control |

---

## Technical Notes

### Subject ID Uniqueness
- Grade 2 subjects use `_g2` suffix: `numbers_g2`, `geometry_g2`, etc.
- This avoids ID collision within a service and makes filtering trivial: `WHERE id LIKE '%_g2'`
- **Cross-service collision is impossible** because each service owns its own subject IDs (e.g., `content-service` won't have `vietnamese_g2`, `language-service` won't have `numbers_g2`)
- Future alternative: use a `grade` column + composite filter instead of suffix

### Question Bank Difficulty
- Grade 1: `difficulty = 1|2`
- Grade 2: `difficulty = 2|3`
- The `difficulty` column already exists on `lessons`

### Curriculum Generation
- Mass curriculum SQL (like `003_mass_curriculum.sql`) can be auto-generated via script
- Consider writing a Python/Rust generator that outputs `INSERT` statements from a structured YAML/JSON curriculum definition

### Migration Safety
- All migrations are additive and use `IF NOT EXISTS`
- Existing Grade 1 users are unaffected (grade defaults to 1)
- New column additions are instant on PostgreSQL

### Cross-Service Progress Aggregation
With two services (`content-service` for math, `language-service` for language), progress is split across databases:
- Math progress → `progress-service.progress` table OR `content-service` progress tracking
- Language progress → `language-service.language_progress` table

**Grade 2 implication:** Total progress for a Grade 2 user must aggregate across BOTH services. Consider a unified progress aggregator in the frontend or a facade API in the `user-service` that queries both backends.

**Recommended approach:** Frontend aggregates (simpler):
```dart
final mathProgress = await ProgressApi.getProgress(userId);
final langProgress = await LanguageApi.getProgress(userId);
final totalProgress = {...mathProgress, ...langProgress};
```

If you need server-side aggregation, add a `GET /api/users/:id/progress` endpoint in `user-service` that fans out to both content and language services.

---

## Alternative New Subjects (if Money is not preferred)

| Subject | ID | Icon | Why |
|---------|-----|------|-----|
| **Patterns & Sequences** | `patterns` | 🔁 | Bridges numbers → logic |
| **Data & Graphs** | `data` | 📊 | Visual, modern skill |
| **Time** | `time` | ⏰ | Already partially in Measurement; could split |
| **Fractions** | `fractions` | 🍕 | Natural next step after counting |
| **Spatial Reasoning** | `spatial` | 🧭 | 3D rotation, maps — high engagement |

**Recommendation:** `money` has the highest engagement for Vietnamese kids (they see VND daily) and the most natural MiniJinja template opportunities.

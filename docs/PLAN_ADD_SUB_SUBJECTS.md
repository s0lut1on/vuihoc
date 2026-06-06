# Plan: Add Sub-Subjects for Vietnamese & English

## 1. Database Schema Changes

### New Table: `language_sub_subjects`
```sql
CREATE TABLE language_sub_subjects (
    id VARCHAR(32) PRIMARY KEY,          -- e.g., 'vn_letters', 'en_phonics'
    subject_id VARCHAR(32) NOT NULL,     -- 'vietnamese' or 'english'
    name_vi VARCHAR(100) NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    icon VARCHAR(8) DEFAULT '📚',
    color VARCHAR(8) DEFAULT '#FFE0E0',
    display_order INT DEFAULT 0,
    FOREIGN KEY (subject_id) REFERENCES language_subjects(id) ON DELETE CASCADE
);
```

### Modify `language_lessons` Table
Add `sub_subject_id` column:
```sql
ALTER TABLE language_lessons ADD COLUMN sub_subject_id VARCHAR(32);
```

## 2. Proposed Sub-Subjects

### Vietnamese (Tiếng Việt) - 5 sub-subjects
| ID | Name (VI) | Name (EN) | Lessons | Icon | Color |
|---|---|---|---|---|---|
| `vn_letters` | Chữ cái | Letters | 1-10 | 🔤 | #FFE0E0 |
| `vn_syllables` | Ghép vần | Syllables | 11-20 | 🔗 | #E0F7FA |
| `vn_words` | Từ vựng | Vocabulary | 21-30 | 📖 | #FFF8E1 |
| `vn_sentences` | Câu đơn | Sentences | 31-38 | ✍️ | #E8F5E9 |
| `vn_reading` | Đọc hiểu | Reading | 39-40 | 📰 | #F3E5F5 |

### English - 5 sub-subjects
| ID | Name (VI) | Name (EN) | Lessons | Icon | Color |
|---|---|---|---|---|---|
| `en_letters` | Chữ cái | Alphabet | 1-10 | 🔤 | #FFE0E0 |
| `en_phonics` | Phonics | Phonics | 11-18 | 🔊 | #E0F7FA |
| `en_sight_words` | Từ thông dụng | Sight Words | 19-26 | 👁️ | #FFF8E1 |
| `en_sentences` | Câu đơn | Sentences | 27-34 | ✍️ | #E8F5E9 |
| `en_reading` | Đọc hiểu | Reading | 35-40 | 📰 | #F3E5F5 |

## 3. Backend API Changes

### Modify `LanguageApi.getCurriculum()`
Change from flat list to grouped structure:
```dart
// Current: returns List<Map<String, dynamic>> of lessons
// New: returns List<Map<String, dynamic>> of sub-subjects, each containing lessons
[
  {
    "sub_subject_id": "vn_letters",
    "name_vi": "Chữ cái",
    "name_en": "Letters",
    "icon": "🔤",
    "color": "#FFE0E0",
    "lessons": [...]
  },
  ...
]
```

### Update Endpoint: `GET /api/language/curriculum`
- Query existing `language_sub_subjects` table
- Group lessons by `sub_subject_id`
- Return hierarchical response

## 4. Frontend Changes

### SubjectScreen (lib/screens/subject_screen.dart)
When `subjectId == 'vietnamese'` or `subjectId == 'english'`:
1. Call `LanguageApi.getCurriculum()` to get grouped sub-subjects
2. Show horizontal list of sub-subjects (same style as math sub-subjects)
3. Tapping a sub-subject navigates to `/subject/{subjectId}/{subSubjectId}`
4. Show lesson list for that sub-subject

### New Route: `/subject/:subjectId/:subSubjectId`
- Add to `app_router.dart`
- Reuse `SubjectScreen` with optional `subSubjectId` parameter
- Filter lessons by `sub_subject_id`

### AppRouter (lib/core/app_router.dart)
```dart
GoRoute(
  path: '/subject/:subjectId/:subSubjectId',
  builder: (context, state) => SubjectScreen(
    subjectId: state.pathParameters['subjectId']!,
    subSubjectId: state.pathParameters['subSubjectId'],
  ),
),
```

## 5. Seed Data Migration

### Step 1: Create sub-subjects
```sql
INSERT INTO language_sub_subjects VALUES
('vn_letters', 'vietnamese', 'Chữ cái', 'Letters', '🔤', '#FFE0E0', 1),
('vn_syllables', 'vietnamese', 'Ghép vần', 'Syllables', '🔗', '#E0F7FA', 2),
('vn_words', 'vietnamese', 'Từ vựng', 'Vocabulary', '📖', '#FFF8E1', 3),
('vn_sentences', 'vietnamese', 'Câu đơn', 'Sentences', '✍️', '#E8F5E9', 4),
('vn_reading', 'vietnamese', 'Đọc hiểu', 'Reading', '📰', '#F3E5F5', 5);

INSERT INTO language_sub_subjects VALUES
('en_letters', 'english', 'Chữ cái', 'Alphabet', '🔤', '#FFE0E0', 1),
('en_phonics', 'english', 'Phonics', 'Phonics', '🔊', '#E0F7FA', 2),
('en_sight_words', 'english', 'Từ thông dụng', 'Sight Words', '👁️', '#FFF8E1', 3),
('en_sentences', 'english', 'Câu đơn', 'Sentences', '✍️', '#E8F5E9', 4),
('en_reading', 'english', 'Đọc hiểu', 'Reading', '📰', '#F3E5F5', 5);
```

### Step 2: Update existing lessons with sub_subject_id
```sql
UPDATE language_lessons SET sub_subject_id = 'vn_letters' WHERE subject_id = 'vietnamese' AND lesson_order BETWEEN 1 AND 10;
UPDATE language_lessons SET sub_subject_id = 'vn_syllables' WHERE subject_id = 'vietnamese' AND lesson_order BETWEEN 11 AND 20;
UPDATE language_lessons SET sub_subject_id = 'vn_words' WHERE subject_id = 'vietnamese' AND lesson_order BETWEEN 21 AND 30;
UPDATE language_lessons SET sub_subject_id = 'vn_sentences' WHERE subject_id = 'vietnamese' AND lesson_order BETWEEN 31 AND 38;
UPDATE language_lessons SET sub_subject_id = 'vn_reading' WHERE subject_id = 'vietnamese' AND lesson_order BETWEEN 39 AND 40;

UPDATE language_lessons SET sub_subject_id = 'en_letters' WHERE subject_id = 'english' AND lesson_order BETWEEN 1 AND 10;
UPDATE language_lessons SET sub_subject_id = 'en_phonics' WHERE subject_id = 'english' AND lesson_order BETWEEN 11 AND 18;
UPDATE language_lessons SET sub_subject_id = 'en_sight_words' WHERE subject_id = 'english' AND lesson_order BETWEEN 19 AND 26;
UPDATE language_lessons SET sub_subject_id = 'en_sentences' WHERE subject_id = 'english' AND lesson_order BETWEEN 27 AND 34;
UPDATE language_lessons SET sub_subject_id = 'en_reading' WHERE subject_id = 'english' AND lesson_order BETWEEN 35 AND 40;
```

## 6. Implementation Steps (Execution Order)

1. **Database Migration** (backend)
   - Create `language_sub_subjects` table
   - Add `sub_subject_id` column to `language_lessons`
   - Run seed data migration

2. **Backend API Update** (backend/language)
   - Update `getCurriculum()` endpoint to return grouped data
   - Add new endpoint `GET /sub-subjects?subject_id={id}` for direct queries
   - Update lesson fetching to filter by sub_subject_id

3. **Frontend - LanguageApi** (frontend)
   - Update `LanguageApi.getCurriculum()` to parse new grouped structure
   - Add `LanguageApi.getSubSubjects(subjectId)` method

4. **Frontend - SubjectScreen** (frontend)
   - Add `_languageSubSubjects` list similar to `_mathSubSubjects`
   - Show sub-subjects grid for vietnamese/english when no subSubjectId
   - Show lesson list when subSubjectId is provided
   - Update `_loadLessons()` to fetch by sub_subject_id

5. **Frontend - AppRouter** (frontend)
   - Add new route `/subject/:subjectId/:subSubjectId`
   - Update navigation from sub-subject to lesson list

6. **Testing**
   - Test curriculum API returns grouped data
   - Test sub-subject navigation works
   - Test lesson list filters correctly by sub_subject_id
   - Test progress tracking still works with sub_subject_id

## 7. Additional Lessons (Optional)

After sub-subjects are implemented, add more lessons per category:
- **Vietnamese**: Add more syllables (ch, gh, kh, nh, ph, th...), more vocabulary categories, more sentence patterns
- **English**: Add more phonics (blends, digraphs), more sight words (50-100), more reading passages

Estimate: 10-20 new lessons per sub-subject, totaling 100-200 new lessons across both languages.

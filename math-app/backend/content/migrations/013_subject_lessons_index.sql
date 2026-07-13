-- 013_subject_lessons_index.sql
-- Add composite index to speed up the lightweight per-subject lesson
-- query (added in content/models.rs as get_subject_lessons). Also
-- add an index on exercises(lesson_id) which the get_lesson() handler
-- already benefits from but didn't have.
--
-- Without these indexes the existing curriculum() query also runs
-- a 3-way LEFT JOIN (subjects, lessons, exercises) that scans
-- ~6,000 lessons and ~2,700 exercises, which was the root cause
-- of the "subject load is very slow" complaint.

CREATE INDEX IF NOT EXISTS idx_lessons_subject_grade_order
  ON lessons (subject_id, grade, lesson_order);

CREATE INDEX IF NOT EXISTS idx_exercises_lesson_order
  ON exercises (lesson_id, exercise_order);

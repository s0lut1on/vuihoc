-- Migration: Add grade columns to language-service tables
-- Phase 1: Grade Levels Implementation

-- Add grade range to language_subjects table
ALTER TABLE language_subjects ADD COLUMN IF NOT EXISTS grade_min INT NOT NULL DEFAULT 1;
ALTER TABLE language_subjects ADD COLUMN IF NOT EXISTS grade_max INT NOT NULL DEFAULT 3;

-- Add grade column to language_lessons
ALTER TABLE language_lessons ADD COLUMN IF NOT EXISTS grade INT NOT NULL DEFAULT 1;

-- Create index for efficient grade filtering
CREATE INDEX IF NOT EXISTS idx_language_lessons_grade ON language_lessons(grade);

-- Create composite index for subject + grade queries
CREATE INDEX IF NOT EXISTS idx_language_lessons_subject_grade ON language_lessons(subject_id, grade);

-- Backfill existing data: all existing lessons are Grade 1
UPDATE language_subjects SET grade_min = 1, grade_max = 3 WHERE id IN ('vietnamese', 'english');
UPDATE language_lessons SET grade = 1;

-- Verify: should show 2 subjects with grade_min=1, grade_max=3
-- SELECT id, name_vi, grade_min, grade_max FROM language_subjects;
-- Verify: should show all lessons with grade=1
-- SELECT COUNT(*) as total_lessons, COUNT(*) FILTER (WHERE grade = 1) as grade1_lessons FROM language_lessons;

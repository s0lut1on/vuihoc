-- Migration: Add grade columns to content-service tables
-- Phase 1: Grade Levels Implementation

-- Add grade range to subjects table (controls which grades see this subject card)
ALTER TABLE subjects ADD COLUMN IF NOT EXISTS grade_min INT NOT NULL DEFAULT 1;
ALTER TABLE subjects ADD COLUMN IF NOT EXISTS grade_max INT NOT NULL DEFAULT 3;

-- Add grade column to lessons (controls which lessons load for this grade)
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS grade INT NOT NULL DEFAULT 1;

-- Create index for efficient grade filtering
CREATE INDEX IF NOT EXISTS idx_lessons_grade ON lessons(grade);

-- Create composite index for subject + grade queries
CREATE INDEX IF NOT EXISTS idx_lessons_subject_grade ON lessons(subject_id, grade);

-- Backfill existing data: all existing lessons are Grade 1
UPDATE subjects SET grade_min = 1, grade_max = 3 WHERE id IN ('numbers', 'geometry', 'measurement', 'logic');
UPDATE lessons SET grade = 1;

-- Verify: should show 4 subjects with grade_min=1, grade_max=3
-- SELECT id, name_vi, grade_min, grade_max FROM subjects;
-- Verify: should show all lessons with grade=1
-- SELECT COUNT(*) as total_lessons, COUNT(*) FILTER (WHERE grade = 1) as grade1_lessons FROM lessons;

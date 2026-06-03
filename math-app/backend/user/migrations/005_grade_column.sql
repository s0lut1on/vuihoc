-- Migration: Add grade column to users table
-- Phase 1: Grade Levels Implementation

-- Add grade column to users table (default Grade 1 for all existing users)
ALTER TABLE users ADD COLUMN IF NOT EXISTS grade INT NOT NULL DEFAULT 1;

-- Create index for grade queries
CREATE INDEX IF NOT EXISTS idx_users_grade ON users(grade);

-- Backfill existing data: all existing users are Grade 1
UPDATE users SET grade = 1 WHERE grade IS NULL;

-- Verify: should show all users with grade=1
-- SELECT id, name, grade FROM users LIMIT 10;

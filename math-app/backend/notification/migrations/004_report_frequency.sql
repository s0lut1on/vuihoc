-- Add report_frequency column to notification_preferences
-- Supports daily, weekly, or never email report preferences

ALTER TABLE notification_preferences
  ADD COLUMN IF NOT EXISTS report_frequency VARCHAR(10) NOT NULL DEFAULT 'never';
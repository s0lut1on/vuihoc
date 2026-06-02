-- Leaderboard / Classroom feature migration
-- Feature #5

ALTER TABLE users ADD COLUMN IF NOT EXISTS classroom_code VARCHAR(6);

CREATE INDEX idx_users_classroom_code ON users(classroom_code) WHERE classroom_code IS NOT NULL;

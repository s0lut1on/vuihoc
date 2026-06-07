-- Spaced Repetition / Weak Spot Drill migration
-- Feature #1

CREATE TABLE IF NOT EXISTS user_exercise_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    exercise_id VARCHAR(64) NOT NULL,
    lesson_id VARCHAR(64) NOT NULL,
    correct_count INTEGER NOT NULL DEFAULT 0,
    wrong_count INTEGER NOT NULL DEFAULT 0,
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),
    next_review_at TIMESTAMPTZ DEFAULT NOW(),
    interval_days INTEGER NOT NULL DEFAULT 1,
    ease_factor FLOAT NOT NULL DEFAULT 2.5,
    UNIQUE (user_id, exercise_id)
);

CREATE INDEX idx_user_exercise_stats_user_id ON user_exercise_stats(user_id);
CREATE INDEX idx_user_exercise_stats_next_review ON user_exercise_stats(next_review_at);

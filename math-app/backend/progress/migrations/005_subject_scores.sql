-- Subject-level score tracking for leaderboard.
-- Accumulates per-lesson performance (correct answers + time) into a
-- running total per (user, subject) pair. The user service reads this
-- table cross-schema (progress.subject_scores) to build global and
-- per-subject leaderboards.

CREATE TABLE IF NOT EXISTS subject_scores (
    user_id UUID NOT NULL,
    subject_id VARCHAR(64) NOT NULL,
    total_score INT NOT NULL DEFAULT 0,
    correct_count INT NOT NULL DEFAULT 0,
    total_time_ms BIGINT NOT NULL DEFAULT 0,
    lessons_completed INT NOT NULL DEFAULT 0,
    name VARCHAR(100) NOT NULL DEFAULT '',
    avatar VARCHAR(20) NOT NULL DEFAULT '🐸',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, subject_id)
);

-- Leaderboard queries: ORDER BY total_score DESC — index supports fast sort.
CREATE INDEX IF NOT EXISTS idx_subject_scores_subject_score
    ON subject_scores(subject_id, total_score DESC);

CREATE INDEX IF NOT EXISTS idx_subject_scores_user
    ON subject_scores(user_id);
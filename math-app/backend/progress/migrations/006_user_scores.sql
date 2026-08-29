-- User-level total score (across ALL subjects).
-- Replaces the per-subject subject_scores table for leaderboard ranking.
-- One row per user; score accumulates from every lesson completion
-- regardless of subject.

CREATE TABLE IF NOT EXISTS user_scores (
    user_id UUID NOT NULL PRIMARY KEY,
    total_score INT NOT NULL DEFAULT 0,
    correct_count INT NOT NULL DEFAULT 0,
    total_time_ms BIGINT NOT NULL DEFAULT 0,
    lessons_completed INT NOT NULL DEFAULT 0,
    name VARCHAR(100) NOT NULL DEFAULT '',
    avatar VARCHAR(20) NOT NULL DEFAULT '🐸',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Migrate existing per-subject rows into the new single-row-per-user table.
-- Sum all subjects so no history is lost.
INSERT INTO user_scores (user_id, total_score, correct_count, total_time_ms, lessons_completed, name, avatar, updated_at)
SELECT
    user_id,
    SUM(total_score) AS total_score,
    SUM(correct_count) AS correct_count,
    SUM(total_time_ms) AS total_time_ms,
    SUM(lessons_completed) AS lessons_completed,
    MAX(name) AS name,
    MAX(avatar) AS avatar,
    MAX(updated_at) AS updated_at
FROM subject_scores
GROUP BY user_id
ON CONFLICT (user_id) DO UPDATE SET
    total_score = user_scores.total_score + EXCLUDED.total_score,
    correct_count = user_scores.correct_count + EXCLUDED.correct_count,
    total_time_ms = user_scores.total_time_ms + EXCLUDED.total_time_ms,
    lessons_completed = user_scores.lessons_completed + EXCLUDED.lessons_completed,
    name = EXCLUDED.name,
    avatar = EXCLUDED.avatar,
    updated_at = NOW();

-- Fast sort for leaderboard queries.
CREATE INDEX IF NOT EXISTS idx_user_scores_score
    ON user_scores(total_score DESC);
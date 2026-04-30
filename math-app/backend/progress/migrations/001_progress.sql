CREATE TABLE IF NOT EXISTS progress (
    user_id UUID NOT NULL,
    lesson_id VARCHAR(255) NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    stars INT NOT NULL DEFAULT 0,
    attempts INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, lesson_id)
);

CREATE TABLE IF NOT EXISTS streaks (
    user_id UUID PRIMARY KEY,
    current_streak INT NOT NULL DEFAULT 0,
    best_streak INT NOT NULL DEFAULT 0,
    last_activity TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

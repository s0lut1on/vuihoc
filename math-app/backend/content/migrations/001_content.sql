CREATE TABLE IF NOT EXISTS cached_lessons (
    id VARCHAR(255) PRIMARY KEY,
    subject_id VARCHAR(255) NOT NULL,
    title_vi VARCHAR(500) NOT NULL,
    title_en VARCHAR(500) NOT NULL,
    difficulty INT NOT NULL DEFAULT 1,
    content JSONB NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cached_lessons_subject ON cached_lessons(subject_id);

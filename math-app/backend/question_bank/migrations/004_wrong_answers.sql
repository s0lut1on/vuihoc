CREATE TABLE IF NOT EXISTS wrong_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    exercise_id VARCHAR(50) NOT NULL,
    lesson_id VARCHAR(50) NOT NULL,
    subject_id VARCHAR(50) NOT NULL,
    question_vi TEXT NOT NULL,
    question_en TEXT NOT NULL,
    hint_vi TEXT,
    hint_en TEXT,
    options TEXT[] NOT NULL DEFAULT '{}',
    correct_index INT NOT NULL DEFAULT 0,
    wrong_count INT NOT NULL DEFAULT 1,
    last_wrong_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (user_id, exercise_id)
);

CREATE INDEX IF NOT EXISTS idx_wrong_answers_user ON wrong_answers(user_id);
CREATE INDEX IF NOT EXISTS idx_wrong_answers_subject ON wrong_answers(subject_id);

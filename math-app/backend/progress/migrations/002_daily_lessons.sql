CREATE TABLE IF NOT EXISTS daily_lessons (
    user_id UUID NOT NULL,
    lesson_date DATE NOT NULL DEFAULT CURRENT_DATE,
    count INT NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, lesson_date)
);

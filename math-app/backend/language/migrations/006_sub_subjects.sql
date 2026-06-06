BEGIN;

-- Create language_sub_subjects table
CREATE TABLE IF NOT EXISTS language_sub_subjects (
    id VARCHAR(50) PRIMARY KEY,
    subject_id VARCHAR(50) NOT NULL REFERENCES language_subjects(id) ON DELETE CASCADE,
    name_vi VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NOT NULL,
    icon VARCHAR(10) DEFAULT '📚',
    color VARCHAR(50) DEFAULT '#FFEBEE',
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add sub_subject_id column to language_lessons (nullable for backward compat)
ALTER TABLE language_lessons ADD COLUMN IF NOT EXISTS sub_subject_id VARCHAR(50) REFERENCES language_sub_subjects(id) ON DELETE SET NULL;

-- Create index for sub_subject_id queries
CREATE INDEX IF NOT EXISTS idx_language_lessons_sub_subject_id ON language_lessons(sub_subject_id);

-- Insert Vietnamese sub-subjects
INSERT INTO language_sub_subjects (id, subject_id, name_vi, name_en, icon, color, display_order) VALUES
('vn_letters', 'vietnamese', 'Chữ cái', 'Letters', '🔤', '#FFE0E0', 1),
('vn_syllables', 'vietnamese', 'Ghép vần', 'Syllables', '🔗', '#E0F7FA', 2),
('vn_words', 'vietnamese', 'Từ vựng', 'Vocabulary', '📖', '#FFF8E1', 3),
('vn_sentences', 'vietnamese', 'Câu đơn', 'Sentences', '✍️', '#E8F5E9', 4),
('vn_reading', 'vietnamese', 'Đọc hiểu', 'Reading', '📰', '#F3E5F5', 5)
ON CONFLICT (id) DO NOTHING;

-- Insert English sub-subjects
INSERT INTO language_sub_subjects (id, subject_id, name_vi, name_en, icon, color, display_order) VALUES
('en_letters', 'english', 'Chữ cái', 'Alphabet', '🔤', '#FFE0E0', 1),
('en_phonics', 'english', 'Phonics', 'Phonics', '🔊', '#E0F7FA', 2),
('en_sight_words', 'english', 'Từ thông dụng', 'Sight Words', '👁️', '#FFF8E1', 3),
('en_sentences', 'english', 'Câu đơn', 'Sentences', '✍️', '#E8F5E9', 4),
('en_reading', 'english', 'Đọc hiểu', 'Reading', '📰', '#F3E5F5', 5)
ON CONFLICT (id) DO NOTHING;

-- Update Vietnamese lessons: assign to sub-subjects based on lesson_order
UPDATE language_lessons SET sub_subject_id = 'vn_letters' WHERE subject_id = 'vietnamese' AND lesson_order BETWEEN 1 AND 10;
UPDATE language_lessons SET sub_subject_id = 'vn_syllables' WHERE subject_id = 'vietnamese' AND lesson_order BETWEEN 11 AND 20;
UPDATE language_lessons SET sub_subject_id = 'vn_words' WHERE subject_id = 'vietnamese' AND lesson_order BETWEEN 21 AND 30;
UPDATE language_lessons SET sub_subject_id = 'vn_sentences' WHERE subject_id = 'vietnamese' AND lesson_order BETWEEN 31 AND 38;
UPDATE language_lessons SET sub_subject_id = 'vn_reading' WHERE subject_id = 'vietnamese' AND lesson_order BETWEEN 39 AND 40;

-- Update English lessons: assign to sub-subjects based on lesson_order
UPDATE language_lessons SET sub_subject_id = 'en_letters' WHERE subject_id = 'english' AND lesson_order BETWEEN 1 AND 10;
UPDATE language_lessons SET sub_subject_id = 'en_phonics' WHERE subject_id = 'english' AND lesson_order BETWEEN 11 AND 18;
UPDATE language_lessons SET sub_subject_id = 'en_sight_words' WHERE subject_id = 'english' AND lesson_order BETWEEN 19 AND 26;
UPDATE language_lessons SET sub_subject_id = 'en_sentences' WHERE subject_id = 'english' AND lesson_order BETWEEN 27 AND 34;
UPDATE language_lessons SET sub_subject_id = 'en_reading' WHERE subject_id = 'english' AND lesson_order BETWEEN 35 AND 40;

COMMIT;

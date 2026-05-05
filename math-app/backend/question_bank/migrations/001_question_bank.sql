-- Knowledge Components
CREATE TABLE IF NOT EXISTS kc (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    bloom_level VARCHAR(20) CHECK (bloom_level IN ('remember', 'understand', 'apply', 'analyze')),
    difficulty_min INT DEFAULT 1,
    difficulty_max INT DEFAULT 5,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Prerequisite relationships (DAG)
CREATE TABLE IF NOT EXISTS kc_prerequisite (
    kc_id UUID REFERENCES kc(id) ON DELETE CASCADE,
    prerequisite_kc_id UUID REFERENCES kc(id) ON DELETE CASCADE,
    PRIMARY KEY (kc_id, prerequisite_kc_id),
    CHECK (kc_id != prerequisite_kc_id)
);

-- Question Templates
CREATE TABLE IF NOT EXISTS template (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kc_id UUID REFERENCES kc(id) ON DELETE CASCADE,
    difficulty INT NOT NULL CHECK (difficulty BETWEEN 1 AND 5),
    bloom_level VARCHAR(20),
    stem_template TEXT NOT NULL,
    param_schema JSONB NOT NULL,
    solution_expr TEXT NOT NULL,
    error_taxonomy JSONB DEFAULT '[]',
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Generated Questions
CREATE TABLE IF NOT EXISTS question (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES template(id) ON DELETE CASCADE,
    kc_id UUID REFERENCES kc(id) ON DELETE CASCADE,
    difficulty INT NOT NULL,
    stem TEXT NOT NULL,
    params JSONB NOT NULL,
    answer FLOAT NOT NULL,
    distractors JSONB NOT NULL,
    context_wrap TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Students (reference from user service)
CREATE TABLE IF NOT EXISTS student (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- BKT Mastery State (per student per KC)
CREATE TABLE IF NOT EXISTS mastery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES student(id) ON DELETE CASCADE,
    kc_id UUID REFERENCES kc(id) ON DELETE CASCADE,
    p_mastery FLOAT DEFAULT 0.1,
    p_learn FLOAT DEFAULT 0.2,
    p_slip FLOAT DEFAULT 0.1,
    p_guess FLOAT DEFAULT 0.2,
    attempt_count INT DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (student_id, kc_id)
);

-- Response Log
CREATE TABLE IF NOT EXISTS response (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES student(id) ON DELETE CASCADE,
    question_id UUID REFERENCES question(id) ON DELETE CASCADE,
    kc_id UUID REFERENCES kc(id) ON DELETE CASCADE,
    answer_given FLOAT,
    is_correct BOOLEAN,
    time_taken_ms INT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_question_kc_diff ON question(kc_id, difficulty);
CREATE INDEX IF NOT EXISTS idx_mastery_student_kc ON mastery(student_id, kc_id);
CREATE INDEX IF NOT EXISTS idx_response_student ON response(student_id);
CREATE INDEX IF NOT EXISTS idx_response_question ON response(question_id);

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    persona VARCHAR(50) NOT NULL DEFAULT 'achiever',
    avatar VARCHAR(255) NOT NULL DEFAULT '🐸',
    streak_days INT NOT NULL DEFAULT 0,
    gems INT NOT NULL DEFAULT 0,
    total_lessons INT NOT NULL DEFAULT 0,
    total_stars INT NOT NULL DEFAULT 0,
    locale VARCHAR(10) NOT NULL DEFAULT 'vi_VN',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

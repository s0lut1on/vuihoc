-- Achievement/Badge System migration
-- Feature #2

CREATE TABLE IF NOT EXISTS badge_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    badge_type VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    icon VARCHAR(10) NOT NULL DEFAULT '🏅',
    threshold INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    badge_type VARCHAR(50) NOT NULL,
    earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_new BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (user_id, badge_type)
);

CREATE INDEX idx_achievements_user_id ON achievements(user_id);
CREATE INDEX idx_achievements_badge_type ON achievements(badge_type);

INSERT INTO badge_definitions (badge_type, name, description, icon, threshold)
VALUES
    ('first_lesson', 'First Lesson', 'Complete your very first lesson', '🎉', 1),
    ('streak_3', '3-Day Streak', 'Practice 3 days in a row', '🔥', 3),
    ('streak_7', '7-Day Streak', 'Practice 7 days in a row', '🚀', 7),
    ('streak_30', '30-Day Streak', 'Practice 30 days in a row', '⭐', 30),
    ('star_collector_10', 'Star Collector 10', 'Earn 10 stars in total', '⭐', 10),
    ('star_collector_50', 'Star Collector 50', 'Earn 50 stars in total', '💎', 50)
ON CONFLICT (badge_type) DO NOTHING;

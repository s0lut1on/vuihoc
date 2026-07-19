ALTER TABLE users ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES users(id);
CREATE INDEX IF NOT EXISTS idx_users_parent ON users(parent_id);

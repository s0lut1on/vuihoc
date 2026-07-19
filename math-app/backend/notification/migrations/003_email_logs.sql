CREATE TABLE IF NOT EXISTS email_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    email_to TEXT NOT NULL,
    email_type VARCHAR(50) NOT NULL DEFAULT 'weekly_report',
    subject TEXT NOT NULL,
    body TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_email_logs_user ON email_logs(user_id, created_at DESC);

ALTER TABLE notification_preferences ADD COLUMN IF NOT EXISTS parent_email TEXT;
ALTER TABLE notification_preferences ADD COLUMN IF NOT EXISTS email_reports_enabled BOOLEAN NOT NULL DEFAULT false;

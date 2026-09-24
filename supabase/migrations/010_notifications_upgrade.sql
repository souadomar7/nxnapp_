-- ==============================================================================
-- 010_NOTIFICATIONS_UPGRADE.SQL
-- Notification routing with deep links, bilingual payload, device tokens,
-- and per-user delivery preferences.
-- ==============================================================================

-- 1. Upgrade existing notifications table
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS reference_type TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS reference_id TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS deep_link TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS title_ar TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS body_ar TEXT;

CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- 2. Notification Preferences
CREATE TABLE IF NOT EXISTS notification_preferences (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type       TEXT NOT NULL, -- 'order_updates', 'rental_reminders', 'payouts', 'system'
  push_on    BOOLEAN NOT NULL DEFAULT true,
  in_app_on  BOOLEAN NOT NULL DEFAULT true,
  email_on   BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, type)
);

ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own notification preferences" ON notification_preferences;
CREATE POLICY "Users manage own notification preferences"
  ON notification_preferences FOR ALL
  USING (user_id = auth.uid());

-- 3. FCM Device Tokens
CREATE TABLE IF NOT EXISTS device_tokens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token      TEXT NOT NULL UNIQUE,
  platform   TEXT CHECK (platform IN ('ios', 'android', 'web')),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own device tokens" ON device_tokens;
CREATE POLICY "Users manage own device tokens"
  ON device_tokens FOR ALL
  USING (user_id = auth.uid());

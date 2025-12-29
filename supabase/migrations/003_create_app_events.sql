-- App Events Table
-- Stores events received from the iOS app backend

CREATE TABLE IF NOT EXISTS app_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pilot_user_id UUID REFERENCES pilot_users(id) ON DELETE CASCADE,
  phone_e164 TEXT NOT NULL,
  event_type TEXT NOT NULL CHECK (event_type IN (
    'installed',
    'commitment_created',
    'feedback_submitted'
  )),
  event_data JSONB, -- Flexible JSON for event-specific data
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_app_events_pilot_user ON app_events(pilot_user_id);
CREATE INDEX idx_app_events_phone ON app_events(phone_e164);
CREATE INDEX idx_app_events_type ON app_events(event_type);
CREATE INDEX idx_app_events_created ON app_events(created_at);


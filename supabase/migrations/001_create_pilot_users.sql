-- Pilot Users Table
-- Stores user state and configuration for WhatsApp pilot

CREATE TABLE IF NOT EXISTS pilot_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_e164 TEXT NOT NULL UNIQUE,
  pilot_start_monday_noon_nyc TIMESTAMPTZ,
  pause BOOLEAN DEFAULT FALSE,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'briefing_pending_confirmation',
  last_error TEXT,
  last_outbound_at TIMESTAMPTZ,
  next_nudge_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_pilot_users_phone ON pilot_users(phone_e164);
CREATE INDEX idx_pilot_users_status ON pilot_users(status);
CREATE INDEX idx_pilot_users_next_nudge ON pilot_users(next_nudge_at) WHERE pause = FALSE;
CREATE INDEX idx_pilot_users_pause ON pilot_users(pause);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_pilot_users_updated_at
  BEFORE UPDATE ON pilot_users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Status enum check (optional, but helpful for data integrity)
-- Note: PostgreSQL doesn't have native enums in this setup, but we can add a check constraint
ALTER TABLE pilot_users ADD CONSTRAINT check_status 
  CHECK (status IN (
    'briefing_pending_confirmation',
    'briefing_sent',
    'install_pending',
    'install_confirmed',
    'commitment_pending',
    'commitment_created',
    'monitoring',
    'week_end',
    'feedback_pending',
    'feedback_submitted'
  ));


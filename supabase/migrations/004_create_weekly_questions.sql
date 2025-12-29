-- Weekly Questions Table
-- Stores feedback question templates for each week

CREATE TABLE IF NOT EXISTS weekly_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_index INTEGER NOT NULL CHECK (week_index >= 1 AND week_index <= 4),
  questions_json JSONB NOT NULL, -- Array of question objects
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(week_index)
);

-- Index for active questions
CREATE INDEX idx_weekly_questions_active ON weekly_questions(active) WHERE active = TRUE;
CREATE INDEX idx_weekly_questions_week ON weekly_questions(week_index);

-- Updated_at trigger
CREATE TRIGGER update_weekly_questions_updated_at
  BEFORE UPDATE ON weekly_questions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();


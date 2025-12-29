-- Message Log Table
-- Stores all sent and received WhatsApp messages

CREATE TABLE IF NOT EXISTS message_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pilot_user_id UUID REFERENCES pilot_users(id) ON DELETE CASCADE,
  phone_e164 TEXT NOT NULL,
  direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  message_type TEXT, -- 'text', 'template', 'status'
  template_name TEXT, -- If message_type is 'template'
  content TEXT,
  whatsapp_message_id TEXT, -- Meta's message ID
  whatsapp_status TEXT, -- 'sent', 'delivered', 'read', 'failed'
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_message_log_pilot_user ON message_log(pilot_user_id);
CREATE INDEX idx_message_log_phone ON message_log(phone_e164);
CREATE INDEX idx_message_log_direction ON message_log(direction);
CREATE INDEX idx_message_log_created ON message_log(created_at);
CREATE INDEX idx_message_log_whatsapp_id ON message_log(whatsapp_message_id);


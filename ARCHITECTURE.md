# PayAttentionClub Pilot Agent - Architecture & Implementation Plan

This is the complete technical specification for the PayAttentionClub WhatsApp Pilot Agent system.

## Mission

PayAttentionClub Pilot Agent is an automated WhatsApp messaging system that guides users through the PayAttentionClub app onboarding and weekly commitment cycle. It provides personalized nudges, reminders, and feedback collection via WhatsApp Business Platform, powered by Supabase and managed through Airtable.

## Technical Overview

### Core Stack
- **WhatsApp Business Platform (Cloud API)**: Messaging channel
- **Supabase**: Database + Edge Functions + Cron scheduling
- **Airtable**: Admin console/UI for managing pilot users
- **LLM Integration**: Optional message variation and behavior-aware feedback

### System Architecture

| Component | Purpose | Technology |
|-----------|---------|------------|
| WhatsApp Cloud API | Messaging channel | Meta Business Platform |
| Supabase Database | Source of truth | PostgreSQL |
| Supabase Edge Functions | Business logic engine | Deno runtime |
| Supabase Cron | Scheduled tasks | pg_cron + pg_net |
| Airtable | Admin console | Airtable Automations |

### Data Flow

```
Airtable (Admin) → admin_ingest → Supabase DB
                                    ↓
App Events → app_event_ingest → Supabase DB
                                    ↓
                            scheduler_tick (cron)
                                    ↓
                    WhatsApp Cloud API → Users
                                    ↓
                    whatsapp_webhook → Supabase DB
```

## Phase 0 — Prerequisites

### 0.1 Dedicated Phone Number

**Requirement**: A business phone number capable of receiving SMS or voice calls for WhatsApp Business Platform verification.

**Options**:
- Twilio
- Vonage
- MessageBird
- Telnyx

**Checklist**:
- ✅ Number can receive SMS or voice call
- ✅ You control it (can receive verification code)
- ✅ Number dedicated to PAC support/pilot

## Phase 1 — WhatsApp Business Platform Setup

### 1.1 Create Meta Assets

1. Create/use a Meta Business Manager account
2. Create a Meta Developer App
3. Add WhatsApp product to the app

**Location**: Meta Developer Dashboard + Business Settings

### 1.2 Register Phone Number

1. Add phone number to WhatsApp Business Account (WABA)
2. Complete registration + verification (SMS/voice)
3. Note the `WABA_PHONE_NUMBER_ID` for API calls

### 1.3 Create Message Templates

Create WhatsApp message templates for business-initiated messages (required for messages outside 24h window):

- **Briefing link** (first outbound)
- **Install reminder**
- **Pilot kickoff** (Monday noon)
- **Commitment reminder**
- **Weekly feedback request**

**Note**: Templates must be approved by Meta before use.

### 1.4 Configure Webhooks

Configure Meta webhooks to point to Supabase Edge Function:

- **Callback URL**: `https://<project>.functions.supabase.co/whatsapp_webhook`
- **Verify Token**: (string you choose, store in Supabase secrets)
- **Subscriptions**: WhatsApp messages, message statuses

## Phase 2 — Supabase Project Setup

### 2.1 Create Supabase Project

1. Create new Supabase project (e.g., `pac-whatsapp-pilot`)
2. Get credentials:
   - Project URL
   - Service role key (store securely)
   - DB connection details

### 2.2 Database Schema

**Core Tables**:

- `pilot_users`: User state and configuration
- `message_log`: All sent/received messages
- `app_events`: Events from the iOS app
- `weekly_questions`: Feedback question templates

**See**: SQL migrations in `supabase/migrations/` (to be created)

### 2.3 Enable Scheduling

Enable Supabase scheduling features:

1. Enable `pg_cron` extension
2. Enable `pg_net` extension
3. Create cron job to call `scheduler_tick` every 5–15 minutes

**Reference**: Supabase docs for pg_cron + pg_net setup

## Phase 3 — Airtable Admin Console

### 3.1 Airtable Base Structure

**Table: PilotUsers**

| Field | Type | Description |
|-------|------|-------------|
| `phone_e164` | Text | E.164 formatted phone number |
| `pilot_start_monday_noon_nyc` | Date | Optional start date |
| `pause` | Checkbox | Pause messaging for this user |
| `notes` | Long text | Admin notes |
| `status` | Single select | Mirror from Supabase |
| `last_error` | Text | Mirror from Supabase |
| `last_outbound_at` | Date | Mirror from Supabase |

**Table: WeeklyQuestions**

| Field | Type | Description |
|-------|------|-------------|
| `week_index` | Number | Week 1–4 |
| `questions_json` | Long text | JSON array of questions |
| `active` | Checkbox | Whether this week is active |

### 3.2 Airtable → Supabase Automation

**Airtable Automation**:

- **Trigger**: "When record created or updated" on `PilotUsers`
- **Action**: "Send a webhook" (POST)
- **URL**: `https://<project>.functions.supabase.co/admin_ingest`
- **Body**: Include `record_id`, `phone_e164`, `pilot_start_monday_noon_nyc`, `pause`, `notes`

## Phase 4 — Supabase Edge Functions

### 4.1 admin_ingest

**Purpose**: Receives Airtable webhook payload and upserts pilot users.

**Responsibilities**:
- Normalize `phone_e164` format
- Upsert `pilot_users` record
- Set initial state: `briefing_pending_confirmation`
- Set `next_nudge_at = now()`

**Location**: `supabase/functions/admin_ingest/index.ts`

### 4.2 whatsapp_webhook

**Purpose**: Endpoint that Meta calls for inbound messages and delivery statuses.

**Responsibilities**:
- Handle Meta verification handshake (verify token check)
- Receive inbound messages → log to `message_log`
- Receive delivery statuses → update `message_log`
- Detect "STOP" command → set `paused=true` in `pilot_users`

**Location**: `supabase/functions/whatsapp_webhook/index.ts`

### 4.3 app_event_ingest

**Purpose**: Receives events from the iOS app backend.

**Triggered by**:
- "I installed" confirmation button
- "Commitment created" event
- "Weekly feedback submitted" event

**Responsibilities**:
- Insert into `app_events` table
- Update `pilot_users` state accordingly
- Update `next_nudge_at` based on event type

**Location**: `supabase/functions/app_event_ingest/index.ts`

### 4.4 scheduler_tick

**Purpose**: The brain of the system. Called by cron every 5–15 minutes.

**Responsibilities**:
1. Query users where:
   - `paused = false`
   - `next_nudge_at <= now()`
   - `state` in: `briefing`, `install`, `no_commitment`, `feedback_pending`
2. For each user, deterministically determine:
   - Which message should be sent
   - Message type (template or text)
   - Message content (optionally via LLM)
3. Send message via WhatsApp Cloud API
4. Log to `message_log`
5. Update:
   - `last_outbound_at = now()`
   - `next_nudge_at` (based on state and message type)
   - State transitions as needed

**State Machine**:
```
briefing_pending_confirmation → briefing_sent → install_pending
install_pending → install_confirmed → commitment_pending
commitment_pending → commitment_created → monitoring
monitoring → week_end → feedback_pending
feedback_pending → feedback_submitted → commitment_pending (next week)
```

**Location**: `supabase/functions/scheduler_tick/index.ts`

### 4.5 airtable_sync (Optional)

**Purpose**: Push status updates back to Airtable so admin console shows live state.

**Responsibilities**:
- Read `pilot_users` changes
- Update corresponding Airtable records via Airtable API
- Sync: `status`, `last_error`, `last_outbound_at`

**Location**: `supabase/functions/airtable_sync/index.ts`

## Phase 5 — WhatsApp Cloud API Integration

### 5.1 Store Secrets

Store in Supabase Vault (recommended):

- `META_WABA_PHONE_NUMBER_ID`
- `META_ACCESS_TOKEN`
- `WHATSAPP_VERIFY_TOKEN`
- `AIRTABLE_API_KEY` (if using airtable_sync)
- `AIRTABLE_BASE_ID` (if using airtable_sync)

### 5.2 WhatsApp Send Helpers

**Functions to implement**:

- `sendWhatsAppTemplate(to, templateName, components)`: Send approved template message
- `sendWhatsAppText(to, text)`: Send free-form text (only within 24h window)

**Note**: For pilot, prefer templates to keep it simple and compliant.

## Phase 6 — Scheduling & Time Handling

### 6.1 Time Zone Handling

**Critical**: All timestamps stored in UTC.

**Conversion Logic**:
- Store "Monday 12:00 NYC" as UTC timestamp for each cohort start
- For weekly cadence: compute next Monday noon (NYC) → convert to UTC
- Use timezone libraries (e.g., `date-fns-tz`) for accurate conversions

### 6.2 Cron Job Setup

**Supabase Cron Configuration**:

```sql
-- Example cron job (runs every 5 minutes)
SELECT cron.schedule(
  'scheduler_tick',
  '*/5 * * * *',
  $$
  SELECT net.http_post(
    url := 'https://<project>.functions.supabase.co/scheduler_tick',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer <service_role_key>"}'::jsonb
  );
  $$
);
```

**Frequency**: Every 5–15 minutes (adjust based on pilot needs)

## Phase 7 — LLM Integration (Optional)

### 7.1 Message Variation

**Use Case**: Generate varied message copy while maintaining tone and constraints.

**Implementation**:
- In `scheduler_tick`, determine `message_type`:
  - `install_reminder`
  - `briefing_reminder`
  - `commitment_reminder`
  - `feedback_request`
- Call LLM with strict constraints:
  - Length limit (WhatsApp message limits)
  - Tone: supportive, no shame
  - Include required information (links, deadlines)

### 7.2 Behavior-Aware Feedback Questions

**Use Case**: Generate personalized weekly feedback questions based on user behavior.

**Implementation**:
1. Build structured `weekly_report` (facts only):
   - Total usage vs. limit
   - Days over limit
   - Penalty accumulated
   - App breakdown (if available)
2. Send to LLM with prompt:
   - Generate 2–4 questions
   - Optional: 1–2 sentence reflection
3. Store in `weekly_questions` or send directly

## Phase 8 — Testing Plan

### 8.1 Onboarding Path Test

1. Add your own number to Airtable `PilotUsers`
2. Verify `admin_ingest` creates user in Supabase
3. Wait for `scheduler_tick` to send briefing template
4. Complete briefing confirmation (via link or reply)
5. Tap "I installed" in app → verify `app_event_ingest` receives event
6. Confirm reminders stop and state advances to `commitment_pending`

### 8.2 Weekly Cycle Test

1. Simulate Monday noon NYC by setting `start_at_utc` to "now + 2 min"
2. Verify kickoff message sent at correct time
3. Create commitment in app → verify reminders stop
4. Trigger feedback request at week end
5. Submit feedback → verify state resets for next week

### 8.3 Error Handling Test

- Test invalid phone numbers
- Test webhook verification failures
- Test WhatsApp API rate limits
- Test paused users (should not receive messages)

## Deliverables Structure

```
payattentionclub-pilotagent/
├── ARCHITECTURE.md (this file)
├── supabase/
│   ├── migrations/
│   │   ├── 001_create_pilot_users.sql
│   │   ├── 002_create_message_log.sql
│   │   ├── 003_create_app_events.sql
│   │   ├── 004_create_weekly_questions.sql
│   │   └── 005_enable_cron.sql
│   └── functions/
│       ├── admin_ingest/
│       │   └── index.ts
│       ├── whatsapp_webhook/
│       │   └── index.ts
│       ├── app_event_ingest/
│       │   └── index.ts
│       ├── scheduler_tick/
│       │   └── index.ts
│       └── airtable_sync/
│           └── index.ts
└── README.md
```

## Implementation Order

1. **Phase 0**: Get phone number
2. **Phase 1**: Set up WhatsApp Business Platform
3. **Phase 2**: Create Supabase project + database schema
4. **Phase 3**: Build Airtable base + automation
5. **Phase 4**: Implement Edge Functions (start with `admin_ingest`, then `whatsapp_webhook`, then `scheduler_tick`)
6. **Phase 5**: Wire WhatsApp API sending
7. **Phase 6**: Set up cron scheduling
8. **Phase 7**: Add LLM integration (optional, can be added later)
9. **Phase 8**: End-to-end testing

## Key Constraints & Notes

- **WhatsApp 24h Window**: Free-form text messages only work within 24h of user's last message. Use templates for business-initiated messages outside this window.
- **Template Approval**: WhatsApp templates must be approved by Meta before use. Plan for approval time.
- **Rate Limits**: WhatsApp Cloud API has rate limits. Implement retry logic and exponential backoff.
- **Privacy**: Store phone numbers in E.164 format. Never log full message content in production logs.
- **State Management**: All state transitions should be deterministic and logged for debugging.

## Summary

**Goal**: An automated WhatsApp messaging system that guides PayAttentionClub users through onboarding and weekly commitment cycles, with admin control via Airtable and reliable scheduling via Supabase.

**Core Principle**: Supabase is the source of truth. Airtable is the admin interface. WhatsApp is the communication channel. All business logic lives in Edge Functions.


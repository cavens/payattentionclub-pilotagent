# PayAttentionClub Pilot Agent

Automated WhatsApp messaging system for guiding PayAttentionClub users through onboarding and weekly commitment cycles.

## Overview

This system uses:
- **WhatsApp Business Platform (Cloud API)** for messaging
- **Supabase** for database, Edge Functions, and scheduling
- **Airtable** for admin console
- **LLM** (optional) for message variation and personalized feedback

## Project Structure

```
payattentionclub-pilotagent/
├── ARCHITECTURE.md          # Complete technical specification
├── PHASE1_CHECKLIST.md      # Step-by-step Meta/WhatsApp setup guide
├── README.md                # This file
└── supabase/
    ├── migrations/          # Database schema migrations
    │   ├── 001_create_pilot_users.sql
    │   ├── 002_create_message_log.sql
    │   ├── 003_create_app_events.sql
    │   ├── 004_create_weekly_questions.sql
    │   └── 005_enable_cron.sql
    └── functions/           # Supabase Edge Functions
        ├── admin_ingest/    # Receives Airtable webhooks
        ├── whatsapp_webhook/# Handles Meta webhooks
        ├── app_event_ingest/# Receives iOS app events
        ├── scheduler_tick/  # Main scheduling brain
        └── airtable_sync/   # Syncs status back to Airtable
```

## Quick Start

### Prerequisites

1. ✅ Phone number for WhatsApp Business Platform (Phase 0)
2. Meta Business Manager account
3. Supabase account
4. Airtable account

### Setup Steps

1. **Phase 1**: Set up WhatsApp Business Platform
   - Follow `PHASE1_CHECKLIST.md`
   - Get access token, phone number ID, and create message templates

2. **Phase 2**: Create Supabase project
   ```bash
   # Create new Supabase project at https://supabase.com
   # Run migrations in order (001-005)
   ```

3. **Phase 3**: Set up Airtable base
   - Create `PilotUsers` and `WeeklyQuestions` tables
   - Set up automation to call `admin_ingest`

4. **Phase 4**: Deploy Edge Functions
   ```bash
   # Deploy functions to Supabase
   supabase functions deploy admin_ingest
   supabase functions deploy whatsapp_webhook
   supabase functions deploy app_event_ingest
   supabase functions deploy scheduler_tick
   supabase functions deploy airtable_sync
   ```

5. **Phase 5**: Configure secrets
   - Add to Supabase Vault:
     - `META_WABA_PHONE_NUMBER_ID`
     - `META_ACCESS_TOKEN`
     - `WHATSAPP_VERIFY_TOKEN`
     - `AIRTABLE_API_KEY` (if using airtable_sync)
     - `AIRTABLE_BASE_ID` (if using airtable_sync)

6. **Phase 6**: Set up cron job
   - Run migration or manually create cron job for `scheduler_tick`

## Development

### Local Development

```bash
# Install Supabase CLI
npm install -g supabase

# Link to your project
supabase link --project-ref <your-project-ref>

# Run migrations locally
supabase db reset

# Deploy functions
supabase functions deploy <function-name>
```

### Testing

See `ARCHITECTURE.md` Phase 8 for testing plan.

## Documentation

- **ARCHITECTURE.md**: Complete technical specification
- **PHASE1_CHECKLIST.md**: WhatsApp Business Platform setup guide

## Status

- [x] Phase 0: Phone number obtained
- [ ] Phase 1: WhatsApp Business Platform setup
- [ ] Phase 2: Supabase project + database
- [ ] Phase 3: Airtable admin console
- [ ] Phase 4: Edge Functions implementation
- [ ] Phase 5: WhatsApp API integration
- [ ] Phase 6: Cron scheduling
- [ ] Phase 7: LLM integration (optional)
- [ ] Phase 8: End-to-end testing


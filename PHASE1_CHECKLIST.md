# Phase 1: WhatsApp Business Platform Setup Checklist

## Prerequisites
- ✅ Phone number obtained (Phase 0 complete)

## Step 1.1: Create Meta Business Manager

1. Go to [Meta Business Manager](https://business.facebook.com/)
2. Create a Business Manager account (or use existing)
3. Note your Business Manager ID

## Step 1.2: Create Meta Developer App

1. Go to [Meta Developers](https://developers.facebook.com/)
2. Click "My Apps" → "Create App"
3. Choose "Business" as the app type
4. Fill in:
   - App Name: "PayAttentionClub Pilot" (or similar)
   - App Contact Email: (your email)
5. Click "Create App"

## Step 1.3: Add WhatsApp Product

1. In your app dashboard, find "Add Product" or "Products" section
2. Find "WhatsApp" and click "Set Up"
3. You'll be taken to WhatsApp configuration

## Step 1.4: Register Phone Number

1. In WhatsApp settings, go to "Phone numbers" or "API Setup"
2. Click "Add phone number"
3. Enter your phone number (E.164 format: +1234567890)
4. Choose verification method (SMS or Voice)
5. Enter the verification code you receive
6. Complete registration

**Important**: Note down:
- `WABA_PHONE_NUMBER_ID` (found in phone number details)
- You'll need this for API calls

## Step 1.5: Get Access Token

1. In WhatsApp settings, go to "API Setup" or "Access Tokens"
2. Generate a temporary access token (for testing)
3. For production, you'll need to:
   - Set up a System User in Business Manager
   - Assign WhatsApp permissions
   - Generate a permanent token

**Important**: Store this token securely (you'll add it to Supabase secrets later)

## Step 1.6: Create Message Templates

1. Go to "Message Templates" in WhatsApp settings
2. Create templates for each message type:

### Template 1: Briefing Link
- **Name**: `briefing_link`
- **Category**: UTILITY
- **Language**: English (US)
- **Body**: "Hi! Welcome to PayAttentionClub pilot. Get started: {{1}}"
- **Variables**: 1 (URL)

### Template 2: Install Reminder
- **Name**: `install_reminder`
- **Category**: UTILITY
- **Language**: English (US)
- **Body**: "Don't forget to install the PayAttentionClub app! Download here: {{1}}"

### Template 3: Pilot Kickoff
- **Name**: `pilot_kickoff`
- **Category**: UTILITY
- **Language**: English (US)
- **Body**: "Your PayAttentionClub week starts now! Set your limit and commit. Open the app to get started."

### Template 4: Commitment Reminder
- **Name**: `commitment_reminder`
- **Category**: UTILITY
- **Language**: English (US)
- **Body**: "Time to set your commitment for this week! Open the app to lock in your limit and penalty."

### Template 5: Weekly Feedback Request
- **Name**: `weekly_feedback`
- **Category**: UTILITY
- **Language**: English (US)
- **Body**: "Week complete! How did it go? Share your feedback: {{1}}"

**Note**: Templates must be approved by Meta before use (can take a few hours to days)

## Step 1.7: Configure Webhooks

1. In WhatsApp settings, go to "Configuration" → "Webhooks"
2. Click "Edit" or "Add Webhook"
3. Set:
   - **Callback URL**: `https://<your-project>.supabase.co/functions/v1/whatsapp_webhook`
     - ⚠️ Replace `<your-project>` with your actual Supabase project reference
     - ⚠️ You'll need to deploy the `whatsapp_webhook` function first (Phase 4)
   - **Verify Token**: Choose a random string (e.g., `pac_verify_token_2024`)
     - ⚠️ Store this - you'll add it to Supabase secrets
4. Subscribe to:
   - ✅ `messages` (inbound messages)
   - ✅ `message_status` (delivery statuses)
5. Click "Verify and Save"

**Note**: Meta will send a GET request to verify the webhook. Your Edge Function needs to handle this (we'll implement in Phase 4).

## Step 1.8: Test Webhook Verification

Once your `whatsapp_webhook` function is deployed, Meta will send a verification request:
- `GET /whatsapp_webhook?hub.mode=subscribe&hub.challenge=<random>&hub.verify_token=<your_token>`
- Your function should return the `hub.challenge` value if the token matches

## What You'll Need Later

After completing Phase 1, you'll need these values for Supabase secrets:

- `META_WABA_PHONE_NUMBER_ID`: From Step 1.4
- `META_ACCESS_TOKEN`: From Step 1.5
- `WHATSAPP_VERIFY_TOKEN`: From Step 1.7

## Next Steps

After Phase 1 is complete:
1. Create Supabase project (Phase 2.1)
2. Run database migrations (Phase 2.2)
3. Deploy Edge Functions (Phase 4)
4. Add secrets to Supabase Vault (Phase 5.1)


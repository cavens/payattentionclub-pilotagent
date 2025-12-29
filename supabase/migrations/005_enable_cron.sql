-- Enable pg_cron and pg_net extensions for scheduled tasks
-- These extensions allow us to schedule Edge Function calls

-- Enable pg_cron (for scheduling)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Enable pg_net (for HTTP requests from cron)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Note: The actual cron job will be created after Edge Functions are deployed
-- Example cron job (to be created manually or via migration after functions are live):
-- 
-- SELECT cron.schedule(
--   'scheduler_tick',
--   '*/5 * * * *', -- Every 5 minutes
--   $$
--   SELECT net.http_post(
--     url := 'https://<project>.functions.supabase.co/scheduler_tick',
--     headers := jsonb_build_object(
--       'Content-Type', 'application/json',
--       'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
--     ),
--     body := '{}'::jsonb
--   );
--   $$
-- );

-- For now, we'll create a placeholder that can be updated after deployment
-- The actual URL and service role key will need to be set after Supabase project is created


-- Enable pg_net for HTTP cron triggers and schedule charge-rentals daily at 00:00 UTC.
-- Configure database settings after applying (replace with your CRON_SECRET):
--   ALTER DATABASE postgres SET app.settings.supabase_url = 'https://fsdfqcnjcjtdmdjshrvu.supabase.co';
--   ALTER DATABASE postgres SET app.settings.cron_secret = 'your-cron-secret';

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

DO $outer$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'gadgetchai-charge-rentals-daily';

    PERFORM cron.schedule(
      'gadgetchai-charge-rentals-daily',
      '0 0 * * *',
      $cron$
      SELECT net.http_post(
        url := coalesce(
          current_setting('app.settings.supabase_url', true),
          'https://fsdfqcnjcjtdmdjshrvu.supabase.co'
        ) || '/functions/v1/charge-rentals',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || coalesce(current_setting('app.settings.cron_secret', true), '')
        ),
        body := '{}'::jsonb
      );
      $cron$
    );
  END IF;
END $outer$;

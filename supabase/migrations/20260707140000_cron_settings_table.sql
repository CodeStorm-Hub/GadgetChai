-- Store cron config (ALTER DATABASE not permitted on hosted Supabase).
-- Values are inserted by scripts/wire-production.mjs after deploy.

CREATE TABLE IF NOT EXISTS public.app_settings (
  key text PRIMARY KEY,
  value text NOT NULL
);

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS app_settings_service_only ON public.app_settings;
CREATE POLICY app_settings_service_only ON public.app_settings
  FOR ALL USING (false);

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
        url := (SELECT value FROM public.app_settings WHERE key = 'supabase_url') || '/functions/v1/charge-rentals',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (SELECT value FROM public.app_settings WHERE key = 'cron_secret')
        ),
        body := '{}'::jsonb
      );
      $cron$
    );
  END IF;
END $outer$;

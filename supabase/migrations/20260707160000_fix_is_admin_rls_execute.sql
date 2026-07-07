-- RLS policies reference is_admin(); anon/authenticated need EXECUTE for evaluation.
-- handle_new_user remains trigger-only (no EXECUTE grant).
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS trial_start_date timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS subscription_end_date timestamptz,
  ADD COLUMN IF NOT EXISTS revenuecat_id text;

CREATE OR REPLACE FUNCTION is_trial_active(p_user_id uuid)
RETURNS boolean AS $$
  SELECT (now() < (created_at + interval '30 days'))
  FROM profiles WHERE id = p_user_id;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

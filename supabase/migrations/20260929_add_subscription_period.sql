ALTER TABLE profiles ADD COLUMN IF NOT EXISTS subscription_period text DEFAULT null;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS stripe_customer_id text DEFAULT null;

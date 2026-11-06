ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS subscription_will_renew boolean DEFAULT true;

-- Adicionar campo is_admin na tabela profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;

-- Para marcar um usuário como admin, execute:
-- UPDATE profiles SET is_admin = true WHERE email = 'seu-email@example.com';

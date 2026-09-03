-- =============================================
-- 1. Tabela app_config (chave-valor para configurações do admin)
-- =============================================
CREATE TABLE IF NOT EXISTS app_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Valores padrão
INSERT INTO app_config (key, value) VALUES
  ('diary_penalty', '-5'),
  ('inactivity_penalty', '-3')
ON CONFLICT (key) DO NOTHING;

-- RLS: somente admins podem alterar, todos autenticados podem ler
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read app_config" ON app_config;
CREATE POLICY "Authenticated users can read app_config"
  ON app_config FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Admins can manage app_config" ON app_config;
CREATE POLICY "Admins can manage app_config"
  ON app_config FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- =============================================
-- 2. Pontuação por pergunta no quiz + total_points decimal
-- =============================================
ALTER TABLE quiz_questions
  ADD COLUMN IF NOT EXISTS faith_points_correct DOUBLE PRECISION NOT NULL DEFAULT 1.0;

ALTER TABLE quiz_questions
  ADD COLUMN IF NOT EXISTS faith_points_wrong DOUBLE PRECISION NOT NULL DEFAULT 0.0;

ALTER TABLE quiz_attempts
  ALTER COLUMN total_points TYPE DOUBLE PRECISION;

-- =============================================
-- 4. Colunas de áudio na tabela tree_messages
-- =============================================
ALTER TABLE tree_messages
  ADD COLUMN IF NOT EXISTS audio_url TEXT;

ALTER TABLE tree_messages
  ADD COLUMN IF NOT EXISTS audio_file_name TEXT;

-- =============================================
-- 5. Bucket de storage para áudios da árvore
-- =============================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('tree-audio', 'tree-audio', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Anyone can read tree audio" ON storage.objects;
CREATE POLICY "Anyone can read tree audio"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'tree-audio');

DROP POLICY IF EXISTS "Admins can upload tree audio" ON storage.objects;
CREATE POLICY "Admins can upload tree audio"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'tree-audio'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can delete tree audio" ON storage.objects;
CREATE POLICY "Admins can delete tree audio"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'tree-audio'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

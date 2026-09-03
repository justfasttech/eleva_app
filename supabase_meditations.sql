-- ============================================
-- Tabela: meditations
-- Meditações (sessões guiadas e sons ambiente)
-- ============================================

CREATE TABLE IF NOT EXISTS meditations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  duration_minutes INTEGER NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('guiada', 'ambiente')),
  audio_url TEXT,
  audio_file_name TEXT,
  faith_points INTEGER NOT NULL DEFAULT 1,
  is_published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION update_meditation_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_meditation_updated_at
  BEFORE UPDATE ON meditations
  FOR EACH ROW
  EXECUTE FUNCTION update_meditation_updated_at();

-- RLS
ALTER TABLE meditations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read published meditations"
  ON meditations FOR SELECT
  TO authenticated
  USING (is_published = true);

CREATE POLICY "Admins can manage all meditations"
  ON meditations FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

ALTER PUBLICATION supabase_realtime ADD TABLE meditations;

CREATE INDEX idx_meditations_type ON meditations(type);
CREATE INDEX idx_meditations_published ON meditations(is_published);

-- ============================================
-- Storage bucket para áudios de meditação
-- ============================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('meditation-audio', 'meditation-audio', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public can read meditation audio"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'meditation-audio');

CREATE POLICY "Admins can upload meditation audio"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'meditation-audio'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

CREATE POLICY "Admins can update meditation audio"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'meditation-audio'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

CREATE POLICY "Admins can delete meditation audio"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'meditation-audio'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

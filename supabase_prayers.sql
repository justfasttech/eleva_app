-- ============================================
-- Tabela: prayers
-- Oracoes (novo tipo de conteudo)
-- ============================================

CREATE TABLE IF NOT EXISTS prayers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  theme_id UUID NOT NULL REFERENCES content_themes(id) ON DELETE RESTRICT,
  faith_points INTEGER NOT NULL DEFAULT 1,
  is_published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_prayer_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_prayer_updated_at
  BEFORE UPDATE ON prayers
  FOR EACH ROW
  EXECUTE FUNCTION update_prayer_updated_at();

-- RLS
ALTER TABLE prayers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read published prayers"
  ON prayers FOR SELECT
  TO authenticated
  USING (is_published = true);

CREATE POLICY "Admins can manage all prayers"
  ON prayers FOR ALL
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

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE prayers;

-- Indices
CREATE INDEX idx_prayers_theme ON prayers(theme_id);
CREATE INDEX idx_prayers_published ON prayers(is_published);

-- ============================================
-- Tabela: content_themes
-- Temas de conteudo (amor, fe, esperanca, etc.)
-- Separado de post_themes (que e para comunidade)
-- ============================================

CREATE TABLE IF NOT EXISTS content_themes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  icon_name TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_content_theme_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_content_theme_updated_at
  BEFORE UPDATE ON content_themes
  FOR EACH ROW
  EXECUTE FUNCTION update_content_theme_updated_at();

-- RLS
ALTER TABLE content_themes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read active themes"
  ON content_themes FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "Admins can manage all themes"
  ON content_themes FOR ALL
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
ALTER PUBLICATION supabase_realtime ADD TABLE content_themes;

-- Indice
CREATE INDEX idx_content_themes_active ON content_themes(is_active);

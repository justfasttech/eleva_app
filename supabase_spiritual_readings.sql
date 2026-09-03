-- ============================================
-- Tabela: spiritual_readings
-- Leituras espirituais (textos, parabolas, salmos, versiculos, sabedorias)
-- ============================================

CREATE TABLE IF NOT EXISTS spiritual_readings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('textos', 'parabolas', 'salmos', 'versiculos', 'sabedorias')),
  author TEXT,
  reference TEXT,
  faith_points INTEGER NOT NULL DEFAULT 1,
  is_published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_reading_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_reading_updated_at
  BEFORE UPDATE ON spiritual_readings
  FOR EACH ROW
  EXECUTE FUNCTION update_reading_updated_at();

-- RLS
ALTER TABLE spiritual_readings ENABLE ROW LEVEL SECURITY;

-- Qualquer usuario autenticado pode ler leituras publicadas
CREATE POLICY "Authenticated users can read published readings"
  ON spiritual_readings FOR SELECT
  TO authenticated
  USING (is_published = true);

-- Admins podem fazer tudo (via service_role ou checagem de is_admin)
CREATE POLICY "Admins can manage all readings"
  ON spiritual_readings FOR ALL
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
ALTER PUBLICATION supabase_realtime ADD TABLE spiritual_readings;

-- Indice por categoria para filtragem rapida
CREATE INDEX idx_spiritual_readings_category ON spiritual_readings(category);
CREATE INDEX idx_spiritual_readings_published ON spiritual_readings(is_published);

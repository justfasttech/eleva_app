-- ============================================
-- Seed: Temas de conteudo + vincular conteudos existentes
-- Executar APOS supabase_content_themes.sql e supabase_theme_and_unlocks.sql
-- ============================================

-- 1. Inserir temas de conteudo
INSERT INTO content_themes (name, description, icon_name) VALUES
  ('Amor', 'Conteudos sobre amor, compaixao e relacionamentos', 'favorite'),
  ('Fe', 'Conteudos sobre fe, confianca e crenca', 'auto_awesome'),
  ('Esperanca', 'Conteudos sobre esperanca, otimismo e futuro', 'wb_sunny'),
  ('Gratidao', 'Conteudos sobre gratidao, reconhecimento e bencaos', 'volunteer_activism'),
  ('Superacao', 'Conteudos sobre superacao, forca e resiliencia', 'trending_up')
ON CONFLICT (name) DO NOTHING;

-- 2. Vincular leituras existentes ao tema "Fe" (default seguro)
UPDATE spiritual_readings
SET theme_id = (SELECT id FROM content_themes WHERE name = 'Fe')
WHERE theme_id IS NULL;

-- 3. Vincular meditacoes existentes ao tema "Esperanca" (default seguro)
UPDATE meditations
SET theme_id = (SELECT id FROM content_themes WHERE name = 'Esperanca')
WHERE theme_id IS NULL;

-- 4. Tornar theme_id NOT NULL nas tabelas
ALTER TABLE spiritual_readings ALTER COLUMN theme_id SET NOT NULL;
ALTER TABLE meditations ALTER COLUMN theme_id SET NOT NULL;

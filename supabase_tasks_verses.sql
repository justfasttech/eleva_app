-- Habilitar extensao moddatetime (caso nao esteja ativa)
CREATE EXTENSION IF NOT EXISTS moddatetime WITH SCHEMA extensions;

-- ============================================================
-- DAILY_TASKS — tarefas diarias gerenciadas pelo admin
-- ============================================================

CREATE TABLE IF NOT EXISTS daily_tasks (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title      TEXT NOT NULL,
  faith_points INTEGER NOT NULL DEFAULT 1,
  is_active  BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_daily_tasks_active ON daily_tasks (is_active) WHERE is_active = true;

ALTER TABLE daily_tasks ENABLE ROW LEVEL SECURITY;

-- Todos podem ler tarefas ativas
CREATE POLICY "Tarefas visiveis para todos"
  ON daily_tasks FOR SELECT
  USING (true);

-- Apenas admins podem inserir
CREATE POLICY "Admins inserem tarefas"
  ON daily_tasks FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- Apenas admins podem atualizar
CREATE POLICY "Admins atualizam tarefas"
  ON daily_tasks FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- Apenas admins podem excluir
CREATE POLICY "Admins excluem tarefas"
  ON daily_tasks FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- Trigger updated_at
CREATE OR REPLACE TRIGGER set_daily_tasks_updated_at
  BEFORE UPDATE ON daily_tasks
  FOR EACH ROW
  EXECUTE FUNCTION extensions.moddatetime(updated_at);

-- ============================================================
-- DAILY_VERSES — versiculos/mensagens diarias
-- ============================================================

CREATE TABLE IF NOT EXISTS daily_verses (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  message    TEXT NOT NULL,
  is_active  BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_daily_verses_active ON daily_verses (is_active) WHERE is_active = true;

ALTER TABLE daily_verses ENABLE ROW LEVEL SECURITY;

-- Todos podem ler versiculos ativos
CREATE POLICY "Versiculos visiveis para todos"
  ON daily_verses FOR SELECT
  USING (true);

-- Apenas admins podem inserir
CREATE POLICY "Admins inserem versiculos"
  ON daily_verses FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- Apenas admins podem atualizar
CREATE POLICY "Admins atualizam versiculos"
  ON daily_verses FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- Apenas admins podem excluir
CREATE POLICY "Admins excluem versiculos"
  ON daily_verses FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- Trigger updated_at
CREATE OR REPLACE TRIGGER set_daily_verses_updated_at
  BEFORE UPDATE ON daily_verses
  FOR EACH ROW
  EXECUTE FUNCTION extensions.moddatetime(updated_at);

-- ============================================================
-- PRE-CADASTRO: 10 mensagens diarias
-- ============================================================

INSERT INTO daily_verses (message) VALUES
  ('"A fé é a certeza daquilo que esperamos e a prova das coisas que não vemos." — Hebreus 11:1'),
  ('"Tudo posso naquele que me fortalece." — Filipenses 4:13'),
  ('"O Senhor é o meu pastor; nada me faltará." — Salmos 23:1'),
  ('"Entrega o teu caminho ao Senhor; confia nele, e ele tudo fará." — Salmos 37:5'),
  ('"Porque Deus amou o mundo de tal maneira que deu o seu Filho unigênito." — João 3:16'),
  ('"Não temas, porque eu sou contigo; não te assombres, porque eu sou o teu Deus." — Isaías 41:10'),
  ('"Buscai primeiro o Reino de Deus, e a sua justiça, e todas estas coisas vos serão acrescentadas." — Mateus 6:33'),
  ('"Eu sou o caminho, a verdade e a vida." — João 14:6'),
  ('"Alegrem-se na esperança, sejam pacientes na tribulação, perseverem na oração." — Romanos 12:12'),
  ('"Pois onde estiver o vosso tesouro, aí estará também o vosso coração." — Mateus 6:21');

-- ============================================================
-- HABILITAR REALTIME
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE daily_tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE daily_verses;

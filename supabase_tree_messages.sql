-- ============================================
-- Tabela: tree_messages
-- Mensagens para cada nivel da arvore da fe
-- ============================================

CREATE TABLE IF NOT EXISTS tree_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  level INTEGER NOT NULL UNIQUE CHECK (level >= 1 AND level <= 14),
  name TEXT NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_tree_message_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_tree_message_updated_at
  BEFORE UPDATE ON tree_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_tree_message_updated_at();

-- RLS
ALTER TABLE tree_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read tree messages"
  ON tree_messages FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage tree messages"
  ON tree_messages FOR ALL
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
ALTER PUBLICATION supabase_realtime ADD TABLE tree_messages;

-- Seed com os valores atuais (hardcoded em tree_achievement_dialog.dart)
INSERT INTO tree_messages (level, name, message) VALUES
  (1, 'Semente', 'A fe esta nascendo no seu coracao. Tudo comeca aqui.'),
  (2, 'Broto', 'Um broto surge! Sua jornada espiritual comeca a tomar forma.'),
  (3, 'Raiz', 'Suas raizes estao se firmando na Palavra de Deus.'),
  (4, 'Crescimento', 'Sua fe esta crescendo e se fortalecendo atraves da oracao.'),
  (5, 'Fortalecimento', 'Voce esta se fortalecendo espiritualmente a cada dia.'),
  (6, 'Enraizamento', 'Sua fe ja tem base solida. Voce se mantem firme nas dificuldades.'),
  (7, 'Florescimento', 'Flores desabrocham! Sua vida espiritual esta florescendo.'),
  (8, 'Frutificacao', 'Voce comeca a dar frutos e impactar outras vidas com o amor de Deus.'),
  (9, 'Abundancia', 'A abundancia de Deus se manifesta na sua caminhada de fe.'),
  (10, 'Maturidade', 'Sua fe e solida e madura. Voce anda com Deus diariamente.'),
  (11, 'Sabedoria', 'A sabedoria divina guia seus passos e decisoes.'),
  (12, 'Resiliencia', 'Sua fe e resiliente. Nenhuma tempestade abala suas raizes.'),
  (13, 'Plenitude', 'Voce vive o proposito de Deus em plenitude e inspira muitos ao redor.'),
  (14, 'Arvore da Vida', 'Sua fe e uma Arvore da Vida — inspiracao para geracoes.')
ON CONFLICT (level) DO UPDATE SET name = EXCLUDED.name, message = EXCLUDED.message;

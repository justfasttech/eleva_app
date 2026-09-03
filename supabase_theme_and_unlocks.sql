-- ============================================
-- Migration: Adicionar theme_id nas tabelas de conteudo
-- + Tabela user_content_unlocks
-- + RPCs can_unlock_today e unlock_content
-- ============================================

-- 1. Adicionar theme_id nas tabelas existentes (nullable inicialmente, será NOT NULL após seed)
ALTER TABLE spiritual_readings
  ADD COLUMN IF NOT EXISTS theme_id UUID REFERENCES content_themes(id) ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS idx_spiritual_readings_theme ON spiritual_readings(theme_id);

ALTER TABLE meditations
  ADD COLUMN IF NOT EXISTS theme_id UUID REFERENCES content_themes(id) ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS idx_meditations_theme ON meditations(theme_id);

-- 2. Tabela de desbloqueios de conteudo
CREATE TABLE IF NOT EXISTS user_content_unlocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL CHECK (content_type IN ('reading', 'meditation', 'prayer')),
  content_id UUID NOT NULL,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, content_type, content_id)
);

CREATE INDEX idx_unlocks_user ON user_content_unlocks(user_id);
CREATE INDEX idx_unlocks_user_type ON user_content_unlocks(user_id, content_type);

-- RLS
ALTER TABLE user_content_unlocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own unlocks"
  ON user_content_unlocks FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own unlocks"
  ON user_content_unlocks FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Admins podem ver todos os desbloqueios
CREATE POLICY "Admins can read all unlocks"
  ON user_content_unlocks FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE user_content_unlocks;

-- 3. RPC: Verificar se pode desbloquear hoje (cutoff 7h local)
CREATE OR REPLACE FUNCTION can_unlock_today(
  p_user_id UUID,
  p_content_type TEXT,
  p_tz_offset_minutes INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_local_time TIMESTAMPTZ;
  v_cutoff TIMESTAMPTZ;
  v_count INT;
BEGIN
  v_user_local_time := NOW() + (p_tz_offset_minutes * INTERVAL '1 minute');

  v_cutoff := date_trunc('day', v_user_local_time) + INTERVAL '7 hours'
              - (p_tz_offset_minutes * INTERVAL '1 minute');

  IF v_user_local_time < (date_trunc('day', v_user_local_time) + INTERVAL '7 hours') THEN
    v_cutoff := v_cutoff - INTERVAL '1 day';
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM user_content_unlocks
  WHERE user_id = p_user_id
    AND content_type = p_content_type
    AND unlocked_at >= v_cutoff;

  RETURN v_count = 0;
END;
$$;

-- 4. RPC: Desbloquear conteudo (atomico: verifica + insere + soma faith_points)
CREATE OR REPLACE FUNCTION unlock_content(
  p_user_id UUID,
  p_content_type TEXT,
  p_content_id UUID,
  p_faith_points INT,
  p_tz_offset_minutes INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_can_unlock BOOLEAN;
BEGIN
  v_can_unlock := can_unlock_today(p_user_id, p_content_type, p_tz_offset_minutes);

  IF NOT v_can_unlock THEN
    RETURN FALSE;
  END IF;

  INSERT INTO user_content_unlocks (user_id, content_type, content_id)
  VALUES (p_user_id, p_content_type, p_content_id)
  ON CONFLICT (user_id, content_type, content_id) DO NOTHING;

  IF p_faith_points > 0 THEN
    UPDATE profiles
    SET pending_faith = COALESCE(pending_faith, 0) + p_faith_points
    WHERE id = p_user_id;
  END IF;

  RETURN TRUE;
END;
$$;

-- Permissoes
GRANT EXECUTE ON FUNCTION can_unlock_today(UUID, TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION unlock_content(UUID, TEXT, UUID, INT, INT) TO authenticated;

-- Migration: scoring_words decimais + daily_faith_merge às 7h com server time
-- Executar no Supabase SQL Editor

-- 1. Alterar scoring_words.points de INT para NUMERIC (suporte a decimais)
ALTER TABLE scoring_words ALTER COLUMN points TYPE NUMERIC(5,2);

-- 2. Adicionar last_merge_date na tabela profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_merge_date DATE;

-- 3. Criar RPC get_server_time para retornar hora do servidor
CREATE OR REPLACE FUNCTION get_server_time()
RETURNS TIMESTAMPTZ
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT NOW();
$$;

-- 4. Criar RPC daily_faith_merge
-- Valida no servidor se são 7h+ no fuso do usuário e se o merge não foi feito hoje
CREATE OR REPLACE FUNCTION daily_faith_merge(
  p_user_id UUID,
  p_tz_offset_minutes INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_local_time TIMESTAMPTZ;
  v_user_local_date DATE;
  v_user_local_hour INT;
  v_last_merge DATE;
  v_pending INT;
  v_current INT;
  v_new_level INT;
BEGIN
  -- Calcular hora local do usuário usando o fuso enviado (validado pelo servidor)
  v_user_local_time := NOW() + (p_tz_offset_minutes * INTERVAL '1 minute');
  v_user_local_date := v_user_local_time::DATE;
  v_user_local_hour := EXTRACT(HOUR FROM v_user_local_time);

  -- Só faz merge a partir das 7h
  IF v_user_local_hour < 7 THEN
    RETURN FALSE;
  END IF;

  -- Verificar se já fez merge hoje
  SELECT last_merge_date, pending_faith, faith_level
  INTO v_last_merge, v_pending, v_current
  FROM profiles
  WHERE id = p_user_id;

  IF v_last_merge IS NOT NULL AND v_last_merge >= v_user_local_date THEN
    RETURN FALSE;
  END IF;

  -- Sem pontos pendentes para merge
  IF v_pending IS NULL OR v_pending = 0 THEN
    -- Atualizar last_merge_date mesmo sem pontos pendentes
    UPDATE profiles
    SET last_merge_date = v_user_local_date
    WHERE id = p_user_id;
    RETURN FALSE;
  END IF;

  -- Calcular novo nível (max 70)
  v_new_level := LEAST(v_current + v_pending, 70);

  -- Aplicar merge
  UPDATE profiles
  SET faith_level = v_new_level,
      pending_faith = 0,
      last_merge_date = v_user_local_date
  WHERE id = p_user_id;

  -- Registrar no histórico
  INSERT INTO faith_history (user_id, faith_level, recorded_date)
  VALUES (p_user_id, v_new_level, v_user_local_date)
  ON CONFLICT (user_id, recorded_date)
  DO UPDATE SET faith_level = EXCLUDED.faith_level;

  RETURN TRUE;
END;
$$;

-- 5. Atualizar apply_faith_penalty para aceitar NUMERIC (decimais)
CREATE OR REPLACE FUNCTION apply_faith_penalty(
  p_user_id UUID,
  p_amount NUMERIC
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_pending INT;
  v_current INT;
  v_new_pending INT;
  v_projected INT;
BEGIN
  SELECT pending_faith, faith_level
  INTO v_pending, v_current
  FROM profiles
  WHERE id = p_user_id;

  v_new_pending := v_pending + ROUND(p_amount)::INT;
  v_projected := LEAST(GREATEST(v_current + v_new_pending, 0), 70);

  UPDATE profiles
  SET pending_faith = v_new_pending
  WHERE id = p_user_id;

  INSERT INTO faith_history (user_id, faith_level, recorded_date)
  VALUES (p_user_id, v_projected, CURRENT_DATE)
  ON CONFLICT (user_id, recorded_date)
  DO UPDATE SET faith_level = EXCLUDED.faith_level;
END;
$$;

-- 6. Permissões RLS (permitir chamada autenticada)
GRANT EXECUTE ON FUNCTION get_server_time() TO authenticated;
GRANT EXECUTE ON FUNCTION daily_faith_merge(UUID, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION apply_faith_penalty(UUID, NUMERIC) TO authenticated;

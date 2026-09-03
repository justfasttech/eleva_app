-- =============================================
-- Migração: Tudo relacionado a pontos de fé → DOUBLE PRECISION
-- =============================================

-- 1. profiles: faith_level e pending_faith
ALTER TABLE profiles
  ALTER COLUMN faith_level TYPE DOUBLE PRECISION;

ALTER TABLE profiles
  ALTER COLUMN pending_faith TYPE DOUBLE PRECISION;

-- 2. faith_history: faith_level
ALTER TABLE faith_history
  ALTER COLUMN faith_level TYPE DOUBLE PRECISION;

-- 3. Conteúdos: faith_points
ALTER TABLE spiritual_readings
  ALTER COLUMN faith_points TYPE DOUBLE PRECISION;

ALTER TABLE meditations
  ALTER COLUMN faith_points TYPE DOUBLE PRECISION;

ALTER TABLE prayers
  ALTER COLUMN faith_points TYPE DOUBLE PRECISION;

ALTER TABLE daily_tasks
  ALTER COLUMN faith_points TYPE DOUBLE PRECISION;

-- 4. Quiz questions: faith_points_correct e faith_points_wrong
ALTER TABLE quiz_questions
  ALTER COLUMN faith_points_correct TYPE DOUBLE PRECISION;

ALTER TABLE quiz_questions
  ALTER COLUMN faith_points_wrong TYPE DOUBLE PRECISION;

-- 5. Recriar merge_pending_faith com DOUBLE PRECISION
DROP FUNCTION IF EXISTS public.merge_pending_faith(UUID);
CREATE OR REPLACE FUNCTION public.merge_pending_faith(p_user_id UUID)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_pending DOUBLE PRECISION;
  v_new_faith DOUBLE PRECISION;
BEGIN
  SELECT pending_faith INTO v_pending FROM public.profiles WHERE id = p_user_id;

  IF v_pending IS NULL OR v_pending = 0 THEN
    RETURN (SELECT faith_level FROM public.profiles WHERE id = p_user_id);
  END IF;

  UPDATE public.profiles
  SET faith_level = LEAST(faith_level + pending_faith, 70),
      pending_faith = 0
  WHERE id = p_user_id
  RETURNING faith_level INTO v_new_faith;

  INSERT INTO public.faith_history (user_id, faith_level, recorded_date)
  VALUES (p_user_id, v_new_faith, CURRENT_DATE)
  ON CONFLICT (user_id, recorded_date)
  DO UPDATE SET faith_level = EXCLUDED.faith_level;

  RETURN v_new_faith;
END;
$$;

GRANT EXECUTE ON FUNCTION public.merge_pending_faith(UUID) TO authenticated;

-- 6. Recriar apply_faith_penalty com NUMERIC (aceita decimal)
DROP FUNCTION IF EXISTS public.apply_faith_penalty(UUID, NUMERIC);
DROP FUNCTION IF EXISTS public.apply_faith_penalty(UUID, INTEGER);
CREATE OR REPLACE FUNCTION public.apply_faith_penalty(p_user_id UUID, p_amount NUMERIC)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_faith DOUBLE PRECISION;
  v_pending DOUBLE PRECISION;
  v_new_pending DOUBLE PRECISION;
BEGIN
  SELECT faith_level, pending_faith INTO v_faith, v_pending
  FROM public.profiles WHERE id = p_user_id;

  v_new_pending := COALESCE(v_pending, 0) + p_amount;

  UPDATE public.profiles
  SET pending_faith = v_new_pending
  WHERE id = p_user_id;

  INSERT INTO public.faith_history (user_id, faith_level, recorded_date)
  VALUES (p_user_id, LEAST(GREATEST(v_faith + v_new_pending, 0), 70), CURRENT_DATE)
  ON CONFLICT (user_id, recorded_date)
  DO UPDATE SET faith_level = EXCLUDED.faith_level;
END;
$$;

GRANT EXECUTE ON FUNCTION public.apply_faith_penalty(UUID, NUMERIC) TO authenticated;

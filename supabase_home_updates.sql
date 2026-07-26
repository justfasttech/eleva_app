-- =============================================
-- Ajustes na Home: onboarding, histórico de fé, pending faith
-- =============================================

-- 1. Novas colunas em profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS faith_description TEXT DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pending_faith INT DEFAULT 0;

-- Marcar usuários existentes como já onboarded (para não mostrar onboarding novamente)
UPDATE public.profiles SET onboarding_completed = true WHERE created_at < NOW();

-- 2. Tabela de histórico de fé (para gráfico de linhas)
CREATE TABLE IF NOT EXISTS public.faith_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  faith_level INT NOT NULL CHECK (faith_level >= 0 AND faith_level <= 70),
  recorded_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, recorded_date)
);

ALTER TABLE public.faith_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own faith history"
  ON public.faith_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own faith history"
  ON public.faith_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own faith history"
  ON public.faith_history FOR UPDATE
  USING (auth.uid() = user_id);

CREATE INDEX idx_faith_history_user_date
  ON public.faith_history(user_id, recorded_date DESC);

ALTER PUBLICATION supabase_realtime ADD TABLE public.faith_history;

-- 3. Função para mesclar pending_faith → faith_level (chamada a cada hora cheia)
CREATE OR REPLACE FUNCTION public.merge_pending_faith(p_user_id UUID)
RETURNS INT AS $$
DECLARE
  v_pending INT;
  v_new_faith INT;
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

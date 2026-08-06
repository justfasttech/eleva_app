-- =============================================
-- UPDATE: Palavras de pontuação do diário (admin-managed)
-- =============================================

CREATE TABLE IF NOT EXISTS public.scoring_words (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  word TEXT NOT NULL UNIQUE,
  points INT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.scoring_words ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read scoring words"
  ON public.scoring_words FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins manage scoring words"
  ON public.scoring_words FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true));

ALTER PUBLICATION supabase_realtime ADD TABLE public.scoring_words;

-- Seed: palavras negativas (já existentes no código + novas do usuário)
INSERT INTO public.scoring_words (word, points) VALUES
  ('ódio', -5),
  ('odio', -5),
  ('maldição', -5),
  ('maldicao', -5),
  ('vingança', -5),
  ('vinganca', -5),
  ('suicídio', -5),
  ('suicidio', -5),
  ('desgraça', -5),
  ('desgraca', -5),
  ('depressão', -5),
  ('raiva', -3),
  ('desistir', -3),
  ('fracasso', -3),
  ('inútil', -3),
  ('inutil', -3),
  ('desespero', -3),
  ('amaldiçoar', -3),
  ('amaldicoar', -3),
  ('desmotivado', -3),
  ('doença', -3),
  ('acidente', -3),
  ('desilusão', -3),
  ('medo', -2),
  ('dúvida', -2),
  ('duvida', -2),
  ('solidão', -2),
  ('solidao', -2),
  ('culpa', -2),
  ('ansiedade', -2),
  ('desligado', -2),
  ('choro', -2),
  ('perdido', -2),
  ('engano', -2),
  ('pressentimento', -1),
  ('saudade', -1)
ON CONFLICT (word) DO NOTHING;

-- Seed: palavras positivas (novas do usuário)
INSERT INTO public.scoring_words (word, points) VALUES
  ('milagre', 5),
  ('benção', 3),
  ('alegria', 3),
  ('conquista', 3),
  ('amizade', 3),
  ('saúde', 3),
  ('focado', 2),
  ('energia', 2),
  ('riso', 2),
  ('prazer', 2),
  ('encontro', 2),
  ('sentimento', 1),
  ('emoção', 1),
  ('desejo', 1),
  ('achado', 1),
  ('apareceu', 1),
  ('inesperado', 1)
ON CONFLICT (word) DO NOTHING;

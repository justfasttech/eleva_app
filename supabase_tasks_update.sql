-- Adicionar coluna admin_replied à tabela posts (para filtro de respondidas no admin)
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS admin_replied BOOLEAN DEFAULT false;

-- Função para marcar post como respondido pelo admin (bypassa RLS)
CREATE OR REPLACE FUNCTION public.mark_post_admin_replied(p_post_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.posts SET admin_replied = true WHERE id = p_post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para desmarcar post como respondido (ao remover resposta admin)
CREATE OR REPLACE FUNCTION public.unmark_post_admin_replied(p_post_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.posts SET admin_replied = false WHERE id = p_post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Corrigir posts já respondidos: marcar admin_replied para posts que já têm comentários de admin
UPDATE public.posts p
SET admin_replied = true
WHERE EXISTS (
  SELECT 1 FROM public.post_comments pc
  JOIN public.profiles pr ON pr.id = pc.user_id
  WHERE pc.post_id = p.id AND pr.is_admin = true
);

-- Adicionar política UPDATE para post_comments (permite editar próprio comentário)
CREATE POLICY "Users can update own comments"
  ON public.post_comments FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

-- Garantir trigger de contagem de comentários nos posts
CREATE OR REPLACE FUNCTION public.update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.posts SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_post_comments_count ON public.post_comments;
CREATE TRIGGER trg_post_comments_count
  AFTER INSERT OR DELETE ON public.post_comments
  FOR EACH ROW EXECUTE FUNCTION public.update_post_comments_count();

-- Corrigir contagem de comentários existentes
UPDATE public.posts p
SET comments_count = (
  SELECT COUNT(*) FROM public.post_comments pc WHERE pc.post_id = p.id
);

-- Adicionar coluna frequency à tabela daily_tasks
ALTER TABLE public.daily_tasks ADD COLUMN IF NOT EXISTS frequency TEXT DEFAULT 'daily' CHECK (frequency IN ('daily', 'weekly'));

-- Função RPC para aplicar penalidade de fé (permite valores negativos)
CREATE OR REPLACE FUNCTION public.apply_faith_penalty(p_user_id UUID, p_amount INT)
RETURNS VOID AS $$
DECLARE
  v_faith INT;
  v_pending INT;
  v_new_pending INT;
  v_projected INT;
BEGIN
  SELECT faith_level, pending_faith INTO v_faith, v_pending
  FROM public.profiles WHERE id = p_user_id;

  v_new_pending := v_pending + p_amount;
  v_projected := GREATEST(v_faith + v_new_pending, 0);
  v_projected := LEAST(v_projected, 70);

  UPDATE public.profiles
  SET pending_faith = v_new_pending
  WHERE id = p_user_id;

  INSERT INTO public.faith_history (user_id, faith_level, recorded_date)
  VALUES (p_user_id, v_projected, CURRENT_DATE)
  ON CONFLICT (user_id, recorded_date)
  DO UPDATE SET faith_level = EXCLUDED.faith_level;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

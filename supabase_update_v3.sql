-- ============================================
-- ATUALIZAÇÃO V3: Grupos melhorados
-- Rodar no Supabase Dashboard > SQL Editor
-- ============================================

-- 1. Remover grupos duplicados (manter apenas o mais antigo de cada creator)
DELETE FROM public.groups
WHERE id NOT IN (
  SELECT DISTINCT ON (creator_id) id
  FROM public.groups
  ORDER BY creator_id, created_at ASC
);

-- 1b. Limitar 1 grupo por usuário (constraint UNIQUE no creator_id)
ALTER TABLE public.groups ADD CONSTRAINT groups_one_per_creator UNIQUE (creator_id);

-- 2. Permitir dono deletar o grupo
CREATE POLICY "Creator can delete own group"
  ON public.groups FOR DELETE TO authenticated
  USING (creator_id = auth.uid());

-- 3. Adicionar coluna message em group_join_requests
ALTER TABLE public.group_join_requests
  ADD COLUMN IF NOT EXISTS message TEXT DEFAULT '';

-- 4. Adicionar title, likes_count, comments_count ao group_posts
ALTER TABLE public.group_posts
  ADD COLUMN IF NOT EXISTS title TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS likes_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS comments_count INT NOT NULL DEFAULT 0;

-- 4. Tabela de likes para posts de grupo
CREATE TABLE IF NOT EXISTS public.group_post_likes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES public.group_posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(post_id, user_id)
);
ALTER TABLE public.group_post_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can read group post likes"
  ON public.group_post_likes FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated can like"
  ON public.group_post_likes FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike own"
  ON public.group_post_likes FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

ALTER PUBLICATION supabase_realtime ADD TABLE public.group_post_likes;

-- 5. Trigger para atualizar likes_count
CREATE OR REPLACE FUNCTION update_group_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.group_posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.group_posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_group_post_likes_count
  AFTER INSERT OR DELETE ON public.group_post_likes
  FOR EACH ROW EXECUTE FUNCTION update_group_post_likes_count();

-- 6. Tabela de comentários para posts de grupo
CREATE TABLE IF NOT EXISTS public.group_post_comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES public.group_posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  author_name TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_group_post_comments_post ON public.group_post_comments (post_id, created_at);
ALTER TABLE public.group_post_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can read group post comments"
  ON public.group_post_comments FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated can comment"
  ON public.group_post_comments FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
  ON public.group_post_comments FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

ALTER PUBLICATION supabase_realtime ADD TABLE public.group_post_comments;

-- 7. Trigger para atualizar comments_count
CREATE OR REPLACE FUNCTION update_group_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.group_posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.group_posts SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_group_post_comments_count
  AFTER INSERT OR DELETE ON public.group_post_comments
  FOR EACH ROW EXECUTE FUNCTION update_group_post_comments_count();

-- =============================================
-- ATUALIZAÇÃO V2: Rodar no Supabase Dashboard → SQL Editor
-- =============================================

-- 0.1 Corrigir RLS do profiles (permitir leitura entre usuários)
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
CREATE POLICY "Authenticated can read profiles"
  ON public.profiles FOR SELECT TO authenticated USING (true);

-- 0.2 Corrigir members_count padrão dos grupos (era 1, trigger somava +1 = 2)
ALTER TABLE public.groups ALTER COLUMN members_count SET DEFAULT 0;

-- 0.3 Adicionar target_user_id para notificações per-user
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS target_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_type_check
  CHECK (type IN ('admin', 'daily_verse', 'friend_request', 'friend_accepted', 'forum_answer', 'unread_messages'));

DROP POLICY IF EXISTS "Authenticated can read notifications" ON public.notifications;
CREATE POLICY "Users can read relevant notifications"
  ON public.notifications FOR SELECT TO authenticated
  USING (target_user_id IS NULL OR target_user_id = auth.uid());

CREATE POLICY "Users can create targeted notifications"
  ON public.notifications FOR INSERT TO authenticated
  WITH CHECK (target_user_id IS NOT NULL);

-- 0.4 Tabela group_join_requests
CREATE TABLE IF NOT EXISTS public.group_join_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  user_name TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(group_id, user_id)
);
ALTER TABLE public.group_join_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Group creators can see requests" ON public.group_join_requests FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM public.groups g WHERE g.id = group_id AND g.creator_id = auth.uid())
  OR auth.uid() = user_id
);
CREATE POLICY "Users can request to join" ON public.group_join_requests FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Group creators can update requests" ON public.group_join_requests FOR UPDATE TO authenticated USING (
  EXISTS (SELECT 1 FROM public.groups g WHERE g.id = group_id AND g.creator_id = auth.uid())
);

ALTER PUBLICATION supabase_realtime ADD TABLE public.group_join_requests;

-- 0.5 Tabela group_posts
CREATE TABLE IF NOT EXISTS public.group_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  author_name TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_group_posts_group ON public.group_posts (group_id, created_at DESC);
ALTER TABLE public.group_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can read group posts" ON public.group_posts FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = group_posts.group_id AND gm.user_id = auth.uid())
);
CREATE POLICY "Members can create posts" ON public.group_posts FOR INSERT TO authenticated WITH CHECK (
  EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = group_posts.group_id AND gm.user_id = auth.uid())
);
CREATE POLICY "Creators can delete any post" ON public.group_posts FOR DELETE TO authenticated USING (
  auth.uid() = user_id
  OR EXISTS (SELECT 1 FROM public.groups g WHERE g.id = group_id AND g.creator_id = auth.uid())
);

ALTER PUBLICATION supabase_realtime ADD TABLE public.group_posts;

-- 0.6 Política UPDATE em notification_reads (faltava, causava erro no upsert)
CREATE POLICY "Users can update own reads"
  ON public.notification_reads FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

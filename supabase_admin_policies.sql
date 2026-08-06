-- =============================================
-- Policies de admin para posts e group_posts
-- Execute no SQL Editor do Supabase
-- =============================================

-- 1. Admin pode ver TODOS os posts de grupo (resolve posts "sumidos")
CREATE POLICY "Admins can read all group posts"
  ON public.group_posts FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.is_admin = true)
  );

-- 2. Admin pode deletar QUALQUER post de grupo
CREATE POLICY "Admins can delete group posts"
  ON public.group_posts FOR DELETE TO authenticated USING (
    EXISTS (SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.is_admin = true)
  );

-- 3. Admin pode deletar QUALQUER post do fórum
CREATE POLICY "Admins can delete posts"
  ON public.posts FOR DELETE TO authenticated USING (
    EXISTS (SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.is_admin = true)
  );

-- 4. Admin pode deletar QUALQUER comentário de post
CREATE POLICY "Admins can delete post comments"
  ON public.post_comments FOR DELETE TO authenticated USING (
    EXISTS (SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.is_admin = true)
  );

-- 5. Admin pode deletar QUALQUER comentário de grupo
CREATE POLICY "Admins can delete group post comments"
  ON public.group_post_comments FOR DELETE TO authenticated USING (
    EXISTS (SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.is_admin = true)
  );

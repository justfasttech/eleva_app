-- =============================================
-- UPDATE: Adicionar is_question nos posts
-- =============================================

ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS is_question BOOLEAN DEFAULT false;
ALTER TABLE public.group_posts ADD COLUMN IF NOT EXISTS is_question BOOLEAN DEFAULT false;

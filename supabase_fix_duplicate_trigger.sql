-- =============================================
-- FIX: Remover trigger duplicada em post_comments
-- Causa: on_post_comment_change e trg_post_comments_count
-- ambas chamam update_post_comments_count(), duplicando o incremento
-- =============================================

DROP TRIGGER IF EXISTS on_post_comment_change ON public.post_comments;

-- Recalcular contagens existentes
UPDATE public.posts SET comments_count = (
  SELECT COUNT(*) FROM public.post_comments WHERE post_id = posts.id
);

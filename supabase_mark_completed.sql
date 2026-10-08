-- RPC para marcar conteúdo como concluído
-- Necessário porque a tabela user_content_unlocks não tem policy de UPDATE no RLS
CREATE OR REPLACE FUNCTION public.mark_content_completed(p_user_id UUID, p_content_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.user_content_unlocks
  SET completed_at = NOW()
  WHERE user_id = p_user_id
    AND content_id = p_content_id
    AND completed_at IS NULL;

  RETURN FOUND;
END;
$$;

GRANT EXECUTE ON FUNCTION public.mark_content_completed(UUID, UUID) TO authenticated;

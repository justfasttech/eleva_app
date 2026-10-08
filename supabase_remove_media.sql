-- ============================================================
-- Remover todos os áudios e vídeos dos conteúdos
-- Executar no SQL Editor do Supabase
-- ============================================================

-- 1. Limpar campos de mídia nas tabelas de conteúdo
UPDATE public.spiritual_readings SET audio_url = NULL WHERE audio_url IS NOT NULL;
UPDATE public.prayers SET audio_url = NULL, video_url = NULL WHERE audio_url IS NOT NULL OR video_url IS NOT NULL;
UPDATE public.meditations SET audio_url = NULL, video_url = NULL WHERE audio_url IS NOT NULL OR video_url IS NOT NULL;
UPDATE public.tree_messages SET audio_url = NULL WHERE audio_url IS NOT NULL;

-- 2. Remover arquivos dos buckets via Storage API (função interna do Supabase)
-- Para cada bucket, listar e deletar os objetos
DO $$
DECLARE
  bucket TEXT;
  obj RECORD;
BEGIN
  FOREACH bucket IN ARRAY ARRAY['reading-audio', 'prayer-audio', 'prayer-video', 'meditation-video']
  LOOP
    FOR obj IN SELECT id, name FROM storage.objects WHERE bucket_id = bucket
    LOOP
      PERFORM storage.delete_object(bucket, obj.name);
    END LOOP;
  END LOOP;
END;
$$;

-- Se o bloco acima der erro, os buckets podem ser esvaziados manualmente:
-- Supabase Dashboard > Storage > Selecionar cada bucket > Selecionar todos > Delete

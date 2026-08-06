-- =============================================
-- UPDATE: Media attachments + Post themes
-- =============================================

-- 1. Mídia nos posts do fórum
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS video_url TEXT;
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS theme_id UUID;

-- 2. Mídia nos posts de grupos
ALTER TABLE public.group_posts ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE public.group_posts ADD COLUMN IF NOT EXISTS video_url TEXT;

-- 3. Tabela de temas de post
CREATE TABLE IF NOT EXISTS public.post_themes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.post_themes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read themes"
  ON public.post_themes FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins manage themes"
  ON public.post_themes FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true));

-- 4. FK e índice
ALTER TABLE public.posts ADD CONSTRAINT fk_posts_theme
  FOREIGN KEY (theme_id) REFERENCES public.post_themes(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_posts_theme ON public.posts(theme_id);

-- 5. Tema padrão
INSERT INTO public.post_themes (name) VALUES ('Pergunta') ON CONFLICT (name) DO NOTHING;

-- 6. Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.post_themes;

-- 7. Storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('community-media', 'community-media', true)
ON CONFLICT (id) DO NOTHING;

-- 8. Storage policies
CREATE POLICY "Authenticated users can upload community media"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'community-media');

CREATE POLICY "Anyone can view community media"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'community-media');

CREATE POLICY "Users can update own community media"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'community-media' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can delete own community media"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'community-media' AND (storage.foldername(name))[1] = auth.uid()::text);

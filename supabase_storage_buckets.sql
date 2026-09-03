-- ============================================
-- Storage buckets e policies para todos os buckets do app
-- Buckets: reading-audio, prayer-audio, prayer-video, meditation-video
-- (meditation-audio e community-media ja possuem policies)
-- Usa DROP IF EXISTS para evitar conflito com policies existentes
-- ============================================

-- =====================
-- 1. reading-audio
-- =====================
INSERT INTO storage.buckets (id, name, public)
VALUES ('reading-audio', 'reading-audio', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public can read reading audio" ON storage.objects;
CREATE POLICY "Public can read reading audio"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'reading-audio');

DROP POLICY IF EXISTS "Admins can upload reading audio" ON storage.objects;
CREATE POLICY "Admins can upload reading audio"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'reading-audio'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

DROP POLICY IF EXISTS "Admins can update reading audio" ON storage.objects;
CREATE POLICY "Admins can update reading audio"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'reading-audio'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

DROP POLICY IF EXISTS "Admins can delete reading audio" ON storage.objects;
CREATE POLICY "Admins can delete reading audio"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'reading-audio'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

-- =====================
-- 2. prayer-audio
-- =====================
INSERT INTO storage.buckets (id, name, public)
VALUES ('prayer-audio', 'prayer-audio', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public can read prayer audio" ON storage.objects;
CREATE POLICY "Public can read prayer audio"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'prayer-audio');

DROP POLICY IF EXISTS "Admins can upload prayer audio" ON storage.objects;
CREATE POLICY "Admins can upload prayer audio"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'prayer-audio'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

DROP POLICY IF EXISTS "Admins can update prayer audio" ON storage.objects;
CREATE POLICY "Admins can update prayer audio"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'prayer-audio'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

DROP POLICY IF EXISTS "Admins can delete prayer audio" ON storage.objects;
CREATE POLICY "Admins can delete prayer audio"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'prayer-audio'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

-- =====================
-- 3. prayer-video
-- =====================
INSERT INTO storage.buckets (id, name, public)
VALUES ('prayer-video', 'prayer-video', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public can read prayer video" ON storage.objects;
CREATE POLICY "Public can read prayer video"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'prayer-video');

DROP POLICY IF EXISTS "Admins can upload prayer video" ON storage.objects;
CREATE POLICY "Admins can upload prayer video"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'prayer-video'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

DROP POLICY IF EXISTS "Admins can update prayer video" ON storage.objects;
CREATE POLICY "Admins can update prayer video"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'prayer-video'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

DROP POLICY IF EXISTS "Admins can delete prayer video" ON storage.objects;
CREATE POLICY "Admins can delete prayer video"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'prayer-video'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

-- =====================
-- 4. meditation-video
-- =====================
INSERT INTO storage.buckets (id, name, public)
VALUES ('meditation-video', 'meditation-video', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public can read meditation video" ON storage.objects;
CREATE POLICY "Public can read meditation video"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'meditation-video');

DROP POLICY IF EXISTS "Admins can upload meditation video" ON storage.objects;
CREATE POLICY "Admins can upload meditation video"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'meditation-video'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

DROP POLICY IF EXISTS "Admins can update meditation video" ON storage.objects;
CREATE POLICY "Admins can update meditation video"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'meditation-video'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

DROP POLICY IF EXISTS "Admins can delete meditation video" ON storage.objects;
CREATE POLICY "Admins can delete meditation video"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'meditation-video'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

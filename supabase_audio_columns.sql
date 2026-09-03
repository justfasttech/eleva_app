-- ============================================
-- ADD AUDIO/VIDEO COLUMNS TO CONTENT TABLES
-- ============================================

-- Spiritual Readings: add audio support
ALTER TABLE spiritual_readings
  ADD COLUMN IF NOT EXISTS audio_url TEXT,
  ADD COLUMN IF NOT EXISTS audio_file_name TEXT;

-- Prayers: add audio + video support
ALTER TABLE prayers
  ADD COLUMN IF NOT EXISTS audio_url TEXT,
  ADD COLUMN IF NOT EXISTS audio_file_name TEXT,
  ADD COLUMN IF NOT EXISTS video_url TEXT,
  ADD COLUMN IF NOT EXISTS video_file_name TEXT;

-- Meditations: add video support (audio columns already exist)
ALTER TABLE meditations
  ADD COLUMN IF NOT EXISTS video_url TEXT,
  ADD COLUMN IF NOT EXISTS video_file_name TEXT;

-- Migração: adicionar pontuação por pergunta no quiz
-- Executar no SQL Editor do Supabase

ALTER TABLE quiz_questions ADD COLUMN IF NOT EXISTS points_correct REAL NOT NULL DEFAULT 1.0;
ALTER TABLE quiz_questions ADD COLUMN IF NOT EXISTS points_wrong REAL NOT NULL DEFAULT 0.0;

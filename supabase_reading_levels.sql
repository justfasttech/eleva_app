-- Adicionar coluna level à tabela spiritual_readings
ALTER TABLE spiritual_readings
  ADD COLUMN level INT NOT NULL DEFAULT 1
  CHECK (level >= 1 AND level <= 7);

-- Todas as leituras existentes ficam nível 1 (acessíveis a todos)
-- O admin pode ajustar manualmente pelo formulário

-- Habilitar realtime para tabelas que usam .stream() no app
ALTER PUBLICATION supabase_realtime ADD TABLE quizzes;
ALTER PUBLICATION supabase_realtime ADD TABLE quiz_questions;

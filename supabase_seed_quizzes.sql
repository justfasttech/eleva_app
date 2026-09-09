DO $$
DECLARE
  v_theme_fe UUID;
  v_theme_amor UUID;
  v_theme_esperanca UUID;
  v_q1 UUID;
  v_q2 UUID;
  v_q3 UUID;
BEGIN
  SELECT id INTO v_theme_fe FROM content_themes WHERE name = 'Fe';
  SELECT id INTO v_theme_amor FROM content_themes WHERE name = 'Amor';
  SELECT id INTO v_theme_esperanca FROM content_themes WHERE name = 'Esperanca';

  DELETE FROM quiz_questions;
  DELETE FROM quiz_attempts;
  DELETE FROM quizzes;

  INSERT INTO quizzes (id, title, theme_id, is_published)
  VALUES (gen_random_uuid(), 'Fundamentos da Fé', v_theme_fe, true)
  RETURNING id INTO v_q1;

  INSERT INTO quiz_questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_option, order_index, faith_points_correct, faith_points_wrong) VALUES
    (v_q1, 'O que significa ter fé segundo Hebreus 11:1?', 'Acreditar apenas no que se vê', 'A certeza daquilo que esperamos e a prova das coisas que não vemos', 'Seguir rituais religiosos', 'Nunca questionar nada', 'b', 0, 2.0, -0.5),
    (v_q1, 'Qual personagem bíblico é conhecido como o pai da fé?', 'Moisés', 'Davi', 'Abraão', 'Paulo', 'c', 1, 1.5, -0.5),
    (v_q1, 'Segundo Tiago 2:26, a fé sem obras é:', 'Suficiente', 'Morta', 'Opcional', 'Perfeita', 'b', 2, 2.0, -1.0),
    (v_q1, 'Jesus disse que com fé do tamanho de um grão de:', 'Trigo', 'Areia', 'Mostarda', 'Feijão', 'c', 3, 1.5, -0.5);

  INSERT INTO quizzes (id, title, theme_id, is_published)
  VALUES (gen_random_uuid(), 'O Amor na Bíblia', v_theme_amor, true)
  RETURNING id INTO v_q2;

  INSERT INTO quiz_questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_option, order_index, faith_points_correct, faith_points_wrong) VALUES
    (v_q2, 'Em qual livro está o famoso capítulo sobre o amor? (cap. 13)', 'Romanos', 'Gálatas', '1 Coríntios', 'Efésios', 'c', 0, 2.0, -0.5),
    (v_q2, 'Segundo 1 João 4:8, "Deus é ___":', 'Justiça', 'Amor', 'Poder', 'Sabedoria', 'b', 1, 2.5, -1.0),
    (v_q2, 'Qual o maior mandamento segundo Jesus?', 'Não roubar', 'Guardar o sábado', 'Amar a Deus sobre todas as coisas', 'Não mentir', 'c', 2, 2.0, -0.5),
    (v_q2, '"O amor é paciente, o amor é ___" (1 Cor 13:4):', 'Forte', 'Bondoso', 'Silencioso', 'Eterno', 'b', 3, 1.5, -0.5),
    (v_q2, 'Jesus demonstrou o maior amor ao:', 'Curar os doentes', 'Multiplicar os pães', 'Dar sua vida na cruz', 'Andar sobre as águas', 'c', 4, 3.0, -1.0);

  INSERT INTO quizzes (id, title, theme_id, is_published)
  VALUES (gen_random_uuid(), 'Esperança e Promessas', v_theme_esperanca, true)
  RETURNING id INTO v_q3;

  INSERT INTO quiz_questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_option, order_index, faith_points_correct, faith_points_wrong) VALUES
    (v_q3, 'Em Jeremias 29:11, Deus diz que tem planos de:', 'Punição e correção', 'Paz e esperança', 'Riqueza e poder', 'Solidão e reflexão', 'b', 0, 2.0, -0.5),
    (v_q3, 'Qual símbolo Deus usou como aliança de esperança após o dilúvio?', 'Uma estrela', 'Uma pomba', 'O arco-íris', 'Uma oliveira', 'c', 1, 1.5, -0.5),
    (v_q3, '"Aqueles que esperam no Senhor renovam suas ___" (Isaías 40:31):', 'Riquezas', 'Forças', 'Famílias', 'Terras', 'b', 2, 2.0, -1.0),
    (v_q3, 'Romanos 15:13 chama Deus de:', 'Deus da vingança', 'Deus da esperança', 'Deus do silêncio', 'Deus da guerra', 'b', 3, 2.5, -0.5);
END;
$$;

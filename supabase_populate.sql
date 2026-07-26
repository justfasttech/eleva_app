-- ============================================
-- POPULAR APP ELEVA COM DADOS DE TESTE
-- Rodar no Supabase Dashboard > SQL Editor
-- ============================================

-- 1. Limpar dados existentes
DELETE FROM public.group_post_comments;
DELETE FROM public.group_post_likes;
DELETE FROM public.group_posts;
DELETE FROM public.group_join_requests;
DELETE FROM public.group_members;
DELETE FROM public.groups;
DELETE FROM public.messages;
DELETE FROM public.conversations;
DELETE FROM public.post_comments;
DELETE FROM public.post_likes;
DELETE FROM public.posts;
DELETE FROM public.daily_tasks;
DELETE FROM public.daily_verses;
DELETE FROM public.spiritual_readings;
DELETE FROM public.friend_requests;

-- Limpar perfis e users de teste por ID (mantém o usuário real)
DELETE FROM public.profiles WHERE id IN (
  'aaaa1111-1111-1111-1111-111111111111',
  'bbbb2222-2222-2222-2222-222222222222',
  'cccc3333-3333-3333-3333-333333333333',
  'dddd4444-4444-4444-4444-444444444444',
  'eeee5555-5555-5555-5555-555555555555'
);
DELETE FROM auth.identities WHERE user_id IN (
  'aaaa1111-1111-1111-1111-111111111111',
  'bbbb2222-2222-2222-2222-222222222222',
  'cccc3333-3333-3333-3333-333333333333',
  'dddd4444-4444-4444-4444-444444444444',
  'eeee5555-5555-5555-5555-555555555555'
);
DELETE FROM auth.users WHERE id IN (
  'aaaa1111-1111-1111-1111-111111111111',
  'bbbb2222-2222-2222-2222-222222222222',
  'cccc3333-3333-3333-3333-333333333333',
  'dddd4444-4444-4444-4444-444444444444',
  'eeee5555-5555-5555-5555-555555555555'
);

-- ============================================
-- 2. Criar 5 usuários de teste
-- ============================================
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, confirmation_token, recovery_token, raw_app_meta_data, raw_user_meta_data)
VALUES
  ('00000000-0000-0000-0000-000000000000', 'aaaa1111-1111-1111-1111-111111111111', 'authenticated', 'authenticated',
   'maria@elevatest.com', crypt('teste123', gen_salt('bf')), now(), now(), now(), '', '',
   '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Maria Santos"}'::jsonb),

  ('00000000-0000-0000-0000-000000000000', 'bbbb2222-2222-2222-2222-222222222222', 'authenticated', 'authenticated',
   'joao@elevatest.com', crypt('teste123', gen_salt('bf')), now(), now(), now(), '', '',
   '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"João Pedro"}'::jsonb),

  ('00000000-0000-0000-0000-000000000000', 'cccc3333-3333-3333-3333-333333333333', 'authenticated', 'authenticated',
   'ana@elevatest.com', crypt('teste123', gen_salt('bf')), now(), now(), now(), '', '',
   '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Ana Clara"}'::jsonb),

  ('00000000-0000-0000-0000-000000000000', 'dddd4444-4444-4444-4444-444444444444', 'authenticated', 'authenticated',
   'lucas@elevatest.com', crypt('teste123', gen_salt('bf')), now(), now(), now(), '', '',
   '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Lucas Silva"}'::jsonb),

  ('00000000-0000-0000-0000-000000000000', 'eeee5555-5555-5555-5555-555555555555', 'authenticated', 'authenticated',
   'isabela@elevatest.com', crypt('teste123', gen_salt('bf')), now(), now(), now(), '', '',
   '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Isabela Costa"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- Identities (necessário para login funcionar)
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES
  ('aaaa1111-1111-1111-1111-111111111111', 'aaaa1111-1111-1111-1111-111111111111',
   '{"sub":"aaaa1111-1111-1111-1111-111111111111","email":"maria@elevatest.com"}'::jsonb, 'email', 'aaaa1111-1111-1111-1111-111111111111', now(), now(), now()),
  ('bbbb2222-2222-2222-2222-222222222222', 'bbbb2222-2222-2222-2222-222222222222',
   '{"sub":"bbbb2222-2222-2222-2222-222222222222","email":"joao@elevatest.com"}'::jsonb, 'email', 'bbbb2222-2222-2222-2222-222222222222', now(), now(), now()),
  ('cccc3333-3333-3333-3333-333333333333', 'cccc3333-3333-3333-3333-333333333333',
   '{"sub":"cccc3333-3333-3333-3333-333333333333","email":"ana@elevatest.com"}'::jsonb, 'email', 'cccc3333-3333-3333-3333-333333333333', now(), now(), now()),
  ('dddd4444-4444-4444-4444-444444444444', 'dddd4444-4444-4444-4444-444444444444',
   '{"sub":"dddd4444-4444-4444-4444-444444444444","email":"lucas@elevatest.com"}'::jsonb, 'email', 'dddd4444-4444-4444-4444-444444444444', now(), now(), now()),
  ('eeee5555-5555-5555-5555-555555555555', 'eeee5555-5555-5555-5555-555555555555',
   '{"sub":"eeee5555-5555-5555-5555-555555555555","email":"isabela@elevatest.com"}'::jsonb, 'email', 'eeee5555-5555-5555-5555-555555555555', now(), now(), now())
ON CONFLICT (id) DO NOTHING;

-- Profiles dos usuários de teste (ON CONFLICT para re-execução segura)
INSERT INTO public.profiles (id, email, name, faith_level, pending_faith, is_admin, onboarding_completed, faith_description) VALUES
  ('aaaa1111-1111-1111-1111-111111111111', 'maria@elevatest.com', 'Maria Santos', 35, 0, false, true, 'Cristã devota'),
  ('bbbb2222-2222-2222-2222-222222222222', 'joao@elevatest.com', 'João Pedro', 20, 0, false, true, 'Buscando espiritualidade'),
  ('cccc3333-3333-3333-3333-333333333333', 'ana@elevatest.com', 'Ana Clara', 50, 0, false, true, 'Praticante de meditação'),
  ('dddd4444-4444-4444-4444-444444444444', 'lucas@elevatest.com', 'Lucas Silva', 10, 0, false, true, 'Iniciante na fé'),
  ('eeee5555-5555-5555-5555-555555555555', 'isabela@elevatest.com', 'Isabela Costa', 45, 0, false, true, 'Evangelista')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  faith_level = EXCLUDED.faith_level,
  faith_description = EXCLUDED.faith_description;

-- ============================================
-- 3. Amizades aceitas (com o usuário real: 9873069f-...)
--    Obs: troque o UUID abaixo pelo seu se for diferente
-- ============================================
DO $$
DECLARE
  v_real_user UUID;
BEGIN
  -- Pega o primeiro usuário que NÃO é de teste
  SELECT id INTO v_real_user FROM public.profiles
  WHERE email NOT LIKE '%@elevatest.com' AND is_admin = true
  LIMIT 1;

  -- Se não achou admin, pega qualquer um que não é teste
  IF v_real_user IS NULL THEN
    SELECT id INTO v_real_user FROM public.profiles
    WHERE email NOT LIKE '%@elevatest.com'
    LIMIT 1;
  END IF;

  IF v_real_user IS NULL THEN
    RAISE NOTICE 'Nenhum usuário real encontrado, pulando amizades';
    RETURN;
  END IF;

  -- Amizades aceitas com Maria, João e Ana
  INSERT INTO public.friend_requests (from_user_id, to_user_id, from_user_name, status) VALUES
    ('aaaa1111-1111-1111-1111-111111111111', v_real_user, 'Maria Santos', 'accepted'),
    ('bbbb2222-2222-2222-2222-222222222222', v_real_user, 'João Pedro', 'accepted'),
    ('cccc3333-3333-3333-3333-333333333333', v_real_user, 'Ana Clara', 'accepted');

  -- Solicitação pendente do Lucas
  INSERT INTO public.friend_requests (from_user_id, to_user_id, from_user_name, status) VALUES
    ('dddd4444-4444-4444-4444-444444444444', v_real_user, 'Lucas Silva', 'pending');

  -- Conversa com Maria
  INSERT INTO public.conversations (user1_id, user2_id, last_message_text, last_message_at)
  VALUES (LEAST(v_real_user, 'aaaa1111-1111-1111-1111-111111111111'), GREATEST(v_real_user, 'aaaa1111-1111-1111-1111-111111111111'),
          'Que Deus abençoe seu dia!', now() - interval '2 hours');

  INSERT INTO public.messages (conversation_id, sender_id, content, created_at)
  SELECT c.id, 'aaaa1111-1111-1111-1111-111111111111', 'Olá! Como vai sua jornada de fé?', now() - interval '3 hours'
  FROM public.conversations c
  WHERE (c.user1_id = v_real_user OR c.user2_id = v_real_user)
    AND (c.user1_id = 'aaaa1111-1111-1111-1111-111111111111' OR c.user2_id = 'aaaa1111-1111-1111-1111-111111111111')
  LIMIT 1;

  INSERT INTO public.messages (conversation_id, sender_id, content, created_at)
  SELECT c.id, v_real_user, 'Muito bem! Tenho mantido a rotina de oração.', now() - interval '2 hours' - interval '30 minutes'
  FROM public.conversations c
  WHERE (c.user1_id = v_real_user OR c.user2_id = v_real_user)
    AND (c.user1_id = 'aaaa1111-1111-1111-1111-111111111111' OR c.user2_id = 'aaaa1111-1111-1111-1111-111111111111')
  LIMIT 1;

  INSERT INTO public.messages (conversation_id, sender_id, content, created_at)
  SELECT c.id, 'aaaa1111-1111-1111-1111-111111111111', 'Que Deus abençoe seu dia!', now() - interval '2 hours'
  FROM public.conversations c
  WHERE (c.user1_id = v_real_user OR c.user2_id = v_real_user)
    AND (c.user1_id = 'aaaa1111-1111-1111-1111-111111111111' OR c.user2_id = 'aaaa1111-1111-1111-1111-111111111111')
  LIMIT 1;

  -- Conversa com João
  INSERT INTO public.conversations (user1_id, user2_id, last_message_text, last_message_at)
  VALUES (LEAST(v_real_user, 'bbbb2222-2222-2222-2222-222222222222'), GREATEST(v_real_user, 'bbbb2222-2222-2222-2222-222222222222'),
          'Amém! Vamos orar juntos.', now() - interval '1 day');

  INSERT INTO public.messages (conversation_id, sender_id, content, created_at)
  SELECT c.id, 'bbbb2222-2222-2222-2222-222222222222', 'Oi! Vi que você completou muitas tarefas hoje!', now() - interval '1 day' - interval '1 hour'
  FROM public.conversations c
  WHERE (c.user1_id = v_real_user OR c.user2_id = v_real_user)
    AND (c.user1_id = 'bbbb2222-2222-2222-2222-222222222222' OR c.user2_id = 'bbbb2222-2222-2222-2222-222222222222')
  LIMIT 1;

  INSERT INTO public.messages (conversation_id, sender_id, content, created_at)
  SELECT c.id, v_real_user, 'Amém! Vamos orar juntos.', now() - interval '1 day'
  FROM public.conversations c
  WHERE (c.user1_id = v_real_user OR c.user2_id = v_real_user)
    AND (c.user1_id = 'bbbb2222-2222-2222-2222-222222222222' OR c.user2_id = 'bbbb2222-2222-2222-2222-222222222222')
  LIMIT 1;

END $$;

-- ============================================
-- 4. Versículos diários
-- ============================================
INSERT INTO public.daily_verses (message, is_active) VALUES
  ('Ora, a fé é a certeza daquilo que esperamos e a prova das coisas que não vemos. — Hebreus 11:1', true),
  ('Porque Deus tanto amou o mundo que deu o seu Filho Unigênito, para que todo o que nele crer não pereça, mas tenha a vida eterna. — João 3:16', true),
  ('O Senhor é o meu pastor; nada me faltará. — Salmos 23:1', true),
  ('Tudo posso naquele que me fortalece. — Filipenses 4:13', true),
  ('Confie no Senhor de todo o seu coração e não se apoie em seu próprio entendimento. — Provérbios 3:5', true),
  ('Porque eu sei os planos que tenho para vocês, planos de fazê-los prosperar e não de causar dano, planos de dar a vocês esperança e um futuro. — Jeremias 29:11', true),
  ('O Senhor é a minha luz e a minha salvação; de quem terei medo? — Salmos 27:1', true),
  ('Busquem, pois, em primeiro lugar o Reino de Deus e a sua justiça, e todas essas coisas serão acrescentadas a vocês. — Mateus 6:33', true),
  ('Não temas, porque eu sou contigo; não te assombres, porque eu sou teu Deus. — Isaías 41:10', true),
  ('E conhecerão a verdade, e a verdade os libertará. — João 8:32', true);

-- ============================================
-- 5. Tarefas diárias
-- ============================================
INSERT INTO public.daily_tasks (title, faith_points, is_active) VALUES
  ('Oração matinal', 3, true),
  ('Leitura bíblica diária', 5, true),
  ('Meditação de 10 minutos', 4, true),
  ('Gratidão — escreva 3 coisas', 2, true),
  ('Ato de bondade', 3, true),
  ('Reflexão noturna', 2, true),
  ('Jejum digital por 1 hora', 4, true),
  ('Ouvir um louvor', 2, true);

-- ============================================
-- 6. Posts do fórum (por diferentes usuários)
-- ============================================
INSERT INTO public.posts (user_id, author_name, title, body, is_admin, likes_count, comments_count) VALUES
  ('aaaa1111-1111-1111-1111-111111111111', 'Maria Santos', 'Bem-vindos ao Fórum Eleva!',
   'Este é um espaço para compartilhar experiências de fé, fazer perguntas e crescer juntos na espiritualidade. Sejam respeitosos e acolhedores com todos.', false, 3, 1),
  ('bbbb2222-2222-2222-2222-222222222222', 'João Pedro', 'Como manter uma rotina de oração?',
   'Muitas pessoas têm dificuldade em manter uma rotina consistente de oração. Compartilhem suas dicas e experiências! O que funciona para vocês?', false, 5, 2),
  ('cccc3333-3333-3333-3333-333333333333', 'Ana Clara', 'O poder do perdão',
   'Perdoar nem sempre é fácil, mas é libertador. Como vocês lidam com o perdão no dia a dia? Já tiveram experiências transformadoras com o perdão?', false, 2, 1),
  ('eeee5555-5555-5555-5555-555555555555', 'Isabela Costa', 'Versículos que marcaram sua vida',
   'Qual versículo bíblico mais impactou sua jornada de fé? Compartilhe aqui e conte por que ele é especial para você.', false, 4, 1),
  ('dddd4444-4444-4444-4444-444444444444', 'Lucas Silva', 'Lidando com a ansiedade através da fé',
   'A ansiedade é um desafio real. Como a fé tem ajudado vocês a enfrentar momentos de ansiedade? Que práticas espirituais trazem paz?', false, 6, 2);

-- Likes nos posts
INSERT INTO public.post_likes (post_id, user_id)
SELECT p.id, 'bbbb2222-2222-2222-2222-222222222222' FROM public.posts p WHERE p.title = 'Bem-vindos ao Fórum Eleva!' LIMIT 1;
INSERT INTO public.post_likes (post_id, user_id)
SELECT p.id, 'cccc3333-3333-3333-3333-333333333333' FROM public.posts p WHERE p.title = 'Bem-vindos ao Fórum Eleva!' LIMIT 1;
INSERT INTO public.post_likes (post_id, user_id)
SELECT p.id, 'aaaa1111-1111-1111-1111-111111111111' FROM public.posts p WHERE p.title = 'Como manter uma rotina de oração?' LIMIT 1;
INSERT INTO public.post_likes (post_id, user_id)
SELECT p.id, 'eeee5555-5555-5555-5555-555555555555' FROM public.posts p WHERE p.title = 'Lidando com a ansiedade através da fé' LIMIT 1;

-- Comentários nos posts
INSERT INTO public.post_comments (post_id, user_id, author_name, content)
SELECT p.id, 'cccc3333-3333-3333-3333-333333333333', 'Ana Clara', 'Que iniciativa linda! Feliz em fazer parte dessa comunidade.'
FROM public.posts p WHERE p.title = 'Bem-vindos ao Fórum Eleva!' LIMIT 1;

INSERT INTO public.post_comments (post_id, user_id, author_name, content)
SELECT p.id, 'aaaa1111-1111-1111-1111-111111111111', 'Maria Santos', 'Para mim, acordar 15 minutos mais cedo fez toda a diferença. Aquele momento de silêncio antes do dia começar é sagrado.'
FROM public.posts p WHERE p.title = 'Como manter uma rotina de oração?' LIMIT 1;

INSERT INTO public.post_comments (post_id, user_id, author_name, content)
SELECT p.id, 'eeee5555-5555-5555-5555-555555555555', 'Isabela Costa', 'Eu gosto de usar um aplicativo de lembrete para não esquecer. Consistência é a chave!'
FROM public.posts p WHERE p.title = 'Como manter uma rotina de oração?' LIMIT 1;

INSERT INTO public.post_comments (post_id, user_id, author_name, content)
SELECT p.id, 'dddd4444-4444-4444-4444-444444444444', 'Lucas Silva', 'Perdoar é um processo, não um evento. Tenho aprendido a ser paciente comigo mesmo.'
FROM public.posts p WHERE p.title = 'O poder do perdão' LIMIT 1;

INSERT INTO public.post_comments (post_id, user_id, author_name, content)
SELECT p.id, 'aaaa1111-1111-1111-1111-111111111111', 'Maria Santos', 'Salmos 23 sempre me traz paz nos momentos difíceis.'
FROM public.posts p WHERE p.title = 'Versículos que marcaram sua vida' LIMIT 1;

INSERT INTO public.post_comments (post_id, user_id, author_name, content)
SELECT p.id, 'cccc3333-3333-3333-3333-333333333333', 'Ana Clara', 'A meditação me ajudou muito! Filipenses 4:6 é meu versículo âncora contra ansiedade.'
FROM public.posts p WHERE p.title = 'Lidando com a ansiedade através da fé' LIMIT 1;

INSERT INTO public.post_comments (post_id, user_id, author_name, content)
SELECT p.id, 'bbbb2222-2222-2222-2222-222222222222', 'João Pedro', 'Eu pratico respiração consciente e oro ao mesmo tempo. Tem funcionado muito.'
FROM public.posts p WHERE p.title = 'Lidando com a ansiedade através da fé' LIMIT 1;

-- ============================================
-- 7. Grupo criado pela Maria (com membros e posts)
-- ============================================
INSERT INTO public.groups (creator_id, name, description, icon_name, members_count) VALUES
  ('aaaa1111-1111-1111-1111-111111111111', 'Comunidade de Oração', 'Grupo dedicado à oração coletiva e intercessão. Compartilhamos pedidos de oração e louvamos juntos as vitórias.', 'groups_rounded', 3);

-- Membros: Maria (criadora), João e Ana
INSERT INTO public.group_members (group_id, user_id)
SELECT g.id, 'aaaa1111-1111-1111-1111-111111111111' FROM public.groups g WHERE g.name = 'Comunidade de Oração' LIMIT 1;
INSERT INTO public.group_members (group_id, user_id)
SELECT g.id, 'bbbb2222-2222-2222-2222-222222222222' FROM public.groups g WHERE g.name = 'Comunidade de Oração' LIMIT 1;
INSERT INTO public.group_members (group_id, user_id)
SELECT g.id, 'cccc3333-3333-3333-3333-333333333333' FROM public.groups g WHERE g.name = 'Comunidade de Oração' LIMIT 1;

-- Solicitação pendente do Lucas para o grupo
INSERT INTO public.group_join_requests (group_id, user_id, user_name, status, message)
SELECT g.id, 'dddd4444-4444-4444-4444-444444444444', 'Lucas Silva', 'pending', 'Gostaria muito de participar das orações do grupo!'
FROM public.groups g WHERE g.name = 'Comunidade de Oração' LIMIT 1;

-- Posts no grupo (estilo fórum)
INSERT INTO public.group_posts (group_id, user_id, author_name, title, content)
SELECT g.id, 'aaaa1111-1111-1111-1111-111111111111', 'Maria Santos', 'Pedido de oração pela saúde',
  'Peço orações pela minha família que está passando por um momento delicado de saúde. Creio no poder da oração coletiva!'
FROM public.groups g WHERE g.name = 'Comunidade de Oração' LIMIT 1;

INSERT INTO public.group_posts (group_id, user_id, author_name, title, content)
SELECT g.id, 'bbbb2222-2222-2222-2222-222222222222', 'João Pedro', 'Louvor: Oração respondida!',
  'Quero compartilhar que aquele pedido de oração que fiz semana passada foi respondido! Deus é fiel. Obrigado a todos que oraram comigo.'
FROM public.groups g WHERE g.name = 'Comunidade de Oração' LIMIT 1;

INSERT INTO public.group_posts (group_id, user_id, author_name, title, content)
SELECT g.id, 'cccc3333-3333-3333-3333-333333333333', 'Ana Clara', 'Reflexão: A importância da comunidade',
  'Jesus disse: "Onde dois ou três estiverem reunidos em meu nome, ali estou no meio deles." (Mateus 18:20). A comunidade fortalece nossa fé!'
FROM public.groups g WHERE g.name = 'Comunidade de Oração' LIMIT 1;

-- Grupo da Isabela
INSERT INTO public.groups (creator_id, name, description, icon_name, members_count) VALUES
  ('eeee5555-5555-5555-5555-555555555555', 'Estudos Bíblicos', 'Grupo para estudo aprofundado da Bíblia. Toda semana escolhemos um livro ou tema para estudar juntos.', 'menu_book_rounded', 2);

INSERT INTO public.group_members (group_id, user_id)
SELECT g.id, 'eeee5555-5555-5555-5555-555555555555' FROM public.groups g WHERE g.name = 'Estudos Bíblicos' LIMIT 1;
INSERT INTO public.group_members (group_id, user_id)
SELECT g.id, 'aaaa1111-1111-1111-1111-111111111111' FROM public.groups g WHERE g.name = 'Estudos Bíblicos' LIMIT 1;

INSERT INTO public.group_posts (group_id, user_id, author_name, title, content)
SELECT g.id, 'eeee5555-5555-5555-5555-555555555555', 'Isabela Costa', 'Estudo da semana: Gênesis 1-3',
  'Vamos começar pelo início! Esta semana estudaremos a criação e a queda. Leiam os capítulos e compartilhem suas reflexões aqui.'
FROM public.groups g WHERE g.name = 'Estudos Bíblicos' LIMIT 1;

-- ============================================
-- 8. Leituras espirituais
-- ============================================
INSERT INTO public.spiritual_readings (title, reference, author, category, content, faith_points, is_published) VALUES
  ('O Sermão da Montanha', 'Mateus 5-7', 'Jesus Cristo', 'textos',
   'Bem-aventurados os humildes de espírito, pois deles é o Reino dos céus. Bem-aventurados os que choram, pois serão consolados. Bem-aventurados os mansos, pois herdarão a terra. Bem-aventurados os que têm fome e sede de justiça, pois serão satisfeitos. Bem-aventurados os misericordiosos, pois obterão misericórdia. Bem-aventurados os puros de coração, pois verão a Deus. Bem-aventurados os pacificadores, pois serão chamados filhos de Deus.',
   5, true),
  ('A Parábola do Semeador', 'Mateus 13:1-23', 'Jesus Cristo', 'parabolas',
   'Um semeador saiu a semear. Enquanto lançava a semente, parte dela caiu à beira do caminho, e as aves vieram e a comeram. Parte caiu em terreno pedregoso, onde não havia muita terra. Brotou depressa, porque a terra não era profunda. Mas quando o sol apareceu, as plantas se queimaram. Parte caiu entre espinhos, que cresceram e sufocaram as plantas. Parte caiu em boa terra, onde produziu fruto a cem, sessenta e trinta por um.',
   5, true),
  ('O Amor em 1 Coríntios', '1 Coríntios 13', 'Paulo', 'sabedorias',
   'O amor é paciente, o amor é bondoso. Não inveja, não se vangloria, não se orgulha. Não maltrata, não procura seus interesses, não se ira facilmente, não guarda rancor. O amor não se alegra com a injustiça, mas se alegra com a verdade. Tudo sofre, tudo crê, tudo espera, tudo suporta. O amor nunca perece.',
   4, true),
  ('Salmo 91 — Proteção Divina', 'Salmos 91', 'Davi', 'salmos',
   'Aquele que habita no abrigo do Altíssimo e descansa à sombra do Todo-poderoso pode dizer ao Senhor: Tu és o meu refúgio e a minha fortaleza, o meu Deus, em quem confio. Ele o cobrirá com as suas penas, e sob as suas asas você encontrará refúgio; a fidelidade dele será o seu escudo protetor.',
   4, true),
  ('A Fé que Move Montanhas', 'Mateus 17:20', null, 'sabedorias',
   'Jesus respondeu: "Porque a fé que vocês têm é pequena. Eu digo a verdade: Se vocês tiverem fé do tamanho de um grão de mostarda, poderão dizer a este monte: Vá daqui para lá, e ele irá. Nada será impossível para vocês." A fé não é sobre tamanho, mas sobre confiança genuína no poder de Deus.',
   3, true),
  ('Salmo 23 — O Bom Pastor', 'Salmos 23', 'Davi', 'salmos',
   'O Senhor é o meu pastor; nada me faltará. Em verdes pastagens me faz repousar e me conduz a águas tranquilas; restaura-me o vigor. Guia-me pelos caminhos justos, por amor do seu nome. Mesmo que eu ande pelo vale da sombra da morte, não temerei perigo algum, pois tu estás comigo.',
   3, true),
  ('A Parábola do Filho Pródigo', 'Lucas 15:11-32', 'Jesus Cristo', 'parabolas',
   'Um homem tinha dois filhos. O mais novo pediu sua parte da herança e partiu para uma terra distante, onde esbanjou tudo. Quando uma grande fome assolou aquela região, começou a passar necessidade. Caindo em si, voltou para o pai e disse: Pai, pequei contra o céu e contra ti. Mas o pai, vendo-o de longe, encheu-se de compaixão, correu e o abraçou.',
   5, true);

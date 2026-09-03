-- ============================================================
-- Seed de conteudo: Oracoes, Leituras Espirituais e Meditacoes
-- Prerequisito: rodar supabase_content_themes.sql e supabase_seed_themes.sql antes
-- ============================================================

-- =====================
-- ORACOES (15 itens)
-- =====================
INSERT INTO prayers (title, content, theme_id, faith_points, is_published) VALUES

-- Tema: Amor
('Oração do Amor Incondicional',
 'Senhor, ensina-me a amar como Tu amas — sem condições, sem limites, sem esperar nada em troca. Que meu coração se abra para todos os que cruzam meu caminho, reconhecendo em cada rosto um reflexo do Teu amor divino.

Ajuda-me a perdoar aqueles que me feriram, a ser ponte onde há divisão, a ser luz onde há escuridão. Que eu seja instrumento do Teu amor neste mundo.

Amém.',
 '4efc23ff-d8e8-44a8-b935-feee687e611e', 3, true),

('Oração pela Família',
 'Pai celestial, abençoa minha família com Tua graça infinita. Protege cada membro com Teu manto de amor e sabedoria. Que nosso lar seja um reflexo do Teu reino — cheio de paz, compreensão e alegria.

Nos momentos de dificuldade, fortalece nossos laços. Nos momentos de alegria, que saibamos agradecer juntos. Que o amor que nos une seja mais forte que qualquer tempestade.

Guarda nossos filhos, nossos pais, nossos irmãos. Que cada um encontre em Ti o alicerce que sustenta a vida.

Amém.',
 '4efc23ff-d8e8-44a8-b935-feee687e611e', 3, true),

('Oração pela Compaixão',
 'Deus de misericórdia, abre meus olhos para enxergar o sofrimento ao meu redor. Dá-me um coração compassivo que se move pela dor alheia e mãos dispostas a ajudar.

Que eu nunca passe indiferente diante de quem precisa. Que minha presença seja conforto, minha palavra seja esperança, e meu gesto seja amor em ação.

Transforma-me em um canal da Tua compaixão neste mundo que tanto precisa.

Amém.',
 '4efc23ff-d8e8-44a8-b935-feee687e611e', 2, true),

-- Tema: Fe
('Oração da Fé Inabalável',
 'Senhor, fortalece minha fé nos dias de incerteza. Quando o caminho parecer escuro e as respostas demorarem, ajuda-me a confiar no Teu plano perfeito.

Que minha fé não dependa das circunstâncias, mas esteja firmada na Tua fidelidade. Que eu creia mesmo quando não posso ver, que eu confie mesmo quando não posso entender.

Como a semente que germina no escuro da terra, permite que minha fé cresça nas estações de espera.

Amém.',
 'a5adfa9b-f0df-4c0c-8d93-f913a0553233', 4, true),

('Oração de Confiança',
 'Pai, entrego nas Tuas mãos tudo aquilo que não posso controlar. Meus planos, meus medos, meus sonhos — tudo deposito aos Teus pés.

Sei que Tu conheces o fim desde o princípio. Sei que Teus caminhos são mais altos que os meus. Por isso, escolho confiar, mesmo quando a lógica humana diz o contrário.

Que minha confiança em Ti seja minha âncora em meio às tempestades da vida.

Amém.',
 'a5adfa9b-f0df-4c0c-8d93-f913a0553233', 3, true),

('Oração do Crer',
 'Senhor, eu creio — ajuda a minha incredulidade! Nos momentos em que a dúvida bate à porta do meu coração, reafirma em mim a certeza da Tua presença.

Que minha fé seja como a do grão de mostarda — pequena aos olhos do mundo, mas poderosa o suficiente para mover montanhas. Que cada experiência vivida fortaleça minha crença no impossível que se torna possível em Tuas mãos.

Amém.',
 'a5adfa9b-f0df-4c0c-8d93-f913a0553233', 3, true),

-- Tema: Esperanca
('Oração da Esperança',
 'Deus de toda esperança, renova meu ânimo quando o cansaço quiser me derrubar. Lembra-me de que após cada noite escura, um novo amanhecer se levanta.

Que eu seja portador de esperança para os desanimados, luz para os que caminham na sombra, e voz de encorajamento para os que pensam em desistir.

Planta em meu coração a certeza de que o melhor ainda está por vir.

Amém.',
 'd0a87fb8-7622-4e41-a006-f2020bc6b261', 3, true),

('Oração pelo Futuro',
 'Senhor, o futuro pertence a Ti. Mesmo quando não consigo ver o próximo passo, sei que Tu já preparaste o caminho. Livra-me da ansiedade do amanhã e ensina-me a viver plenamente o hoje.

Que cada dia seja uma semente plantada com fé, regada com esperança e colhida com gratidão. Que meu futuro esteja seguro em Tuas mãos amorosas.

Amém.',
 'd0a87fb8-7622-4e41-a006-f2020bc6b261', 2, true),

('Oração da Renovação',
 'Pai, renova todas as coisas em mim. Onde há cansaço, traze vigor. Onde há tristeza, traze alegria. Onde há medo, traze coragem.

Como a primavera que renova a terra após o inverno, renova minha alma, meus sonhos e minha capacidade de acreditar. Que cada novo dia seja uma oportunidade de recomeço.

Faz de mim uma nova criatura, transformada pelo Teu amor e guiada pela Tua luz.

Amém.',
 'd0a87fb8-7622-4e41-a006-f2020bc6b261', 3, true),

-- Tema: Gratidao
('Oração de Agradecimento',
 'Senhor, obrigado por tudo — pelo que vejo e pelo que não vejo, pelo que entendo e pelo que ainda vou compreender. Obrigado pela vida, pela saúde, pelas pessoas que colocaste em meu caminho.

Ensina-me a ter um coração grato em todas as circunstâncias. Que eu nunca me acostume com as Tuas bênçãos ao ponto de esquecê-las.

Que a gratidão seja minha primeira oração ao acordar e meu último pensamento ao dormir.

Amém.',
 '14b98c21-caae-4b28-ab83-41afab0968e1', 3, true),

('Oração pelas Bênçãos',
 'Pai generoso, reconheço que cada bom presente vem de Ti. O ar que respiro, o alimento na mesa, o teto sobre minha cabeça — tudo é fruto da Tua bondade.

Abre meus olhos para enxergar as bênçãos escondidas nos dias comuns. Que eu saiba valorizar o ordinário como extraordinário.

Derrama sobre mim e minha família Tuas bênçãos, e faz de mim uma bênção para os outros.

Amém.',
 '14b98c21-caae-4b28-ab83-41afab0968e1', 2, true),

('Oração de Louvor',
 'Te louvo, Senhor, não pelo que Tu fazes, mas por quem Tu és. Tu és grandioso, maravilhoso, incomparável. Tua fidelidade alcança as nuvens e Teu amor não tem medida.

Que minha vida inteira seja um cântico de louvor a Ti. Nos dias bons e nos dias difíceis, que minha boca declare Tua grandeza.

Todo louvor, toda honra, toda glória — a Ti, agora e para sempre.

Amém.',
 '14b98c21-caae-4b28-ab83-41afab0968e1', 4, true),

-- Tema: Superacao
('Oração da Força',
 'Deus forte, quando minhas forças se esgotarem, sê Tu minha fortaleza. Quando eu pensar que não consigo mais, lembra-me de que posso todas as coisas Naquele que me fortalece.

Não me deixes desistir diante dos obstáculos. Transforma cada dificuldade em degrau, cada queda em aprendizado, cada lágrima em semente de vitória.

Que Tua força se aperfeiçoe na minha fraqueza.

Amém.',
 '65118bff-9f3f-40aa-834a-eb9c1f318e57', 4, true),

('Oração da Perseverança',
 'Senhor, dá-me a graça de perseverar. Quando o caminho for longo e os resultados demorarem, sustenta meus passos com Tua fidelidade.

Que eu corra a corrida com paciência, sem olhar para os lados, com os olhos fixos no alvo. Que cada pequeno progresso seja celebrado e cada tropeço seja superado com Tua ajuda.

Ensina-me que a perseverança produz caráter, e o caráter produz esperança.

Amém.',
 '65118bff-9f3f-40aa-834a-eb9c1f318e57', 3, true),

('Oração da Vitória',
 'Pai, declaro que sou mais que vencedor através do Teu amor. Nenhuma batalha é grande demais quando Tu lutas ao meu lado. Nenhum gigante é forte demais quando Tu és meu escudo.

Celebro antecipadamente a vitória que vem de Ti. Não pela minha capacidade, mas pela Tua graça. Não pela minha sabedoria, mas pelo Teu poder.

A vitória é Tua, Senhor, e eu caminho nela.

Amém.',
 '65118bff-9f3f-40aa-834a-eb9c1f318e57', 5, true);


-- ================================
-- LEITURAS ESPIRITUAIS (15 itens)
-- ================================
INSERT INTO spiritual_readings (title, content, category, author, reference, faith_points, level, theme_id, is_published) VALUES

-- Tema: Amor
('O Amor que Transforma',
 'O amor verdadeiro não é apenas um sentimento — é uma decisão diária de escolher o bem do outro acima do nosso próprio conforto. Ao longo da história, os maiores transformadores do mundo foram movidos não pela força, mas pelo amor.

Quando amamos genuinamente, criamos um campo de força espiritual ao nosso redor que atrai o melhor das pessoas e das situações. O amor é a linguagem universal da alma, compreendida por todos os corações.

Pratique hoje: escolha uma pessoa difícil de amar e faça algo gentil por ela, sem esperar retorno.',
 'textos', 'Reflexões Espirituais', 'Amor ao próximo', 3, 1,
 '4efc23ff-d8e8-44a8-b935-feee687e611e', true),

('A Parábola do Bom Samaritano',
 'Um homem descia de Jerusalém para Jericó e caiu nas mãos de salteadores. Despojaram-no, feriram-no e partiram, deixando-o meio morto. Por acaso, descia pelo mesmo caminho um sacerdote e, vendo-o, passou de largo. Igualmente um levita chegou àquele lugar, viu-o e passou de largo.

Mas um samaritano, que ia de viagem, chegou ao pé dele e, vendo-o, moveu-se de compaixão. Aproximou-se, tratou-lhe as feridas e cuidou dele.

Reflexão: Quem é o nosso próximo? Não é aquele que mora ao lado, mas aquele que precisa de nós neste momento. O amor verdadeiro não pergunta "quem merece?" — ele age.',
 'parabolas', 'Tradição Cristã', 'Lucas 10:30-37', 4, 1,
 '4efc23ff-d8e8-44a8-b935-feee687e611e', true),

('Salmo do Amor Eterno',
 'O Senhor é compassivo e misericordioso, longânimo e assaz benigno.
Não repreende perpetuamente, nem conserva para sempre a Sua ira.
Não nos trata segundo os nossos pecados, nem nos retribui consoante as nossas iniquidades.

Pois quanto o céu se alteia acima da terra, assim é grande a Sua misericórdia para com os que O temem.
Quanto dista o Oriente do Ocidente, assim afasta de nós as nossas transgressões.

Como um pai se compadece de seus filhos, assim o Senhor se compadece dos que O temem.',
 'salmos', 'Livro dos Salmos', 'Salmo 103:8-13', 3, 1,
 '4efc23ff-d8e8-44a8-b935-feee687e611e', true),

-- Tema: Fe
('Caminhar pela Fé',
 'A fé é dar o primeiro passo mesmo quando você não vê a escada inteira. É confiar no arquiteto do universo quando o projeto da sua vida parece incompleto.

Muitos dos maiores avanços espirituais acontecem nos momentos de maior incerteza. É na escuridão que aprendemos a confiar na luz que não podemos ver mas sabemos que existe.

A fé não é a ausência de dúvida — é a coragem de avançar apesar dela. Cada passo de fé fortalece o músculo espiritual que nos sustenta nas tempestades.

Exercício: Hoje, identifique uma área da sua vida onde você precisa exercitar mais fé. Dê um pequeno passo nessa direção.',
 'textos', 'Reflexões Espirituais', 'Caminhada de Fé', 4, 2,
 'a5adfa9b-f0df-4c0c-8d93-f913a0553233', true),

('Versículo da Fé',
 '"Ora, a fé é a certeza daquilo que esperamos e a prova das coisas que não vemos."

Este versículo nos ensina que a fé opera em duas dimensões: certeza e prova. A certeza é a convicção interior de que Deus cumprirá Suas promessas. A prova é a evidência espiritual que transcende os sentidos físicos.

Quando exercitamos a fé, estamos acessando uma realidade que os olhos naturais não conseguem captar, mas que o coração reconhece como verdadeira.

Meditação: Repita este versículo ao longo do dia e observe como ele transforma sua perspectiva sobre as situações que você enfrenta.',
 'versiculos', 'Carta aos Hebreus', 'Hebreus 11:1', 3, 1,
 'a5adfa9b-f0df-4c0c-8d93-f913a0553233', true),

('Sabedoria dos Antigos sobre a Fé',
 '"A fé e a razão são como as duas asas pelas quais o espírito humano se eleva para a contemplação da verdade."

A sabedoria ancestral nos ensina que fé e razão não são inimigas — são aliadas. A razão sem fé se torna fria e vazia. A fé sem razão pode se tornar cega. Juntas, elas nos levam a alturas que nenhuma das duas alcançaria sozinha.

Os grandes sábios de todas as tradições reconheceram que existe algo além do que os olhos podem ver e a mente pode calcular. Esse "algo além" é o território da fé.

Reflexão: Como você equilibra fé e razão na sua vida diária?',
 'sabedorias', 'Sabedoria Universal', 'Tradição Filosófica', 3, 2,
 'a5adfa9b-f0df-4c0c-8d93-f913a0553233', true),

-- Tema: Esperanca
('A Esperança como Âncora',
 'Em tempos de turbulência, a esperança funciona como uma âncora para a alma — firme e segura. Ela não nega a realidade da tempestade, mas nos garante que o barco não será levado pela correnteza.

A esperança é diferente do otimismo superficial. Ela é uma decisão consciente de acreditar que há propósito mesmo no sofrimento, que há luz mesmo na escuridão mais profunda.

Quando cultivamos a esperança, estamos investindo no futuro com a moeda mais valiosa que existe: a confiança de que dias melhores virão.

Prática: Escreva três razões pelas quais você tem esperança hoje, por menores que sejam.',
 'textos', 'Reflexões Espirituais', 'Esperança e Resiliência', 3, 1,
 'd0a87fb8-7622-4e41-a006-f2020bc6b261', true),

('A Parábola do Semeador',
 'Um semeador saiu a semear. Enquanto semeava, algumas sementes caíram à beira do caminho e foram comidas pelas aves. Outras caíram em solo pedregoso, onde brotaram rapidamente mas secaram ao sol por não terem raízes profundas. Outras caíram entre espinhos que as sufocaram. Mas outras caíram em boa terra e produziram fruto — trinta, sessenta e até cem por um.

Reflexão: A esperança é como a semente. Nem sempre ela encontra terreno fértil de imediato, mas quando encontra, multiplica-se abundantemente. Prepare o solo do seu coração com paciência e fé, e a colheita virá no tempo certo.',
 'parabolas', 'Tradição Cristã', 'Mateus 13:3-8', 3, 1,
 'd0a87fb8-7622-4e41-a006-f2020bc6b261', true),

('Salmo da Esperança',
 'Esperei confiantemente pelo Senhor;
Ele se inclinou para mim e ouviu o meu clamor.
Tirou-me de um poço de destruição, de um atoleiro de lama;
colocou os meus pés sobre uma rocha e firmou os meus passos.

Pôs nos meus lábios um novo cântico, um hino de louvor ao nosso Deus.
Muitos verão isso e temerão, e confiarão no Senhor.

Bem-aventurado o homem que põe no Senhor a sua confiança.',
 'salmos', 'Livro dos Salmos', 'Salmo 40:1-4', 4, 1,
 'd0a87fb8-7622-4e41-a006-f2020bc6b261', true),

-- Tema: Gratidao
('O Poder da Gratidão',
 'A gratidão é mais do que educação — é uma força espiritual transformadora. Pesquisas mostram que pessoas gratas são mais felizes, mais saudáveis e mais resilientes. Mas além da ciência, a sabedoria espiritual sempre soube disso.

Quando agradecemos, mudamos nosso foco daquilo que nos falta para aquilo que já temos. Essa mudança de perspectiva é revolucionária — ela transforma a escassez em abundância, a reclamação em celebração.

A gratidão é a memória do coração. Ela nos lembra de que, apesar das dificuldades, somos sustentados, amados e abençoados.

Exercício: Antes de dormir, escreva três coisas pelas quais você é grato hoje.',
 'textos', 'Reflexões Espirituais', 'Gratidão Diária', 3, 1,
 '14b98c21-caae-4b28-ab83-41afab0968e1', true),

('Versículo da Gratidão',
 '"Em tudo dai graças, porque esta é a vontade de Deus em Cristo Jesus para convosco."

Dar graças "em tudo" não significa dar graças "por tudo". Não precisamos ser gratos pelo sofrimento em si, mas podemos ser gratos pela força que encontramos para atravessá-lo.

A gratidão é um ato de fé — é declarar que, mesmo nas circunstâncias mais difíceis, há algo de bom sendo tecido nos bastidores da nossa história.

Desafio: Hoje, encontre um motivo de gratidão em uma situação que normalmente te causaria frustração.',
 'versiculos', 'Carta aos Tessalonicenses', '1 Tessalonicenses 5:18', 3, 1,
 '14b98c21-caae-4b28-ab83-41afab0968e1', true),

('Sabedoria sobre Gratidão',
 '"Não é a alegria que nos faz gratos; é a gratidão que nos faz alegres."

Esta sabedoria inverte nossa lógica habitual. Normalmente pensamos: "Quando eu tiver motivos, serei grato." Mas a verdade é o oposto: quando escolhemos ser gratos, os motivos de alegria se multiplicam.

A gratidão é uma lente que muda tudo o que vemos. O café da manhã simples se torna um banquete. O dia comum se torna uma dádiva. A pessoa ao nosso lado se torna um tesouro.

Pratique a gratidão como um músculo — quanto mais você exercita, mais forte ela fica.',
 'sabedorias', 'Sabedoria Universal', 'Tradição Contemplativa', 2, 1,
 '14b98c21-caae-4b28-ab83-41afab0968e1', true),

-- Tema: Superacao
('Vencendo Gigantes Interiores',
 'Todos nós temos gigantes interiores — medos, inseguranças, traumas, hábitos que parecem impossíveis de vencer. Mas a história nos mostra que os maiores heróis não eram aqueles sem medo, e sim aqueles que agiram apesar dele.

A superação começa com uma decisão: recusar-se a ser definido pelas circunstâncias. Você é mais do que seus fracassos, mais do que seus erros, mais do que suas limitações.

Cada pequena vitória sobre si mesmo constrói o caráter necessário para as grandes batalhas. Não subestime o poder de um passo de cada vez.

Reflexão: Qual gigante interior você precisa enfrentar hoje? Dê o primeiro passo, por menor que seja.',
 'textos', 'Reflexões Espirituais', 'Superação Pessoal', 4, 2,
 '65118bff-9f3f-40aa-834a-eb9c1f318e57', true),

('A Parábola da Águia',
 'Conta-se que um homem encontrou um ovo de águia e o colocou no ninho de uma galinha. A águia nasceu e cresceu pensando que era galinha — ciscava, cacarejava e nunca voava além de poucos metros.

Um dia, olhando para o céu, viu uma ave magnífica planando nas alturas com graça e majestade. "Quem é aquela?" perguntou. "É a águia, a rainha dos céus", respondeu uma galinha. "Mas não pense nisso — nós somos galinhas."

A águia viveu e morreu como galinha, porque foi isso que acreditou ser.

Reflexão: Quantas vezes vivemos abaixo do nosso potencial porque acreditamos nas limitações que outros impuseram sobre nós? Você foi criado para voar.',
 'parabolas', 'Tradição Oral', 'A Águia e a Galinha', 5, 2,
 '65118bff-9f3f-40aa-834a-eb9c1f318e57', true),

('Versículo da Superação',
 '"Tudo posso naquele que me fortalece."

Quatro palavras que mudaram a história de milhões de pessoas. Este versículo não é uma promessa de que tudo será fácil, mas uma declaração de que nenhum desafio será grande demais quando estamos conectados à fonte de toda força.

"Tudo posso" não é arrogância humana — é confiança na força divina que opera em nós. É reconhecer que nossas limitações não são o fim da história, porque há um poder maior disponível.

Meditação: Quando sentir que não consegue mais, repita estas palavras e permita que a força que vem do alto renove suas energias.',
 'versiculos', 'Carta aos Filipenses', 'Filipenses 4:13', 4, 2,
 '65118bff-9f3f-40aa-834a-eb9c1f318e57', true);


-- ==========================
-- MEDITACOES (10 itens)
-- ==========================
INSERT INTO meditations (title, description, duration_minutes, type, faith_points, theme_id, is_published) VALUES

-- Tema: Amor
('Meditação do Amor Universal',
 'Uma meditação guiada para expandir seu coração e cultivar amor incondicional por si mesmo e pelos outros. Respire profundamente e permita que o amor divino preencha cada célula do seu ser.',
 10, 'guiada', 3,
 '4efc23ff-d8e8-44a8-b935-feee687e611e', true),

('Ambiente de Paz e Amor',
 'Sons suaves da natureza combinados com frequências harmônicas para criar um ambiente de paz interior. Ideal para momentos de oração, reflexão ou simplesmente para acalmar o coração.',
 15, 'ambiente', 2,
 '4efc23ff-d8e8-44a8-b935-feee687e611e', true),

-- Tema: Fe
('Meditação da Fé Profunda',
 'Uma jornada interior para fortalecer sua conexão espiritual. Através de respiração consciente e visualização, esta meditação guiada ajuda a aprofundar sua fé e confiança no plano divino.',
 12, 'guiada', 4,
 'a5adfa9b-f0df-4c0c-8d93-f913a0553233', true),

('Sons da Contemplação',
 'Ambiente sonoro contemplativo com sinos tibetanos e sons da natureza. Perfeito para momentos de meditação silenciosa e conexão com o sagrado interior.',
 20, 'ambiente', 2,
 'a5adfa9b-f0df-4c0c-8d93-f913a0553233', true),

-- Tema: Esperanca
('Meditação da Renovação',
 'Uma meditação guiada focada em renovar suas esperanças e sonhos. Visualize a luz divina dissipando toda escuridão e trazendo clareza sobre o futuro que Deus preparou para você.',
 10, 'guiada', 3,
 'd0a87fb8-7622-4e41-a006-f2020bc6b261', true),

('Amanhecer Espiritual',
 'Sons do amanhecer — pássaros cantando, brisa suave, água correndo — para criar um ambiente de renovação e esperança. Cada novo dia é uma nova oportunidade.',
 15, 'ambiente', 2,
 'd0a87fb8-7622-4e41-a006-f2020bc6b261', true),

-- Tema: Gratidao
('Meditação da Gratidão',
 'Uma prática guiada para cultivar um coração grato. Percorra mentalmente as bênçãos do seu dia, da sua semana, da sua vida. Sinta a gratidão transformar sua perspectiva e elevar seu espírito.',
 8, 'guiada', 3,
 '14b98c21-caae-4b28-ab83-41afab0968e1', true),

('Harmonia e Bênçãos',
 'Frequências harmônicas suaves para acompanhar seus momentos de gratidão e louvor. Deixe-se envolver pela atmosfera de paz e reconhecimento.',
 12, 'ambiente', 2,
 '14b98c21-caae-4b28-ab83-41afab0968e1', true),

-- Tema: Superacao
('Meditação do Guerreiro Espiritual',
 'Uma meditação guiada para despertar a força interior que existe em você. Conecte-se com a coragem divina, supere seus medos e encontre a determinação para enfrentar qualquer desafio.',
 15, 'guiada', 4,
 '65118bff-9f3f-40aa-834a-eb9c1f318e57', true),

('Força Interior',
 'Ambiente sonoro energizante com tambores suaves e sons da natureza para momentos em que você precisa de força e motivação espiritual.',
 10, 'ambiente', 3,
 '65118bff-9f3f-40aa-834a-eb9c1f318e57', true);

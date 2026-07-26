import 'dart:math';

const dailyMessages = [
  (
    text: '"A fé é a certeza daquilo que esperamos e a prova das coisas que não vemos."',
    source: 'Hebreus 11:1',
  ),
  (
    text: '"Tudo posso naquele que me fortalece."',
    source: 'Filipenses 4:13',
  ),
  (
    text: '"O Senhor é o meu pastor; nada me faltará."',
    source: 'Salmos 23:1',
  ),
  (
    text: '"Entrega o teu caminho ao Senhor; confia nele, e ele tudo fará."',
    source: 'Salmos 37:5',
  ),
  (
    text: '"Porque Deus amou o mundo de tal maneira que deu o seu Filho unigênito."',
    source: 'João 3:16',
  ),
  (
    text: '"Não temas, porque eu sou contigo; não te assombres, porque eu sou o teu Deus."',
    source: 'Isaías 41:10',
  ),
  (
    text: '"Buscai primeiro o Reino de Deus, e a sua justiça, e todas estas coisas vos serão acrescentadas."',
    source: 'Mateus 6:33',
  ),
  (
    text: '"Eu sou o caminho, a verdade e a vida."',
    source: 'João 14:6',
  ),
  (
    text: '"Alegrem-se na esperança, sejam pacientes na tribulação, perseverem na oração."',
    source: 'Romanos 12:12',
  ),
  (
    text: '"Pois onde estiver o vosso tesouro, aí estará também o vosso coração."',
    source: 'Mateus 6:21',
  ),
];

({String text, String source}) getTodayMessage() {
  final now = DateTime.now();
  final seed = now.year * 10000 + now.month * 100 + now.day;
  final index = Random(seed).nextInt(dailyMessages.length);
  return dailyMessages[index];
}

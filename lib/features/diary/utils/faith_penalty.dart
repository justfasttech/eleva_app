const _severeWords = ['ódio', 'odio', 'maldição', 'maldicao', 'vingança', 'vinganca', 'suicídio', 'suicidio', 'desgraça', 'desgraca'];
const _moderateWords = ['raiva', 'desistir', 'fracasso', 'inútil', 'inutil', 'desespero', 'amaldiçoar', 'amaldicoar'];
const _mildWords = ['medo', 'dúvida', 'duvida', 'solidão', 'solidao', 'culpa', 'ansiedade'];

int calculateContentPenalty(String content) {
  final lower = content.toLowerCase();

  for (final word in _severeWords) {
    if (lower.contains(word)) return -5;
  }
  for (final word in _moderateWords) {
    if (lower.contains(word)) return -3;
  }
  for (final word in _mildWords) {
    if (lower.contains(word)) return -2;
  }

  return 0;
}

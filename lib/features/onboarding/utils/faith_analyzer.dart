int analyzeFaithLevel(String text) {
  if (text.trim().isEmpty) return 5;

  final lower = text.toLowerCase();
  int score = 5;

  const beginner = [
    'curioso', 'curiosa', 'comecar', 'começar', 'inicio', 'início',
    'aprender', 'conhecer', 'novo', 'nova', 'primeira vez', 'iniciante',
  ];
  const intermediate = [
    'oro', 'oração', 'oracao', 'igreja', 'biblia', 'bíblia', 'leitura',
    'devocional', 'culto', 'missa', 'fé', 'fe', 'deus', 'jesus', 'cristo',
    'espírito', 'espirito', 'senhor', 'evangelho', 'palavra',
  ];
  const advanced = [
    'ministerio', 'ministério', 'servir', 'liderança', 'lideranca',
    'discipulado', 'evangelizar', 'missão', 'missao', 'comunidade',
    'voluntário', 'voluntario', 'louvor', 'adoração', 'adoracao',
  ];
  const deep = [
    'jejum', 'intercessão', 'intercessao', 'profundo', 'profunda',
    'transformação', 'transformacao', 'chamado', 'propósito', 'proposito',
    'intimidade com deus', 'vida devocional', 'consagração', 'consagracao',
  ];

  for (final kw in beginner) {
    if (lower.contains(kw)) score += 2;
  }
  for (final kw in intermediate) {
    if (lower.contains(kw)) score += 3;
  }
  for (final kw in advanced) {
    if (lower.contains(kw)) score += 4;
  }
  for (final kw in deep) {
    if (lower.contains(kw)) score += 5;
  }

  if (text.length > 100) score += 3;
  if (text.length > 300) score += 5;

  return score.clamp(5, 50);
}

import '../models/scoring_word.dart';

int calculateContentScore(String content, List<ScoringWord> words) {
  final lower = content.toLowerCase();
  int total = 0;

  for (final sw in words) {
    if (lower.contains(sw.word.toLowerCase())) {
      total += sw.points;
    }
  }

  return total;
}

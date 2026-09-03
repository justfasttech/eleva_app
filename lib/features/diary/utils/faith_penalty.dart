import '../models/scoring_word.dart';

double calculateContentScore(String content, List<ScoringWord> words) {
  final lower = content.toLowerCase();
  double total = 0;

  for (final sw in words) {
    if (lower.contains(sw.word.toLowerCase())) {
      total += sw.points;
    }
  }

  return total;
}

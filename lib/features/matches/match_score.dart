import '../../models/profile.dart';

class MatchResult {
  final int score;
  final List<String> reasons;
  MatchResult(this.score, this.reasons);
}

MatchResult calcMatch(Profile me, Profile other) {
  if (me.city.toLowerCase() != other.city.toLowerCase()) {
    return MatchResult(0, ['Şehir uyuşmuyor']);
  }

  int score = 0;
  final reasons = <String>[];

  // Budget
  final overlap =
      me.budgetMin <= other.budgetMax && me.budgetMax >= other.budgetMin;
  if (overlap) {
    score += 40;
    reasons.add('Bütçe uyumlu');
  }

  // Smoker
  if (me.smokerOk == other.smokerOk) {
    score += 20;
    reasons.add('Sigara tercihi benzer');
  }

  // Cleanliness
  score += (20 - (me.cleanliness - other.cleanliness).abs() * 5).clamp(0, 20);

  // Quietness
  score += (10 - (me.quietness - other.quietness).abs() * 3).clamp(0, 10);

  // Sleep
  score += (10 - (me.sleepFrom - other.sleepFrom).abs()).clamp(0, 10);

  return MatchResult(score, reasons.take(3).toList());
}

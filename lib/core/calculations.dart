/// Pure, offline math used across the app. No Flutter imports.
library;

enum Sex { male, female }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

enum GoalType { lose, maintain, gain, fitness }

enum ProteinMode { basic, active, strength }

enum Intensity { light, moderate, hard }

enum MealType { breakfast, lunch, dinner, snack }

enum ProgressStatus { stable, losing, losingQuickly, gaining, gainingQuickly }

const activityFactors = {
  ActivityLevel.sedentary: 1.2,
  ActivityLevel.light: 1.375,
  ActivityLevel.moderate: 1.55,
  ActivityLevel.active: 1.725,
  ActivityLevel.veryActive: 1.9,
};

/// Mifflin-St Jeor.
double bmr({
  required Sex sex,
  required double weightKg,
  required double heightCm,
  required int age,
}) {
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return sex == Sex.male ? base + 5 : base - 161;
}

double tdee({required double bmrValue, required ActivityLevel level}) =>
    bmrValue * activityFactors[level]!;

/// 1 kg of body weight ~ 7700 kcal, so 0.5 kg/week ~ 550 kcal/day.
int calorieTarget({
  required double tdeeValue,
  required double weeklyChangeKg,
  required Sex sex,
}) {
  final daily = tdeeValue + weeklyChangeKg * 7700 / 7;
  final floor = sex == Sex.male ? 1500 : 1200;
  final rounded = (daily / 10).round() * 10;
  return rounded < floor ? floor : rounded;
}

int proteinTarget({required double weightKg, required ProteinMode mode}) {
  final coefficient = switch (mode) {
    ProteinMode.basic => 1.2,
    ProteinMode.active => 1.6,
    ProteinMode.strength => 2.0,
  };
  return (weightKg * coefficient).round();
}

double cardioKcal({
  required double met,
  required double weightKg,
  required int durationSeconds,
}) =>
    met * weightKg * (durationSeconds / 3600);

/// MET by running speed (Compendium of Physical Activities, approximated).
double runningMet(double kmh) {
  if (kmh < 6.5) return 5.0; // brisk walk / very slow jog
  if (kmh < 8.0) return 8.3;
  if (kmh < 9.0) return 9.0;
  if (kmh < 10.0) return 9.8;
  if (kmh < 11.0) return 10.5;
  if (kmh < 12.0) return 11.0;
  if (kmh < 13.0) return 11.8;
  if (kmh < 14.0) return 12.3;
  return 12.8;
}

double walkingMet(double kmh) {
  if (kmh < 3.5) return 2.8;
  if (kmh < 5.0) return 3.5;
  if (kmh < 6.0) return 4.3;
  return 5.0;
}

double cyclingMet(double kmh) {
  if (kmh < 16) return 4.0;
  if (kmh < 19) return 6.8;
  if (kmh < 22) return 8.0;
  if (kmh < 26) return 10.0;
  return 12.0;
}

double runKcal({
  required double distanceKm,
  required int durationSeconds,
  required double weightKg,
}) {
  final hours = durationSeconds / 3600;
  final kmh = hours == 0 ? 0.0 : distanceKm / hours;
  return cardioKcal(
      met: runningMet(kmh), weightKg: weightKg, durationSeconds: durationSeconds);
}

double walkKcal({
  required double distanceKm,
  required int durationSeconds,
  required double weightKg,
}) {
  final hours = durationSeconds / 3600;
  final kmh = hours == 0 ? 0.0 : distanceKm / hours;
  return cardioKcal(
      met: walkingMet(kmh), weightKg: weightKg, durationSeconds: durationSeconds);
}

double cycleKcal({
  required double distanceKm,
  required int durationSeconds,
  required double weightKg,
}) {
  final hours = durationSeconds / 3600;
  final kmh = hours == 0 ? 0.0 : distanceKm / hours;
  return cardioKcal(
      met: cyclingMet(kmh), weightKg: weightKg, durationSeconds: durationSeconds);
}

/// Fixed-MET activities (duration only).
const fixedMet = {
  'gym': 5.0,
  'jumprope': 11.0,
  'yoga': 3.0,
  'other': 4.0,
};

double intensityMet(Intensity intensity) => switch (intensity) {
      Intensity.light => 3.5,
      Intensity.moderate => 5.0,
      Intensity.hard => 7.0,
    };

double simpleWorkoutKcal({
  required Intensity intensity,
  required double weightKg,
  required int minutes,
}) =>
    intensityMet(intensity) * weightKg * (minutes / 60);

class Macros {
  const Macros({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

Macros applyPortion({
  required double calories,
  required double protein,
  required double carbs,
  required double fat,
  required double multiplier,
}) =>
    Macros(
      calories: calories * multiplier,
      protein: protein * multiplier,
      carbs: carbs * multiplier,
      fat: fat * multiplier,
    );

/// Trailing moving average with a window of 7 (averages fewer when not enough).
List<double> movingAverage(List<double> values, {int window = 7}) {
  final out = <double>[];
  for (var i = 0; i < values.length; i++) {
    final from = i - window + 1 < 0 ? 0 : i - window + 1;
    var sum = 0.0;
    for (var j = from; j <= i; j++) {
      sum += values[j];
    }
    out.add(sum / (i - from + 1));
  }
  return out;
}

double weeklyChangeKg({
  required double startWeight,
  required double endWeight,
  required DateTime start,
  required DateTime end,
}) {
  final days = end.difference(start).inDays;
  if (days <= 0) return 0;
  return (endWeight - startWeight) / days * 7;
}

ProgressStatus progressStatus(double kgPerWeek) {
  if (kgPerWeek.abs() <= 0.1) return ProgressStatus.stable;
  if (kgPerWeek < 0) {
    return kgPerWeek >= -0.75 ? ProgressStatus.losing : ProgressStatus.losingQuickly;
  }
  return kgPerWeek <= 0.75 ? ProgressStatus.gaining : ProgressStatus.gainingQuickly;
}

bool isPlateau({required double trendChange14d, required GoalType goal}) {
  if (goal == GoalType.lose) return trendChange14d > -0.2;
  if (goal == GoalType.gain) return trendChange14d < 0.2;
  return false;
}

/// Local ranking for the "Recent" list. Inputs are normalised 0..1.
double recentScore({
  required double frequency,
  required double recency,
  required double sameMealTime,
}) =>
    frequency * 0.5 + recency * 0.3 + sameMealTime * 0.2;

MealType mealTypeForHour(int hour) {
  if (hour >= 5 && hour < 10) return MealType.breakfast;
  if (hour >= 10 && hour < 14) return MealType.lunch;
  if (hour >= 17 && hour < 21) return MealType.dinner;
  return MealType.snack;
}

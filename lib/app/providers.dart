import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/calculations.dart';
import '../data/models.dart';
import '../data/repository.dart';

/// Overridden in main() after Hive is opened.
final repositoryProvider = Provider<Repository>(
  (ref) => throw UnimplementedError(),
);

/// Rebuilds dependents whenever the repository notifies.
final repoTickProvider = ChangeNotifierProvider<Repository>(
  (ref) => ref.watch(repositoryProvider),
);

final selectedDayProvider = StateProvider<String>(
  (ref) => dayKey(DateTime.now()),
);

class DaySummary {
  const DaySummary({
    required this.day,
    required this.foodLogs,
    required this.workouts,
    required this.waterMl,
    required this.weight,
    required this.goal,
    required this.settings,
  });

  final String day;
  final List<FoodLog> foodLogs;
  final List<WorkoutLog> workouts;
  final int waterMl;
  final double? weight;
  final Goal? goal;
  final AppSettings settings;

  double get eaten => foodLogs.fold(0, (s, l) => s + l.calories);
  double get protein => foodLogs.fold(0, (s, l) => s + l.protein);
  double get carbs => foodLogs.fold(0, (s, l) => s + l.carbs);
  double get fat => foodLogs.fold(0, (s, l) => s + l.fat);
  double get burned => workouts.fold(0, (s, w) => s + w.estimatedCalories);
  int get workoutMinutes =>
      workouts.fold(0, (s, w) => s + w.durationSeconds ~/ 60);

  int get targetCalories => goal?.targetCalories ?? 2000;
  int get targetProtein => goal?.targetProtein ?? 100;
  int get targetWater => goal?.targetWaterMl ?? 2500;

  double get budget =>
      targetCalories + (settings.addExerciseToBudget ? burned : 0);
  double get remaining => budget - eaten;
  double get ringProgress => budget <= 0 ? 0 : (eaten / budget).clamp(0, 1);

  List<FoodLog> logsFor(MealType t) =>
      foodLogs.where((l) => l.mealType == t).toList();
}

final daySummaryProvider = Provider.family<DaySummary, String>((ref, day) {
  final repo = ref.watch(repoTickProvider);
  final weights = repo.weights
      .where((w) => dayKey(w.timestamp).compareTo(day) <= 0)
      .toList();
  return DaySummary(
    day: day,
    foodLogs: repo.foodLogsFor(day),
    workouts: repo.workoutsFor(day),
    waterMl: repo.waterFor(day).fold(0, (s, w) => s + w.amountMl),
    weight: weights.isEmpty ? repo.profile?.weightKg : weights.last.weightKg,
    goal: repo.goal,
    settings: repo.settings,
  );
});

final todaySummaryProvider = Provider<DaySummary>(
  (ref) => ref.watch(daySummaryProvider(dayKey(DateTime.now()))),
);

/// Quick-add entries: meals and foods ranked by local score for the current hour.
class QuickEntry {
  const QuickEntry({this.meal, this.food, required this.score});
  final Meal? meal;
  final Food? food;
  final double score;
  String get name => meal?.name ?? food!.name;
  double get calories => meal?.calories ?? food!.calories;
  double get protein => meal?.protein ?? food!.protein;
  double get carbs => meal?.carbs ?? food!.carbs;
  double get fat => meal?.fat ?? food!.fat;
}

final recentEntriesProvider = Provider<List<QuickEntry>>((ref) {
  final repo = ref.watch(repoTickProvider);
  final now = DateTime.now();
  final slot = mealTypeForHour(now.hour);
  double recency(DateTime? t) {
    if (t == null) return 0;
    final days = now.difference(t).inHours / 24;
    return (1 - days / 14).clamp(0, 1);
  }

  final maxUse = [
    ...repo.meals.map((m) => m.useCount),
    ...repo.foods.map((f) => f.useCount),
    1,
  ].reduce((a, b) => a > b ? a : b);

  final out = <QuickEntry>[];
  for (final m in repo.meals) {
    if (m.useCount == 0 && m.lastUsedAt == null) {
      out.add(QuickEntry(meal: m, score: 0.05));
      continue;
    }
    final sameSlot =
        m.usedAtHours.where((h) => mealTypeForHour(h) == slot).length /
        (m.usedAtHours.isEmpty ? 1 : m.usedAtHours.length);
    out.add(
      QuickEntry(
        meal: m,
        score: recentScore(
          frequency: m.useCount / maxUse,
          recency: recency(m.lastUsedAt),
          sameMealTime: sameSlot,
        ),
      ),
    );
  }
  for (final f in repo.foods.where((f) => f.useCount > 0)) {
    out.add(
      QuickEntry(
        food: f,
        score: recentScore(
          frequency: f.useCount / maxUse,
          recency: recency(f.lastUsedAt),
          sameMealTime: 0.5,
        ),
      ),
    );
  }
  out.sort((a, b) => b.score.compareTo(a.score));
  return out;
});

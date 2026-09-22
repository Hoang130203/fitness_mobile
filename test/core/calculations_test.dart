import 'package:fitlog/core/calculations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BMR / TDEE', () {
    test('Mifflin-St Jeor male', () {
      expect(
        bmr(sex: Sex.male, weightKg: 70, heightCm: 170, age: 23),
        closeTo(10 * 70 + 6.25 * 170 - 5 * 23 + 5, 0.001),
      );
    });
    test('Mifflin-St Jeor female', () {
      expect(
        bmr(sex: Sex.female, weightKg: 60, heightCm: 165, age: 30),
        closeTo(10 * 60 + 6.25 * 165 - 5 * 30 - 161, 0.001),
      );
    });
    test('TDEE applies activity factor', () {
      expect(
        tdee(bmrValue: 1600, level: ActivityLevel.moderate),
        closeTo(1600 * 1.55, 0.001),
      );
    });
  });

  group('calorie target', () {
    test('lose 0.5 kg/week subtracts ~550 kcal', () {
      expect(
        calorieTarget(tdeeValue: 2200, weeklyChangeKg: -0.5, sex: Sex.male),
        2200 - 550,
      );
    });
    test('safety floor male 1500, female 1200', () {
      expect(
        calorieTarget(tdeeValue: 1700, weeklyChangeKg: -0.75, sex: Sex.male),
        1500,
      );
      expect(
        calorieTarget(tdeeValue: 1400, weeklyChangeKg: -0.75, sex: Sex.female),
        1200,
      );
    });
    test('maintain returns tdee rounded to 10', () {
      expect(
        calorieTarget(tdeeValue: 2204, weeklyChangeKg: 0, sex: Sex.male),
        2200,
      );
    });
  });

  test('protein target coefficients', () {
    expect(proteinTarget(weightKg: 70, mode: ProteinMode.basic), 84);
    expect(proteinTarget(weightKg: 70, mode: ProteinMode.active), 112);
    expect(proteinTarget(weightKg: 70, mode: ProteinMode.strength), 140);
  });

  group('workout kcal', () {
    test('MET formula', () {
      expect(
        cardioKcal(met: 8.3, weightKg: 70, durationSeconds: 1800),
        closeTo(290.5, 0.01),
      );
    });
    test('running MET picks from pace', () {
      // 5 km in 31:20 -> ~9.6 km/h -> MET ~9.8
      final kcal = runKcal(
        distanceKm: 5.0,
        durationSeconds: 1880,
        weightKg: 69.8,
      );
      expect(kcal, inInclusiveRange(330, 420));
    });
    test('simple workout intensity', () {
      expect(
        simpleWorkoutKcal(
          intensity: Intensity.moderate,
          weightKg: 70,
          minutes: 45,
        ),
        closeTo(5.0 * 70 * 0.75, 0.01),
      );
    });
  });

  test('portion multiplier scales kcal and macros', () {
    final m = applyPortion(
      calories: 620,
      protein: 32,
      carbs: 78,
      fat: 18,
      multiplier: 0.75,
    );
    expect(m.calories, 465);
    expect(m.protein, 24);
    expect(m.carbs, closeTo(58.5, 0.01));
    expect(m.fat, closeTo(13.5, 0.01));
  });

  group('weight trend', () {
    test('7-day moving average with fewer samples averages what exists', () {
      expect(movingAverage([70.5, 70.1, 70.8, 69.9, 70.2]), [
        70.5,
        closeTo(70.3, 0.001),
        closeTo(70.4667, 0.001),
        closeTo(70.325, 0.001),
        closeTo(70.3, 0.001),
      ]);
    });
    test('window is 7', () {
      final avg = movingAverage(List.generate(10, (i) => 70.0 - i));
      expect(avg.last, closeTo((61 + 62 + 63 + 64 + 65 + 66 + 67) / 7, 0.001));
    });
    test('weekly change from trend endpoints', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 9, 29);
      expect(
        weeklyChangeKg(startWeight: 72, endWeight: 70, start: start, end: end),
        closeTo(-0.5, 0.001),
      );
    });
  });

  group('status rules', () {
    test('thresholds', () {
      expect(progressStatus(-0.05), ProgressStatus.stable);
      expect(progressStatus(0.1), ProgressStatus.stable);
      expect(progressStatus(-0.11), ProgressStatus.losing);
      expect(progressStatus(-0.75), ProgressStatus.losing);
      expect(progressStatus(-0.76), ProgressStatus.losingQuickly);
      expect(progressStatus(0.3), ProgressStatus.gaining);
    });
    test('plateau when losing goal and 14d change > -0.2', () {
      expect(isPlateau(trendChange14d: -0.1, goal: GoalType.lose), isTrue);
      expect(isPlateau(trendChange14d: -0.5, goal: GoalType.lose), isFalse);
      expect(isPlateau(trendChange14d: -0.1, goal: GoalType.maintain), isFalse);
    });
  });

  test('recent score weights', () {
    expect(
      recentScore(frequency: 1, recency: 1, sameMealTime: 1),
      closeTo(1, 0.001),
    );
    expect(
      recentScore(frequency: 1, recency: 0, sameMealTime: 0),
      closeTo(0.5, 0.001),
    );
    expect(
      recentScore(frequency: 0, recency: 0, sameMealTime: 1),
      closeTo(0.2, 0.001),
    );
  });

  test('mealTypeForHour', () {
    expect(mealTypeForHour(7), MealType.breakfast);
    expect(mealTypeForHour(12), MealType.lunch);
    expect(mealTypeForHour(19), MealType.dinner);
    expect(mealTypeForHour(22), MealType.snack);
  });
}

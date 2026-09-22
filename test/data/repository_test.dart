import 'dart:io';

import 'package:fitlog/core/calculations.dart';
import 'package:fitlog/data/models.dart';
import 'package:fitlog/data/repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory dir;
  late Repository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fitlog_test');
    Hive.init(dir.path);
    repo = await Repository.open(
      prefix: 't${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('seed foods are present', () {
    expect(repo.foods.where((f) => f.isBuiltIn).length, greaterThan(20));
  });

  test('logging a meal snapshots macros and survives meal edits', () async {
    final meal = Meal(
      id: 'm1',
      name: 'Cơm nhà',
      items: const [],
      calories: 620,
      protein: 32,
      carbs: 78,
      fat: 18,
    );
    await repo.saveMeal(meal);
    final log = await repo.logMeal(
      meal,
      day: '2026-09-22',
      mealType: MealType.lunch,
      multiplier: 0.75,
    );
    expect(log.calories, 465);
    expect(log.protein, 24);
    expect(repo.meal('m1')!.useCount, 1);

    await repo.saveMeal(repo.meal('m1')!.copyWith(calories: 1000));
    final stored = repo.foodLogsFor('2026-09-22').single;
    expect(stored.calories, 465);
  });

  test('copyMeals copies only selected types into target day', () async {
    final f = repo.foods.first;
    await repo.logFood(f, day: '2026-09-21', mealType: MealType.lunch);
    await repo.logFood(f, day: '2026-09-21', mealType: MealType.dinner);
    final copied = await repo.copyMeals(
      fromDay: '2026-09-21',
      toDay: '2026-09-22',
      types: {MealType.lunch},
    );
    expect(copied.length, 1);
    expect(repo.foodLogsFor('2026-09-22').single.mealType, MealType.lunch);
  });

  test('saving weight updates profile current weight', () async {
    await repo.saveProfile(
      UserProfile(
        name: 'H',
        sex: Sex.male,
        birthYear: 2003,
        heightCm: 170,
        weightKg: 70.1,
        activityLevel: ActivityLevel.moderate,
      ),
    );
    await repo.saveWeight(
      WeightLog(id: 'w1', timestamp: DateTime(2026, 9, 22), weightKg: 69.8),
    );
    expect(repo.profile!.weightKg, 69.8);
    expect(repo.latestWeight!.weightKg, 69.8);
  });

  test('export/import round-trips', () async {
    await repo.addWater(250, at: DateTime(2026, 9, 22, 8));
    final json = repo.exportJsonString();
    await repo.wipe();
    expect(repo.waterFor('2026-09-22'), isEmpty);
    await repo.importJsonString(json);
    expect(repo.waterFor('2026-09-22').single.amountMl, 250);
  });
}

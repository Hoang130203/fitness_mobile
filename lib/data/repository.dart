import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import '../core/calculations.dart';
import 'models.dart';
import 'seed_foods.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

/// Single source of truth for all local data. Everything is stored as JSON maps
/// in Hive boxes so it works identically on web (IndexedDB) and mobile (files).
class Repository extends ChangeNotifier {
  Repository._(
    this._meta,
    this._foods,
    this._meals,
    this._foodLogs,
    this._workouts,
    this._presets,
    this._weights,
    this._water,
  );

  final Box<dynamic> _meta;
  final Box<dynamic> _foods;
  final Box<dynamic> _meals;
  final Box<dynamic> _foodLogs;
  final Box<dynamic> _workouts;
  final Box<dynamic> _presets;
  final Box<dynamic> _weights;
  final Box<dynamic> _water;

  static const boxNames = [
    'meta',
    'foods',
    'meals',
    'foodLogs',
    'workouts',
    'presets',
    'weights',
    'water',
  ];

  static Future<Repository> open({String prefix = 'fitlog'}) async {
    final boxes = <Box<dynamic>>[];
    for (final n in boxNames) {
      boxes.add(await Hive.openBox<dynamic>('${prefix}_$n'));
    }
    final repo = Repository._(
      boxes[0],
      boxes[1],
      boxes[2],
      boxes[3],
      boxes[4],
      boxes[5],
      boxes[6],
      boxes[7],
    );
    await repo._seed();
    return repo;
  }

  Future<void> _seed() async {
    for (final f in seedFoods) {
      if (!_foods.containsKey(f.id)) {
        await _foods.put(f.id, f.toJson());
      }
    }
  }

  // ---------------------------------------------------------------- profile

  UserProfile? get profile {
    final j = _meta.get('profile');
    return j == null ? null : UserProfile.fromJson(j as Map);
  }

  Goal? get goal {
    final j = _meta.get('goal');
    return j == null ? null : Goal.fromJson(j as Map);
  }

  AppSettings get settings {
    final j = _meta.get('settings');
    return j == null ? const AppSettings() : AppSettings.fromJson(j as Map);
  }

  Future<void> saveProfile(UserProfile p) async {
    await _meta.put('profile', p.toJson());
    notifyListeners();
  }

  Future<void> saveGoal(Goal g) async {
    await _meta.put('goal', g.toJson());
    notifyListeners();
  }

  Future<void> saveSettings(AppSettings s) async {
    await _meta.put('settings', s.toJson());
    notifyListeners();
  }

  // ------------------------------------------------------------------ foods

  List<Food> get foods =>
      _foods.values.map((e) => Food.fromJson(e as Map)).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Food? food(String id) {
    final j = _foods.get(id);
    return j == null ? null : Food.fromJson(j as Map);
  }

  Future<void> saveFood(Food f) async {
    await _foods.put(f.id, f.toJson());
    notifyListeners();
  }

  Future<void> deleteFood(String id) async {
    await _foods.delete(id);
    notifyListeners();
  }

  // ------------------------------------------------------------------ meals

  List<Meal> get meals =>
      _meals.values.map((e) => Meal.fromJson(e as Map)).toList();

  Meal? meal(String id) {
    final j = _meals.get(id);
    return j == null ? null : Meal.fromJson(j as Map);
  }

  Future<void> saveMeal(Meal m) async {
    await _meals.put(m.id, m.toJson());
    notifyListeners();
  }

  Future<void> deleteMeal(String id) async {
    await _meals.delete(id);
    notifyListeners();
  }

  // -------------------------------------------------------------- food logs

  List<FoodLog> foodLogsFor(String day) =>
      _foodLogs.values
          .map((e) => FoodLog.fromJson(e as Map))
          .where((l) => l.date == day)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<FoodLog> get allFoodLogs =>
      _foodLogs.values.map((e) => FoodLog.fromJson(e as Map)).toList();

  Future<void> saveFoodLog(FoodLog l) async {
    await _foodLogs.put(l.id, l.toJson());
    notifyListeners();
  }

  Future<void> deleteFoodLog(String id) async {
    await _foodLogs.delete(id);
    notifyListeners();
  }

  /// Logs a saved meal with a portion multiplier; snapshots macros and bumps usage.
  Future<FoodLog> logMeal(
    Meal m, {
    required String day,
    required MealType mealType,
    double multiplier = 1,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    final macros = applyPortion(
      calories: m.calories,
      protein: m.protein,
      carbs: m.carbs,
      fat: m.fat,
      multiplier: multiplier,
    );
    final log = FoodLog(
      id: newId(),
      mealId: m.id,
      name: m.name,
      date: day,
      mealType: mealType,
      portionMultiplier: multiplier,
      calories: macros.calories,
      protein: macros.protein,
      carbs: macros.carbs,
      fat: macros.fat,
      createdAt: now,
    );
    await _foodLogs.put(log.id, log.toJson());
    await _meals.put(
      m.id,
      m
          .copyWith(
            lastUsedAt: now,
            useCount: m.useCount + 1,
            usedAtHours: [...m.usedAtHours.take(29), now.hour],
          )
          .toJson(),
    );
    notifyListeners();
    return log;
  }

  Future<FoodLog> logFood(
    Food f, {
    required String day,
    required MealType mealType,
    double multiplier = 1,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    final macros = applyPortion(
      calories: f.calories,
      protein: f.protein,
      carbs: f.carbs,
      fat: f.fat,
      multiplier: multiplier,
    );
    final log = FoodLog(
      id: newId(),
      foodId: f.id,
      name: f.name,
      date: day,
      mealType: mealType,
      portionMultiplier: multiplier,
      calories: macros.calories,
      protein: macros.protein,
      carbs: macros.carbs,
      fat: macros.fat,
      createdAt: now,
    );
    await _foodLogs.put(log.id, log.toJson());
    await _foods.put(
      f.id,
      f.copyWith(lastUsedAt: now, useCount: f.useCount + 1).toJson(),
    );
    notifyListeners();
    return log;
  }

  /// Copies the given meal slots from [fromDay] into [toDay]. Returns copied logs.
  Future<List<FoodLog>> copyMeals({
    required String fromDay,
    required String toDay,
    Set<MealType>? types,
  }) async {
    final copied = <FoodLog>[];
    for (final l in foodLogsFor(fromDay)) {
      if (types != null && !types.contains(l.mealType)) continue;
      final c = l.copyWith(id: newId(), date: toDay, createdAt: DateTime.now());
      await _foodLogs.put(c.id, c.toJson());
      copied.add(c);
    }
    notifyListeners();
    return copied;
  }

  Future<void> deleteFoodLogs(Iterable<String> ids) async {
    await _foodLogs.deleteAll(ids);
    notifyListeners();
  }

  // --------------------------------------------------------------- workouts

  List<WorkoutLog> workoutsFor(String day) =>
      _workouts.values
          .map((e) => WorkoutLog.fromJson(e as Map))
          .where((l) => l.date == day)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<WorkoutLog> get allWorkouts =>
      _workouts.values.map((e) => WorkoutLog.fromJson(e as Map)).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<void> saveWorkout(WorkoutLog w) async {
    await _workouts.put(w.id, w.toJson());
    notifyListeners();
  }

  Future<void> deleteWorkout(String id) async {
    await _workouts.delete(id);
    notifyListeners();
  }

  List<WorkoutPreset> get presets =>
      _presets.values.map((e) => WorkoutPreset.fromJson(e as Map)).toList();

  Future<void> savePreset(WorkoutPreset p) async {
    await _presets.put(p.id, p.toJson());
    notifyListeners();
  }

  Future<void> deletePreset(String id) async {
    await _presets.delete(id);
    notifyListeners();
  }

  // ----------------------------------------------------------------- weight

  List<WeightLog> get weights =>
      _weights.values.map((e) => WeightLog.fromJson(e as Map)).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  WeightLog? get latestWeight => weights.isEmpty ? null : weights.last;

  Future<void> saveWeight(WeightLog w) async {
    await _weights.put(w.id, w.toJson());
    final p = profile;
    if (p != null &&
        (latestWeight == null ||
            !w.timestamp.isBefore(latestWeight!.timestamp))) {
      await _meta.put('profile', p.copyWith(weightKg: w.weightKg).toJson());
    }
    notifyListeners();
  }

  Future<void> deleteWeight(String id) async {
    await _weights.delete(id);
    notifyListeners();
  }

  // ------------------------------------------------------------------ water

  List<WaterLog> waterFor(String day) => _water.values
      .map((e) => WaterLog.fromJson(e as Map))
      .where((l) => dayKey(l.timestamp) == day)
      .toList();

  List<WaterLog> get allWater =>
      _water.values.map((e) => WaterLog.fromJson(e as Map)).toList();

  Future<void> addWater(int ml, {DateTime? at}) async {
    final w = WaterLog(
      id: newId(),
      timestamp: at ?? DateTime.now(),
      amountMl: ml,
    );
    await _water.put(w.id, w.toJson());
    notifyListeners();
  }

  Future<void> deleteWater(String id) async {
    await _water.delete(id);
    notifyListeners();
  }

  // ----------------------------------------------------------------- backup

  Map<String, dynamic> exportJson() => {
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'meta': _meta.toMap().map((k, v) => MapEntry(k.toString(), v)),
    'foods': _foods.values.toList(),
    'meals': _meals.values.toList(),
    'foodLogs': _foodLogs.values.toList(),
    'workouts': _workouts.values.toList(),
    'presets': _presets.values.toList(),
    'weights': _weights.values.toList(),
    'water': _water.values.toList(),
  };

  String exportJsonString() => jsonEncode(exportJson());

  Future<void> importJson(Map<String, dynamic> data) async {
    Future<void> load(Box<dynamic> box, String key) async {
      await box.clear();
      for (final e in (data[key] as List? ?? [])) {
        final m = Map<String, dynamic>.from(e as Map);
        await box.put(m['id'], m);
      }
    }

    await _meta.clear();
    for (final e in (data['meta'] as Map? ?? {}).entries) {
      await _meta.put(e.key, e.value);
    }
    await load(_foods, 'foods');
    await load(_meals, 'meals');
    await load(_foodLogs, 'foodLogs');
    await load(_workouts, 'workouts');
    await load(_presets, 'presets');
    await load(_weights, 'weights');
    await load(_water, 'water');
    await _seed();
    notifyListeners();
  }

  Future<void> importJsonString(String s) =>
      importJson(jsonDecode(s) as Map<String, dynamic>);

  Future<void> clearDay(String day) async {
    await _foodLogs.deleteAll(foodLogsFor(day).map((e) => e.id));
    await _workouts.deleteAll(workoutsFor(day).map((e) => e.id));
    notifyListeners();
  }

  Future<void> wipe() async {
    for (final b in [
      _meta,
      _foods,
      _meals,
      _foodLogs,
      _workouts,
      _presets,
      _weights,
      _water,
    ]) {
      await b.clear();
    }
    await _seed();
    notifyListeners();
  }
}

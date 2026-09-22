import '../core/calculations.dart';

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDayKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((e) => e.name == name, orElse: () => fallback);

double _d(Object? v, [double fallback = 0]) =>
    v == null ? fallback : (v as num).toDouble();

class UserProfile {
  UserProfile({
    required this.name,
    required this.sex,
    required this.birthYear,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String name;
  final Sex sex;
  final int birthYear;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final DateTime createdAt;

  int get age => DateTime.now().year - birthYear;

  UserProfile copyWith({
    String? name,
    Sex? sex,
    int? birthYear,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
  }) =>
      UserProfile(
        name: name ?? this.name,
        sex: sex ?? this.sex,
        birthYear: birthYear ?? this.birthYear,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'sex': sex.name,
        'birthYear': birthYear,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityLevel': activityLevel.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<dynamic, dynamic> j) => UserProfile(
        name: j['name'] as String? ?? '',
        sex: _enum(Sex.values, j['sex'], Sex.male),
        birthYear: j['birthYear'] as int? ?? 2000,
        heightCm: _d(j['heightCm'], 170),
        weightKg: _d(j['weightKg'], 70),
        activityLevel:
            _enum(ActivityLevel.values, j['activityLevel'], ActivityLevel.moderate),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}

class Goal {
  const Goal({
    required this.goalType,
    required this.targetWeightKg,
    required this.weeklyChangeKg,
    required this.targetCalories,
    required this.targetProtein,
    this.targetWaterMl = 2500,
    this.proteinMode = ProteinMode.active,
    required this.startDate,
  });

  final GoalType goalType;
  final double targetWeightKg;
  final double weeklyChangeKg;
  final int targetCalories;
  final int targetProtein;
  final int targetWaterMl;
  final ProteinMode proteinMode;
  final DateTime startDate;

  Goal copyWith({
    GoalType? goalType,
    double? targetWeightKg,
    double? weeklyChangeKg,
    int? targetCalories,
    int? targetProtein,
    int? targetWaterMl,
    ProteinMode? proteinMode,
  }) =>
      Goal(
        goalType: goalType ?? this.goalType,
        targetWeightKg: targetWeightKg ?? this.targetWeightKg,
        weeklyChangeKg: weeklyChangeKg ?? this.weeklyChangeKg,
        targetCalories: targetCalories ?? this.targetCalories,
        targetProtein: targetProtein ?? this.targetProtein,
        targetWaterMl: targetWaterMl ?? this.targetWaterMl,
        proteinMode: proteinMode ?? this.proteinMode,
        startDate: startDate,
      );

  Map<String, dynamic> toJson() => {
        'goalType': goalType.name,
        'targetWeightKg': targetWeightKg,
        'weeklyChangeKg': weeklyChangeKg,
        'targetCalories': targetCalories,
        'targetProtein': targetProtein,
        'targetWaterMl': targetWaterMl,
        'proteinMode': proteinMode.name,
        'startDate': startDate.toIso8601String(),
      };

  factory Goal.fromJson(Map<dynamic, dynamic> j) => Goal(
        goalType: _enum(GoalType.values, j['goalType'], GoalType.maintain),
        targetWeightKg: _d(j['targetWeightKg'], 70),
        weeklyChangeKg: _d(j['weeklyChangeKg']),
        targetCalories: j['targetCalories'] as int? ?? 2000,
        targetProtein: j['targetProtein'] as int? ?? 100,
        targetWaterMl: j['targetWaterMl'] as int? ?? 2500,
        proteinMode: _enum(ProteinMode.values, j['proteinMode'], ProteinMode.active),
        startDate: DateTime.tryParse(j['startDate'] as String? ?? '') ?? DateTime.now(),
      );
}

class Food {
  Food({
    required this.id,
    required this.name,
    this.servingAmount = 1,
    this.servingUnit = 'serving',
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.isFavorite = false,
    this.isBuiltIn = false,
    DateTime? createdAt,
    this.lastUsedAt,
    this.useCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final double servingAmount;
  final String servingUnit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final bool isFavorite;
  final bool isBuiltIn;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int useCount;

  Food copyWith({
    String? name,
    double? servingAmount,
    String? servingUnit,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    bool? isFavorite,
    DateTime? lastUsedAt,
    int? useCount,
  }) =>
      Food(
        id: id,
        name: name ?? this.name,
        servingAmount: servingAmount ?? this.servingAmount,
        servingUnit: servingUnit ?? this.servingUnit,
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        isFavorite: isFavorite ?? this.isFavorite,
        isBuiltIn: isBuiltIn,
        createdAt: createdAt,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
        useCount: useCount ?? this.useCount,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'servingAmount': servingAmount,
        'servingUnit': servingUnit,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'isFavorite': isFavorite,
        'isBuiltIn': isBuiltIn,
        'createdAt': createdAt.toIso8601String(),
        'lastUsedAt': lastUsedAt?.toIso8601String(),
        'useCount': useCount,
      };

  factory Food.fromJson(Map<dynamic, dynamic> j) => Food(
        id: j['id'] as String,
        name: j['name'] as String,
        servingAmount: _d(j['servingAmount'], 1),
        servingUnit: j['servingUnit'] as String? ?? 'serving',
        calories: _d(j['calories']),
        protein: _d(j['protein']),
        carbs: _d(j['carbs']),
        fat: _d(j['fat']),
        isFavorite: j['isFavorite'] as bool? ?? false,
        isBuiltIn: j['isBuiltIn'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
        lastUsedAt: DateTime.tryParse(j['lastUsedAt'] as String? ?? ''),
        useCount: j['useCount'] as int? ?? 0,
      );
}

class MealItem {
  const MealItem({required this.foodId, required this.quantity});
  final String foodId;
  final double quantity;

  Map<String, dynamic> toJson() => {'foodId': foodId, 'quantity': quantity};
  factory MealItem.fromJson(Map<dynamic, dynamic> j) =>
      MealItem(foodId: j['foodId'] as String, quantity: _d(j['quantity'], 1));
}

class Meal {
  Meal({
    required this.id,
    required this.name,
    this.mealType,
    required this.items,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.lastUsedAt,
    this.useCount = 0,
    this.usedAtHours = const [],
  });

  final String id;
  final String name;
  final MealType? mealType;
  final List<MealItem> items;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime? lastUsedAt;
  final int useCount;
  final List<int> usedAtHours;

  Meal copyWith({
    String? name,
    MealType? mealType,
    List<MealItem>? items,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? lastUsedAt,
    int? useCount,
    List<int>? usedAtHours,
  }) =>
      Meal(
        id: id,
        name: name ?? this.name,
        mealType: mealType ?? this.mealType,
        items: items ?? this.items,
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
        useCount: useCount ?? this.useCount,
        usedAtHours: usedAtHours ?? this.usedAtHours,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mealType': mealType?.name,
        'items': items.map((e) => e.toJson()).toList(),
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'lastUsedAt': lastUsedAt?.toIso8601String(),
        'useCount': useCount,
        'usedAtHours': usedAtHours,
      };

  factory Meal.fromJson(Map<dynamic, dynamic> j) => Meal(
        id: j['id'] as String,
        name: j['name'] as String,
        mealType: j['mealType'] == null
            ? null
            : _enum(MealType.values, j['mealType'], MealType.lunch),
        items: (j['items'] as List? ?? [])
            .map((e) => MealItem.fromJson(e as Map))
            .toList(),
        calories: _d(j['calories']),
        protein: _d(j['protein']),
        carbs: _d(j['carbs']),
        fat: _d(j['fat']),
        lastUsedAt: DateTime.tryParse(j['lastUsedAt'] as String? ?? ''),
        useCount: j['useCount'] as int? ?? 0,
        usedAtHours: (j['usedAtHours'] as List? ?? []).cast<int>(),
      );
}

/// Snapshot of what was eaten. Macros are copied, never referenced.
class FoodLog {
  FoodLog({
    required this.id,
    this.foodId,
    this.mealId,
    required this.name,
    required this.date,
    required this.mealType,
    this.portionMultiplier = 1,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String? foodId;
  final String? mealId;
  final String name;
  final String date;
  final MealType mealType;
  final double portionMultiplier;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime createdAt;

  FoodLog copyWith({
    String? id,
    String? name,
    String? date,
    MealType? mealType,
    double? portionMultiplier,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? createdAt,
  }) =>
      FoodLog(
        id: id ?? this.id,
        foodId: foodId,
        mealId: mealId,
        name: name ?? this.name,
        date: date ?? this.date,
        mealType: mealType ?? this.mealType,
        portionMultiplier: portionMultiplier ?? this.portionMultiplier,
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'foodId': foodId,
        'mealId': mealId,
        'name': name,
        'date': date,
        'mealType': mealType.name,
        'portionMultiplier': portionMultiplier,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FoodLog.fromJson(Map<dynamic, dynamic> j) => FoodLog(
        id: j['id'] as String,
        foodId: j['foodId'] as String?,
        mealId: j['mealId'] as String?,
        name: j['name'] as String,
        date: j['date'] as String,
        mealType: _enum(MealType.values, j['mealType'], MealType.snack),
        portionMultiplier: _d(j['portionMultiplier'], 1),
        calories: _d(j['calories']),
        protein: _d(j['protein']),
        carbs: _d(j['carbs']),
        fat: _d(j['fat']),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}

enum WorkoutKind { run, walk, gym, cycling, jumprope, yoga, strength, other }

class StrengthSet {
  const StrengthSet({required this.exercise, required this.reps, this.weightKg});
  final String exercise;
  final List<int> reps;
  final double? weightKg;

  Map<String, dynamic> toJson() =>
      {'exercise': exercise, 'reps': reps, 'weightKg': weightKg};
  factory StrengthSet.fromJson(Map<dynamic, dynamic> j) => StrengthSet(
        exercise: j['exercise'] as String,
        reps: (j['reps'] as List? ?? []).cast<int>(),
        weightKg: j['weightKg'] == null ? null : _d(j['weightKg']),
      );
}

class WorkoutLog {
  WorkoutLog({
    required this.id,
    required this.kind,
    required this.date,
    required this.durationSeconds,
    this.distanceKm,
    this.intensity,
    required this.estimatedCalories,
    this.name,
    this.notes,
    this.sets = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final WorkoutKind kind;
  final String date;
  final int durationSeconds;
  final double? distanceKm;
  final Intensity? intensity;
  final double estimatedCalories;
  final String? name;
  final String? notes;
  final List<StrengthSet> sets;
  final DateTime createdAt;

  String get title => name ?? kindLabel(kind);

  static String kindLabel(WorkoutKind k) => switch (k) {
        WorkoutKind.run => 'Run',
        WorkoutKind.walk => 'Walk',
        WorkoutKind.gym => 'Gym workout',
        WorkoutKind.cycling => 'Cycling',
        WorkoutKind.jumprope => 'Jump rope',
        WorkoutKind.yoga => 'Yoga',
        WorkoutKind.strength => 'Strength',
        WorkoutKind.other => 'Other',
      };

  WorkoutLog copyWith({String? id, String? date, DateTime? createdAt}) => WorkoutLog(
        id: id ?? this.id,
        kind: kind,
        date: date ?? this.date,
        durationSeconds: durationSeconds,
        distanceKm: distanceKm,
        intensity: intensity,
        estimatedCalories: estimatedCalories,
        name: name,
        notes: notes,
        sets: sets,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'date': date,
        'durationSeconds': durationSeconds,
        'distanceKm': distanceKm,
        'intensity': intensity?.name,
        'estimatedCalories': estimatedCalories,
        'name': name,
        'notes': notes,
        'sets': sets.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory WorkoutLog.fromJson(Map<dynamic, dynamic> j) => WorkoutLog(
        id: j['id'] as String,
        kind: _enum(WorkoutKind.values, j['kind'], WorkoutKind.other),
        date: j['date'] as String,
        durationSeconds: j['durationSeconds'] as int? ?? 0,
        distanceKm: j['distanceKm'] == null ? null : _d(j['distanceKm']),
        intensity: j['intensity'] == null
            ? null
            : _enum(Intensity.values, j['intensity'], Intensity.moderate),
        estimatedCalories: _d(j['estimatedCalories']),
        name: j['name'] as String?,
        notes: j['notes'] as String?,
        sets: (j['sets'] as List? ?? [])
            .map((e) => StrengthSet.fromJson(e as Map))
            .toList(),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}

class WorkoutPreset {
  const WorkoutPreset({
    required this.id,
    required this.name,
    required this.kind,
    this.exercises = const [],
    this.durationMinutes,
    this.intensity,
  });
  final String id;
  final String name;
  final WorkoutKind kind;
  final List<String> exercises;
  final int? durationMinutes;
  final Intensity? intensity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'exercises': exercises,
        'durationMinutes': durationMinutes,
        'intensity': intensity?.name,
      };
  factory WorkoutPreset.fromJson(Map<dynamic, dynamic> j) => WorkoutPreset(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: _enum(WorkoutKind.values, j['kind'], WorkoutKind.strength),
        exercises: (j['exercises'] as List? ?? []).cast<String>(),
        durationMinutes: j['durationMinutes'] as int?,
        intensity: j['intensity'] == null
            ? null
            : _enum(Intensity.values, j['intensity'], Intensity.moderate),
      );
}

class WeightLog {
  const WeightLog({required this.id, required this.timestamp, required this.weightKg});
  final String id;
  final DateTime timestamp;
  final double weightKg;

  Map<String, dynamic> toJson() =>
      {'id': id, 'timestamp': timestamp.toIso8601String(), 'weightKg': weightKg};
  factory WeightLog.fromJson(Map<dynamic, dynamic> j) => WeightLog(
        id: j['id'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        weightKg: _d(j['weightKg']),
      );
}

class WaterLog {
  const WaterLog({required this.id, required this.timestamp, required this.amountMl});
  final String id;
  final DateTime timestamp;
  final int amountMl;

  Map<String, dynamic> toJson() =>
      {'id': id, 'timestamp': timestamp.toIso8601String(), 'amountMl': amountMl};
  factory WaterLog.fromJson(Map<dynamic, dynamic> j) => WaterLog(
        id: j['id'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        amountMl: j['amountMl'] as int,
      );
}

class AppSettings {
  const AppSettings({
    this.addExerciseToBudget = false,
    this.metric = true,
    this.mealReminders = false,
    this.weightReminder = false,
    this.workoutReminder = false,
    this.waterReminder = false,
    this.onboarded = false,
    this.defaultWaterMl = 250,
  });

  final bool addExerciseToBudget;
  final bool metric;
  final bool mealReminders;
  final bool weightReminder;
  final bool workoutReminder;
  final bool waterReminder;
  final bool onboarded;
  final int defaultWaterMl;

  AppSettings copyWith({
    bool? addExerciseToBudget,
    bool? metric,
    bool? mealReminders,
    bool? weightReminder,
    bool? workoutReminder,
    bool? waterReminder,
    bool? onboarded,
    int? defaultWaterMl,
  }) =>
      AppSettings(
        addExerciseToBudget: addExerciseToBudget ?? this.addExerciseToBudget,
        metric: metric ?? this.metric,
        mealReminders: mealReminders ?? this.mealReminders,
        weightReminder: weightReminder ?? this.weightReminder,
        workoutReminder: workoutReminder ?? this.workoutReminder,
        waterReminder: waterReminder ?? this.waterReminder,
        onboarded: onboarded ?? this.onboarded,
        defaultWaterMl: defaultWaterMl ?? this.defaultWaterMl,
      );

  Map<String, dynamic> toJson() => {
        'addExerciseToBudget': addExerciseToBudget,
        'metric': metric,
        'mealReminders': mealReminders,
        'weightReminder': weightReminder,
        'workoutReminder': workoutReminder,
        'waterReminder': waterReminder,
        'onboarded': onboarded,
        'defaultWaterMl': defaultWaterMl,
      };

  factory AppSettings.fromJson(Map<dynamic, dynamic> j) => AppSettings(
        addExerciseToBudget: j['addExerciseToBudget'] as bool? ?? false,
        metric: j['metric'] as bool? ?? true,
        mealReminders: j['mealReminders'] as bool? ?? false,
        weightReminder: j['weightReminder'] as bool? ?? false,
        workoutReminder: j['workoutReminder'] as bool? ?? false,
        waterReminder: j['waterReminder'] as bool? ?? false,
        onboarded: j['onboarded'] as bool? ?? false,
        defaultWaterMl: j['defaultWaterMl'] as int? ?? 250,
      );
}

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../app/providers.dart';
import '../data/repository.dart';

/// Pushes the daily summary into platform home-screen widgets.
/// No-op on web; failures are swallowed so logging never blocks on widgets.
class WidgetService {
  static const appGroupId = 'group.com.hoang.fitlog';
  static const androidWidgetName = 'FitlogWidgetProvider';
  static const iOSWidgetName = 'FitlogWidget';

  static Future<void> sync(Repository repo) async {
    if (kIsWeb || !(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }
    try {
      final s = DaySummary(
        day: dayKeyNow(),
        foodLogs: repo.foodLogsFor(dayKeyNow()),
        workouts: repo.workoutsFor(dayKeyNow()),
        waterMl:
            repo.waterFor(dayKeyNow()).fold(0, (sum, w) => sum + w.amountMl),
        weight: repo.latestWeight?.weightKg ?? repo.profile?.weightKg,
        goal: repo.goal,
        settings: repo.settings,
      );
      final data = <String, String>{
        'caloriesLeft': s.remaining.round().toString(),
        'caloriesEaten': s.eaten.round().toString(),
        'caloriesBudget': s.budget.round().toString(),
        'ringProgress': (s.ringProgress * 100).round().toString(),
        'protein': s.protein.round().toString(),
        'proteinTarget': s.targetProtein.toString(),
        'burned': s.burned.round().toString(),
        'waterMl': s.waterMl.toString(),
        'waterTargetMl': s.targetWater.toString(),
        'weight': s.weight?.toStringAsFixed(1) ?? '—',
        'workouts': s.workouts.length.toString(),
      };
      for (final e in data.entries) {
        await HomeWidget.saveWidgetData<String>(e.key, e.value);
      }
      await HomeWidget.updateWidget(
          androidName: androidWidgetName, iOSName: iOSWidgetName);
    } catch (_) {}
  }
}

String dayKeyNow() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

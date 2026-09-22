import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../core/calculations.dart';
import '../data/models.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import 'widgets.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  String _goalLabel(GoalType g) => switch (g) {
    GoalType.lose => 'Lose weight',
    GoalType.maintain => 'Maintain weight',
    GoalType.gain => 'Gain weight',
    GoalType.fitness => 'Improve fitness',
  };

  String _activityLabel(ActivityLevel a) => switch (a) {
    ActivityLevel.sedentary => 'Mostly sitting',
    ActivityLevel.light => 'Some walking',
    ActivityLevel.moderate => 'Exercise 3–4 days/week',
    ActivityLevel.active => 'Exercise almost daily',
    ActivityLevel.veryActive => 'Very active lifestyle',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repoTickProvider);
    final p = repo.profile;
    final g = repo.goal;
    final s = repo.settings;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            Text('Me', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 10),
            const Section('Goal'),
            Card(
              child: ListTile(
                title: Text(
                  g == null ? 'Not set' : _goalLabel(g.goalType),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: g == null
                    ? const Text('Complete onboarding to set targets')
                    : Text(
                        'Target: ${g.targetWeightKg.toStringAsFixed(1)} kg · ${kcalNum(g.targetCalories.toDouble())} kcal/day · ${g.targetProtein} g protein',
                      ),
                trailing: const Icon(Icons.chevron_right, color: C.muted),
                onTap: () => context.push('/onboarding'),
              ),
            ),
            const Section('Body'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: p == null
                    ? const ListTile(title: Text('No profile yet'))
                    : Column(
                        children: [
                          _MeRow(
                            'Weight',
                            '${p.weightKg.toStringAsFixed(1)} kg',
                          ),
                          _MeRow(
                            'Height',
                            '${p.heightCm.toStringAsFixed(0)} cm',
                          ),
                          _MeRow('Age', '${p.age}'),
                          _MeRow('Sex', p.sex == Sex.male ? 'Male' : 'Female'),
                        ],
                      ),
              ),
            ),
            const Section('Activity'),
            Card(
              child: ListTile(
                title: Text(
                  p == null ? '—' : _activityLabel(p.activityLevel),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const Section('Settings'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Add exercise calories to food budget'),
                    value: s.addExerciseToBudget,
                    onChanged: (v) =>
                        repo.saveSettings(s.copyWith(addExerciseToBudget: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Metric units'),
                    value: s.metric,
                    onChanged: (v) => repo.saveSettings(s.copyWith(metric: v)),
                  ),
                ],
              ),
            ),
            const Section('Reminders', trailing: null),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Meal reminders'),
                    value: s.mealReminders,
                    onChanged: (v) =>
                        _toggle(ref, s.copyWith(mealReminders: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Weight reminder (morning)'),
                    value: s.weightReminder,
                    onChanged: (v) =>
                        _toggle(ref, s.copyWith(weightReminder: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Workout reminder (evening)'),
                    value: s.workoutReminder,
                    onChanged: (v) =>
                        _toggle(ref, s.copyWith(workoutReminder: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Water reminder (hourly)'),
                    value: s.waterReminder,
                    onChanged: (v) =>
                        _toggle(ref, s.copyWith(waterReminder: v)),
                  ),
                ],
              ),
            ),
            const Section('Backup'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.upload_outlined, color: C.lime),
                    title: const Text('Export backup (.json)'),
                    onTap: () => BackupService.exportBackup(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download_outlined, color: C.lime),
                    title: const Text('Import backup'),
                    onTap: () => BackupService.importBackup(context, ref),
                  ),
                  ListTile(
                    leading: Icon(Icons.table_chart_outlined, color: C.lime),
                    title: const Text('Export CSV (daily summary)'),
                    onTap: () => BackupService.exportCsv(context, ref),
                  ),
                ],
              ),
            ),
            const Section('About'),
            Card(
              child: ListTile(
                title: const Text('FitLog'),
                subtitle: const Text(
                  'Offline daily fitness journal.\nYour health data stays on this device. No account required.',
                ),
                trailing: Text(
                  'v0.1.0',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _confirmWipe(context, ref),
              child: const Text(
                'Erase all data',
                style: TextStyle(color: C.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(WidgetRef ref, AppSettings next) async {
    await ref.read(repositoryProvider).saveSettings(next);
    await NotificationService.instance.sync(next);
  }

  void _confirmWipe(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase all data?'),
        content: const Text('This deletes profile, logs, meals and settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(repositoryProvider).wipe();
              if (context.mounted) context.go('/onboarding');
            },
            child: const Text('Erase', style: TextStyle(color: C.red)),
          ),
        ],
      ),
    );
  }
}

class _MeRow extends StatelessWidget {
  const _MeRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text(label, style: Theme.of(context).textTheme.bodySmall),
    trailing: Text(
      value,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    ),
  );
}

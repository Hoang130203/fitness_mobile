import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../core/calculations.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'widgets.dart';

const _kinds = [
  (WorkoutKind.run, Icons.directions_run_rounded, 'Run'),
  (WorkoutKind.walk, Icons.directions_walk_rounded, 'Walk'),
  (WorkoutKind.gym, Icons.fitness_center_rounded, 'Gym'),
  (WorkoutKind.cycling, Icons.directions_bike_rounded, 'Cycling'),
  (WorkoutKind.jumprope, Icons.cable_rounded, 'Jump rope'),
  (WorkoutKind.yoga, Icons.self_improvement_rounded, 'Yoga'),
  (WorkoutKind.strength, Icons.sports_gymnastics_rounded, 'Strength'),
  (WorkoutKind.other, Icons.bolt_rounded, 'Other'),
];

class WorkoutAddScreen extends ConsumerWidget {
  const WorkoutAddScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(repoTickProvider).presets;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add workout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const Section('Popular'),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.05,
              children: _kinds
                  .map(
                    (k) => InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openForm(context, k.$1),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: C.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(k.$2, color: C.lime, size: 26),
                            const SizedBox(height: 6),
                            Text(k.$3, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (presets.isNotEmpty) ...[
              const Section('Recent / presets'),
              ...presets.map(
                (p) => _EntryTileWorkout(
                  name: p.name,
                  subtitle: [
                    WorkoutLog.kindLabel(p.kind),
                    if (p.durationMinutes != null) '${p.durationMinutes} min',
                  ].join(' · '),
                  onTap: () => _openPreset(context, p),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context, WorkoutKind kind) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => WorkoutFormScreen(kind: kind)),
      );

  void _openPreset(BuildContext context, WorkoutPreset p) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WorkoutFormScreen(kind: p.kind, preset: p),
        ),
      );
}

class _EntryTileWorkout extends StatelessWidget {
  const _EntryTileWorkout({
    required this.name,
    required this.subtitle,
    required this.onTap,
  });
  final String name;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: ListTile(
      tileColor: C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      onTap: onTap,
    ),
  );
}

class WorkoutFormScreen extends ConsumerStatefulWidget {
  const WorkoutFormScreen({super.key, required this.kind, this.preset});
  final WorkoutKind kind;
  final WorkoutPreset? preset;

  @override
  ConsumerState<WorkoutFormScreen> createState() => _WorkoutFormState();
}

class _WorkoutFormState extends ConsumerState<WorkoutFormScreen> {
  final _distance = TextEditingController();
  final _minutes = TextEditingController();
  final _seconds = TextEditingController();
  Intensity _intensity = Intensity.moderate;
  bool _detailed = false;

  /// exercise → list of set reps
  final Map<String, List<TextEditingController>> _sets = {};

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    if (p != null) {
      if (p.durationMinutes != null)
        _minutes.text = p.durationMinutes.toString();
      if (p.intensity != null) _intensity = p.intensity!;
      _detailed = p.exercises.isNotEmpty;
      for (final e in p.exercises) {
        _sets[e] = List.generate(3, (_) => TextEditingController());
      }
    }
    if (widget.kind == WorkoutKind.strength) {
      _detailed = widget.preset == null;
      if (_sets.isEmpty) {
        for (final e in const ['Exercise 1', 'Exercise 2', 'Exercise 3']) {
          _sets[e] = List.generate(3, (_) => TextEditingController());
        }
      }
    }
  }

  bool get _showsIntensity =>
      widget.kind == WorkoutKind.gym ||
      widget.kind == WorkoutKind.strength ||
      widget.kind == WorkoutKind.other;

  bool get _distanceKind =>
      widget.kind == WorkoutKind.run ||
      widget.kind == WorkoutKind.walk ||
      widget.kind == WorkoutKind.cycling;

  int get _durationSec {
    final m = int.tryParse(_minutes.text) ?? 0;
    final s = int.tryParse(_seconds.text) ?? 0;
    return m * 60 + s;
  }

  double get _estimate {
    final repo = ref.read(repositoryProvider);
    final w = repo.latestWeight?.weightKg ?? repo.profile?.weightKg ?? 70;
    final dist = double.tryParse(_distance.text) ?? 0;
    return switch (widget.kind) {
      WorkoutKind.run =>
        dist > 0 && _durationSec > 0
            ? runKcal(
                distanceKm: dist,
                durationSeconds: _durationSec,
                weightKg: w,
              )
            : cardioKcal(met: 8.3, weightKg: w, durationSeconds: _durationSec),
      WorkoutKind.walk =>
        dist > 0 && _durationSec > 0
            ? walkKcal(
                distanceKm: dist,
                durationSeconds: _durationSec,
                weightKg: w,
              )
            : cardioKcal(met: 3.5, weightKg: w, durationSeconds: _durationSec),
      WorkoutKind.cycling =>
        dist > 0 && _durationSec > 0
            ? cycleKcal(
                distanceKm: dist,
                durationSeconds: _durationSec,
                weightKg: w,
              )
            : cardioKcal(met: 6.8, weightKg: w, durationSeconds: _durationSec),
      WorkoutKind.jumprope => cardioKcal(
        met: 11,
        weightKg: w,
        durationSeconds: _durationSec,
      ),
      WorkoutKind.yoga => cardioKcal(
        met: 3.0,
        weightKg: w,
        durationSeconds: _durationSec,
      ),
      WorkoutKind.gym ||
      WorkoutKind.strength ||
      WorkoutKind.other => simpleWorkoutKcal(
        intensity: _intensity,
        weightKg: w,
        minutes: _durationSec ~/ 60,
      ),
    };
  }

  void _sameAsLastTime() {
    final repo = ref.read(repositoryProvider);
    final last = repo.allWorkouts
        .where((l) => l.kind == widget.kind)
        .lastOrNull;
    if (last == null) return;
    setState(() {
      _minutes.text = (last.durationSeconds ~/ 60).toString();
      _seconds.text = (last.durationSeconds % 60).toString();
      if (last.distanceKm != null) {
        _distance.text = last.distanceKm!.toStringAsFixed(1);
      }
      if (last.intensity != null) _intensity = last.intensity!;
      for (final s in last.sets) {
        final ctrls = _sets[s.exercise];
        if (ctrls != null) {
          for (var i = 0; i < ctrls.length && i < s.reps.length; i++) {
            ctrls[i].text = s.reps[i].toString();
          }
        }
      }
    });
  }

  Future<void> _save() async {
    final repo = ref.read(repositoryProvider);
    final sets = _detailed
        ? _sets.entries
              .map(
                (e) => StrengthSet(
                  exercise: e.key,
                  reps: e.value.map((c) => int.tryParse(c.text) ?? 0).toList(),
                ),
              )
              .toList()
        : const <StrengthSet>[];
    final log = WorkoutLog(
      id: newId(),
      kind: widget.kind,
      name: widget.preset?.name,
      date: dayKey(DateTime.now()),
      durationSeconds: _durationSec,
      distanceKm: double.tryParse(_distance.text),
      intensity: _showsIntensity && !_detailed ? _intensity : null,
      estimatedCalories: _estimate,
      sets: sets,
    );
    await repo.saveWorkout(log);

    // offer to save as preset when detailed
    if (_detailed && widget.preset == null && _sets.isNotEmpty) {
      final name = await _askPresetName();
      if (name != null && name.isNotEmpty) {
        await repo.savePreset(
          WorkoutPreset(
            id: newId(),
            name: name,
            kind: widget.kind,
            exercises: _sets.keys.toList(),
            durationMinutes: _durationSec ~/ 60,
          ),
        );
      }
    }
    HapticFeedback.lightImpact();
    if (mounted) context.pop();
  }

  Future<String?> _askPresetName() => showDialog<String>(
    context: context,
    builder: (ctx) {
      final c = TextEditingController();
      return AlertDialog(
        title: const Text('Save as preset?'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: 'Preset name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final title = widget.preset?.name ?? WorkoutLog.kindLabel(widget.kind);
    final hasLast = ref
        .watch(repoTickProvider)
        .allWorkouts
        .any((l) => l.kind == widget.kind);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            if (hasLast)
              TextButton.icon(
                onPressed: _sameAsLastTime,
                icon: const Icon(Icons.replay, size: 16),
                label: const Text('Same as last time'),
              ),
            if (_distanceKind) ...[
              TextField(
                controller: _distance,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Distance (km)'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _minutes,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Minutes'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _seconds,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Seconds'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_showsIntensity) _intensityRow(),
            if (widget.kind == WorkoutKind.strength || widget.preset != null)
              _detailedToggle(),
            if (_detailed) _setsEditor(),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(
                      'Estimated calories',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '~${kcalNum(_estimate)} kcal',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  Widget _intensityRow() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Intensity', style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 8),
      OptionChips<Intensity>(
        values: Intensity.values,
        labelOf: intensityLabel,
        selected: _intensity,
        onSelect: (v) => setState(() => _intensity = v),
      ),
      const SizedBox(height: 14),
    ],
  );

  Widget _detailedToggle() => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('Track sets & reps'),
    value: _detailed,
    onChanged: (v) => setState(() => _detailed = v),
  );

  Widget _setsEditor() => Column(
    children: [
      const SizedBox(height: 8),
      ..._sets.entries.map(
        (e) => Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.key,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    e.value.length,
                    (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: TextField(
                          controller: e.value[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Set ${i + 1}',
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      TextButton.icon(
        onPressed: () => setState(() {
          _sets['Exercise ${_sets.length + 1}'] = List.generate(
            3,
            (_) => TextEditingController(),
          );
        }),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add exercise'),
      ),
    ],
  );
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../core/calculations.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'widgets.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(todaySummaryProvider);
    final repo = ref.watch(repoTickProvider);
    final name = repo.profile?.name ?? '';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            _Header(name: name),
            const SizedBox(height: 18),
            _RingCard(summary: s),
            const SizedBox(height: 12),
            _QuickStats(summary: s),
            const Section('Today', trailing: _DayMenu()),
            _Timeline(summary: s),
            const SizedBox(height: 16),
            _QuickActions(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});
  final String name;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('E, MMM d').format(DateTime.now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting${name.isEmpty ? '' : ',\n$name'}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(date, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.push('/me'),
          icon: const Icon(Icons.settings_outlined, color: C.muted),
        ),
      ],
    );
  }
}

class _RingCard extends StatelessWidget {
  const _RingCard({required this.summary});
  final DaySummary summary;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          SizedBox(
            width: 190,
            height: 190,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: summary.ringProgress),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => CustomPaint(
                painter: _RingPainter(v),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        kcalNum(summary.remaining),
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      Text(
                        'kcal left',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${kcalNum(summary.eaten)} / ${kcalNum(summary.budget)}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: C.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InlineStat('Eaten', '${kcalNum(summary.eaten)} kcal'),
              Container(
                width: 1,
                height: 26,
                color: C.faint,
                margin: const EdgeInsets.symmetric(horizontal: 28),
              ),
              _InlineStat('Burned', '${kcalNum(summary.burned)} kcal'),
            ],
          ),
        ],
      ),
    ),
  );
}

class _InlineStat extends StatelessWidget {
  const _InlineStat(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 10;
    final track = Paint()
      ..color = C.faint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = C.lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 2,
      false,
      track,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.summary});
  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final cards = <Widget>[
      StatCard(
        value: '${s.protein.round()} / ${s.targetProtein}',
        suffix: 'g',
        label: 'Protein',
      ),
      StatCard(value: kcalNum(s.burned), suffix: 'kcal', label: 'Activity'),
      StatCard(
        value: s.weight == null ? '—' : s.weight!.toStringAsFixed(1),
        suffix: 'kg',
        label: 'Weight',
      ),
      StatCard(
        value:
            '${(s.waterMl / 1000).toStringAsFixed(1)} / ${(s.targetWater / 1000).toStringAsFixed(1)}',
        suffix: 'L',
        label: 'Water',
      ),
      StatCard(value: s.carbs.round().toString(), suffix: 'g', label: 'Carbs'),
      StatCard(value: s.fat.round().toString(), suffix: 'g', label: 'Fat'),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => SizedBox(width: 128, child: cards[i]),
      ),
    );
  }
}

class _DayMenu extends ConsumerWidget {
  const _DayMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) => PopupMenuButton<String>(
    icon: const Icon(Icons.more_horiz, color: C.muted),
    color: C.raised,
    onSelected: (v) async {
      final repo = ref.read(repositoryProvider);
      final today = dayKey(DateTime.now());
      switch (v) {
        case 'copy':
          final yesterday = dayKey(
            DateTime.now().subtract(const Duration(days: 1)),
          );
          final n = await repo.copyMeals(fromDay: yesterday, toDay: today);
          if (context.mounted) {
            hapticSnack(
              context,
              n.isEmpty
                  ? 'Nothing logged yesterday'
                  : '${n.length} items copied from yesterday',
            );
          }
        case 'clear':
          await repo.clearDay(today);
          if (context.mounted) hapticSnack(context, 'Today cleared');
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'copy', child: Text('Copy yesterday')),
      PopupMenuItem(value: 'clear', child: Text('Clear today')),
    ],
  );
}

class _Timeline extends ConsumerWidget {
  const _Timeline({required this.summary});
  final DaySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = summary;
    final items = <Widget>[];
    for (final t in MealType.values) {
      final logs = s.logsFor(t);
      if (logs.isEmpty) continue;
      items.add(_MealGroup(type: t, logs: logs));
    }
    if (s.workouts.isEmpty && s.foodLogs.isEmpty) {
      return const EmptyHint('Nothing logged yet — tap + to add');
    }
    for (final w in s.workouts) {
      items.add(_WorkoutTile(workout: w));
    }
    return Column(children: items);
  }
}

class _MealGroup extends ConsumerWidget {
  const _MealGroup({required this.type, required this.logs});
  final MealType type;
  final List<FoodLog> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repositoryProvider);
    final total = logs.fold(0.0, (sum, l) => sum + l.calories);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  mealLabel(type).toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              TextButton(
                onPressed: () async {
                  final yesterday = dayKey(
                    DateTime.now().subtract(const Duration(days: 1)),
                  );
                  final n = await repo.copyMeals(
                    fromDay: yesterday,
                    toDay: dayKey(DateTime.now()),
                    types: {type},
                  );
                  if (context.mounted) {
                    hapticSnack(
                      context,
                      n.isEmpty
                          ? 'No ${mealLabel(type).toLowerCase()} yesterday'
                          : '${mealLabel(type)} copied',
                    );
                  }
                },
                child: const Text(
                  '↻ same as yesterday',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Text(
                '${kcalNum(total)} kcal',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        ...logs.map((l) => _FoodTile(log: l)),
      ],
    );
  }
}

class _FoodTile extends ConsumerWidget {
  const _FoodTile({required this.log});
  final FoodLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repositoryProvider);
    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          // swipe right → duplicate
          await repo.saveFoodLog(
            log.copyWith(id: newId(), createdAt: DateTime.now()),
          );
          if (context.mounted) hapticSnack(context, 'Duplicated');
          return false;
        }
        return true; // swipe left → delete
      },
      onDismissed: (_) async {
        await repo.deleteFoodLog(log.id);
        if (context.mounted) {
          hapticSnack(
            context,
            '${log.name} deleted',
            action: 'Undo',
            onAction: () {
              repo.saveFoodLog(log);
            },
          );
        }
      },
      background: _swipeBg(
        alignment: Alignment.centerLeft,
        icon: Icons.copy_rounded,
        color: C.blue,
        edge: Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBg(
        alignment: Alignment.centerRight,
        icon: Icons.delete_outline,
        color: C.red,
        edge: Alignment.centerRight,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        dense: true,
        title: Text(log.name, style: const TextStyle(fontSize: 15)),
        subtitle: Text(
          '${log.portionMultiplier == 1 ? '' : '${log.portionMultiplier}× · '}${DateFormat('HH:mm').format(log.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          '${kcalNum(log.calories)}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        onLongPress: () async {
          // save as preset meal
          await repo.saveMeal(
            Meal(
              id: newId(),
              name: log.name,
              mealType: log.mealType,
              items: const [],
              calories: log.calories,
              protein: log.protein,
              carbs: log.carbs,
              fat: log.fat,
            ),
          );
          if (context.mounted) hapticSnack(context, 'Saved as meal');
        },
      ),
    );
  }

  static Widget _swipeBg({
    required Alignment alignment,
    required IconData icon,
    required Color color,
    required Alignment edge,
  }) => Container(
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: color),
  );
}

class _WorkoutTile extends ConsumerWidget {
  const _WorkoutTile({required this.workout});
  final WorkoutLog workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = workout;
    final mins = w.durationSeconds ~/ 60;
    final detail = [
      if (w.distanceKm != null) '${w.distanceKm!.toStringAsFixed(1)} km',
      if (mins > 0) '${mins} min',
      if (w.intensity != null) intensityLabel(w.intensity!),
    ].join(' · ');
    return Dismissible(
      key: ValueKey(w.id),
      direction: DismissDirection.endToStart,
      background: _FoodTile._swipeBg(
        alignment: Alignment.centerRight,
        icon: Icons.delete_outline,
        color: C.red,
        edge: Alignment.centerRight,
      ),
      onDismissed: (_) => ref.read(repositoryProvider).deleteWorkout(w.id),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        dense: true,
        leading: const Icon(
          Icons.fitness_center_rounded,
          color: C.lime,
          size: 20,
        ),
        title: Text(
          w.title.toUpperCase(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(detail, style: Theme.of(context).textTheme.bodySmall),
        trailing: Text(
          '−${kcalNum(w.estimatedCalories)}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: C.orange,
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(todaySummaryProvider);
    final repo = ref.read(repositoryProvider);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SlimButton(
                '+ ${repo.settings.defaultWaterMl} ml',
                icon: Icons.water_drop_outlined,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await repo.addWater(repo.settings.defaultWaterMl);
                  if (context.mounted) {
                    hapticSnack(
                      context,
                      '+${repo.settings.defaultWaterMl} ml water',
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SlimButton(
                'Weight',
                icon: Icons.monitor_weight_outlined,
                onTap: () => context.push('/weight/add'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SlimButton(
          'Workout',
          icon: Icons.fitness_center_rounded,
          onTap: () => context.push('/workout/add'),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            'Water today: ${(s.waterMl / 1000).toStringAsFixed(1)} L',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

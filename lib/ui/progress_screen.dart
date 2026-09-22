import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../core/calculations.dart';
import '../data/models.dart';
import 'widgets.dart';

enum Range { d7, d30, m3, y1 }

extension on Range {
  int get days => switch (this) {
    Range.d7 => 7,
    Range.d30 => 30,
    Range.m3 => 92,
    Range.y1 => 365,
  };
  String get label => switch (this) {
    Range.d7 => '7D',
    Range.d30 => '30D',
    Range.m3 => '3M',
    Range.y1 => '1Y',
  };
}

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  Range _range = Range.d30;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repoTickProvider);
    final goal = repo.goal;
    final cutoff = DateTime.now().subtract(Duration(days: _range.days - 1));
    final weights = repo.weights
        .where((w) => !w.timestamp.isBefore(cutoff))
        .toList();
    final workouts = repo.allWorkouts
        .where((w) => w.createdAt.isAfter(cutoff))
        .toList();
    final logs = repo.allFoodLogs
        .where((l) => l.createdAt.isAfter(cutoff))
        .toList();

    final values = weights.map((w) => w.weightKg).toList();
    final trend = movingAverage(values);
    final change = values.length >= 2 ? values.last - values.first : 0.0;

    final kcalByDay = <String, double>{};
    for (final l in logs) {
      kcalByDay[l.date] = (kcalByDay[l.date] ?? 0) + l.calories;
    }
    final avgKcal = kcalByDay.isEmpty
        ? 0.0
        : kcalByDay.values.reduce((a, b) => a + b) / kcalByDay.length;

    final proteinByDay = <String, double>{};
    for (final l in logs) {
      proteinByDay[l.date] = (proteinByDay[l.date] ?? 0) + l.protein;
    }
    final proteinHit = proteinByDay.values
        .where((p) => p >= (goal?.targetProtein ?? 100))
        .length;
    final proteinPct = proteinByDay.isEmpty
        ? 0.0
        : proteinHit / proteinByDay.length * 100;

    // plateau: 14-day trend change
    final cutoff14 = DateTime.now().subtract(const Duration(days: 13));
    final w14 = repo.weights
        .where((w) => !w.timestamp.isBefore(cutoff14))
        .toList();
    final trend14 = w14.length >= 2
        ? weeklyChangeKg(
                startWeight: w14.first.weightKg,
                endWeight: w14.last.weightKg,
                start: w14.first.timestamp,
                end: w14.last.timestamp,
              ) *
              14 /
              7
        : -1.0;
    final plateau =
        goal != null && isPlateau(trendChange14d: trend14, goal: goal.goalType);

    final kgPerWeek = w14.length >= 2
        ? weeklyChangeKg(
            startWeight: w14.first.weightKg,
            endWeight: w14.last.weightKg,
            start: w14.first.timestamp,
            end: w14.last.timestamp,
          )
        : 0.0;
    final status = progressStatus(kgPerWeek);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            Text('Progress', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 12),
            OptionChips<Range>(
              values: Range.values,
              labelOf: (r) => r.label,
              selected: _range,
              onSelect: (r) => setState(() => _range = r),
            ),
            const SizedBox(height: 18),
            _WeightCard(
              weights: weights,
              trend: trend,
              change: change,
              kgPerWeek: kgPerWeek,
              status: status,
              plateau: plateau,
              goal: goal,
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                StatCard(value: kcalNum(avgKcal), label: 'Calories avg/day'),
                StatCard(
                  value: '${workouts.length}',
                  label: 'Workout sessions',
                ),
                StatCard(
                  value:
                      '${change == 0 && values.length < 2 ? '—' : (change > 0 ? '+' : '') + change.toStringAsFixed(1)}',
                  suffix: 'kg',
                  label: 'Weight change',
                ),
                StatCard(
                  value: '${proteinPct.round()}%',
                  label: 'Protein goal days',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({
    required this.weights,
    required this.trend,
    required this.change,
    required this.kgPerWeek,
    required this.status,
    required this.plateau,
    required this.goal,
  });
  final List<WeightLog> weights;
  final List<double> trend;
  final double change;
  final double kgPerWeek;
  final ProgressStatus status;
  final bool plateau;
  final Goal? goal;

  String get statusText => switch (status) {
    ProgressStatus.stable => 'STABLE',
    ProgressStatus.losing => 'LOSING',
    ProgressStatus.losingQuickly => 'LOSING QUICKLY',
    ProgressStatus.gaining => 'GAINING',
    ProgressStatus.gainingQuickly => 'GAINING QUICKLY',
  };

  @override
  Widget build(BuildContext context) {
    final latest = weights.isEmpty ? null : weights.last.weightKg;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Weight',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: plateau
                        ? C.orange.withValues(alpha: 0.15)
                        : C.lime.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    plateau ? 'PLATEAU' : statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: plateau ? C.orange : C.lime,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  latest == null ? '—' : latest.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'kg',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    weights.length < 2
                        ? 'log more entries for trends'
                        : '${change > 0 ? '↑' : '↓'} ${change.abs().toStringAsFixed(1)} kg · ${kgPerWeek.toStringAsFixed(2)} kg/week',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (trend.length >= 2)
              SizedBox(height: 150, child: _chart())
            else
              const EmptyHint('Log weight a few days to see your trend'),
            if (plateau) ...[
              const SizedBox(height: 8),
              Text(
                'Weight has been stable for around 2 weeks — review your calorie target.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chart() {
    final spots = <FlSpot>[
      for (var i = 0; i < trend.length; i++) FlSpot(i.toDouble(), trend[i]),
    ];
    final min = trend.reduce((a, b) => a < b ? a : b) - 0.5;
    final max = trend.reduce((a, b) => a > b ? a : b) + 0.5;
    return LineChart(
      LineChartData(
        minY: min,
        maxY: max,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: C.lime,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: C.lime.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

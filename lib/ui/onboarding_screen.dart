import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../core/calculations.dart';
import '../data/models.dart';
import 'widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String _name = '';
  Sex _sex = Sex.male;
  int _birthYear = 2000;
  double _height = 170;
  double _weight = 70;
  ActivityLevel _activity = ActivityLevel.moderate;
  GoalType _goal = GoalType.lose;
  double _weeklyChange = -0.5;
  double _targetWeight = 65;
  ProteinMode _proteinMode = ProteinMode.active;

  int get _calories {
    final b = bmr(
      sex: _sex,
      weightKg: _weight,
      heightCm: _height,
      age: DateTime.now().year - _birthYear,
    );
    final t = tdee(bmrValue: b, level: _activity);
    final weekly = _goal == GoalType.maintain || _goal == GoalType.fitness
        ? 0.0
        : _weeklyChange;
    return calorieTarget(tdeeValue: t, weeklyChangeKg: weekly, sex: _sex);
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _goalStep,
      _paceStep,
      _bodyStep,
      _activityStep,
      _summaryStep,
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              _Dots(count: steps.length, index: _step),
              Expanded(child: steps[_step]()),
              Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 52),
                    ),
                    child: Text(
                      _step == steps.length - 1 ? 'Get started' : 'Next',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _next() async {
    if (_step < 4) {
      setState(() => _step++);
      return;
    }
    final repo = ref.read(repositoryProvider);
    await repo.saveProfile(
      UserProfile(
        name: _name.trim(),
        sex: _sex,
        birthYear: _birthYear,
        heightCm: _height,
        weightKg: _weight,
        activityLevel: _activity,
      ),
    );
    await repo.saveGoal(
      Goal(
        goalType: _goal,
        targetWeightKg: _goal == GoalType.maintain ? _weight : _targetWeight,
        weeklyChangeKg: _goal == GoalType.maintain || _goal == GoalType.fitness
            ? 0
            : _weeklyChange,
        targetCalories: _calories,
        targetProtein: proteinTarget(weightKg: _weight, mode: _proteinMode),
        targetWaterMl: 2500,
        proteinMode: _proteinMode,
        startDate: DateTime.now(),
      ),
    );
    await repo.saveSettings(repo.settings.copyWith(onboarded: true));
    if (mounted) context.go('/');
  }

  Widget _goalStep() => _StepView(
    title: "What's your goal?",
    child: Column(
      children: [
        _PickTile(
          'Lose weight',
          _goal == GoalType.lose,
          () => setState(() => _goal = GoalType.lose),
        ),
        _PickTile(
          'Maintain weight',
          _goal == GoalType.maintain,
          () => setState(() => _goal = GoalType.maintain),
        ),
        _PickTile(
          'Gain weight',
          _goal == GoalType.gain,
          () => setState(() => _goal = GoalType.gain),
        ),
        _PickTile(
          'Improve fitness',
          _goal == GoalType.fitness,
          () => setState(() => _goal = GoalType.fitness),
        ),
      ],
    ),
  );

  Widget _paceStep() {
    if (_goal == GoalType.maintain || _goal == GoalType.fitness) {
      return _StepView(
        title: 'Target',
        child: Column(
          children: [
            Text(
              'Maintain around your current weight and build habits.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            _NumberRow('Weekly change', '0 kg/week'),
          ],
        ),
      );
    }
    final losing = _goal == GoalType.lose;
    final options = losing
        ? [
            (-0.25, 'Slow', '−0.25 kg/week'),
            (-0.5, 'Moderate', '−0.5 kg/week'),
            (-0.75, 'Fast', '−0.75 kg/week'),
          ]
        : [
            (0.25, 'Slow', '+0.25 kg/week'),
            (0.5, 'Moderate', '+0.5 kg/week'),
            (0.75, 'Fast', '+0.75 kg/week'),
          ];
    return _StepView(
      title: 'Weekly target',
      child: Column(
        children: [
          TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Target weight (kg)'),
            onChanged: (v) =>
                _targetWeight = double.tryParse(v) ?? _targetWeight,
          ),
          const SizedBox(height: 16),
          ...options.map(
            (o) => _PickTile(
              '${o.$2}  ·  ${o.$3}',
              _weeklyChange == o.$1,
              () => setState(() => _weeklyChange = o.$1),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '≈ ${_calories} kcal/day',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _bodyStep() => _StepView(
    title: 'About you',
    child: Column(
      children: [
        TextField(
          decoration: const InputDecoration(labelText: 'Name (optional)'),
          onChanged: (v) => _name = v,
        ),
        const SizedBox(height: 10),
        OptionChips<Sex>(
          values: Sex.values,
          labelOf: (s) => s == Sex.male ? 'Male' : 'Female',
          selected: _sex,
          onSelect: (v) => setState(() => _sex = v),
        ),
        const SizedBox(height: 14),
        _SliderRow(
          'Height',
          '${_height.round()} cm',
          _height,
          140,
          210,
          (v) => setState(() => _height = v),
        ),
        _SliderRow(
          'Weight',
          '${_weight.toStringAsFixed(1)} kg',
          _weight,
          40,
          160,
          (v) => setState(() => _weight = v),
        ),
        _SliderRow(
          'Birth year',
          '$_birthYear',
          _birthYear.toDouble(),
          1950,
          2015,
          (v) => setState(() => _birthYear = v.round()),
        ),
        const SizedBox(height: 8),
        Text(
          'Your health data stays on this device.\nNo account required.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );

  Widget _activityStep() => _StepView(
    title: 'How active are you?',
    child: Column(
      children: [
        _PickTile(
          'Mostly sitting',
          _activity == ActivityLevel.sedentary,
          () => setState(() => _activity = ActivityLevel.sedentary),
        ),
        _PickTile(
          'Some walking',
          _activity == ActivityLevel.light,
          () => setState(() => _activity = ActivityLevel.light),
        ),
        _PickTile(
          'Exercise 3–4 days/week',
          _activity == ActivityLevel.moderate,
          () => setState(() => _activity = ActivityLevel.moderate),
        ),
        _PickTile(
          'Exercise almost daily',
          _activity == ActivityLevel.active,
          () => setState(() => _activity = ActivityLevel.active),
        ),
        _PickTile(
          'Very active lifestyle',
          _activity == ActivityLevel.veryActive,
          () => setState(() => _activity = ActivityLevel.veryActive),
        ),
      ],
    ),
  );

  Widget _summaryStep() => _StepView(
    title: 'Your daily targets',
    child: Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(
                  '${kcalNum(_calories.toDouble())} kcal',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                Text('per day', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SummaryStat(
                      '${proteinTarget(weightKg: _weight, mode: _proteinMode)} g',
                      'Protein',
                    ),
                    _SummaryStat(
                      '${(2500 / 1000).toStringAsFixed(1)} L',
                      'Water',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Protein style', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        OptionChips<ProteinMode>(
          values: ProteinMode.values,
          labelOf: (m) => switch (m) {
            ProteinMode.basic => 'Basic',
            ProteinMode.active => 'Active',
            ProteinMode.strength => 'Strength',
          },
          selected: _proteinMode,
          onSelect: (v) => setState(() => _proteinMode = v),
        ),
      ],
    ),
  );
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class _StepView extends StatelessWidget {
  const _StepView({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const SizedBox(height: 20),
      Text(title, style: Theme.of(context).textTheme.displayMedium),
      const SizedBox(height: 20),
      child,
    ],
  );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      count,
      (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: i == index ? 22 : 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: i <= index ? C.lime : C.faint,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
  );
}

class _PickTile extends StatelessWidget {
  const _PickTile(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? C.raised : C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? C.lime : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: selected ? C.lime : C.text,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: C.lime, size: 20),
          ],
        ),
      ),
    ),
  );
}

class _SliderRow extends StatelessWidget {
  const _SliderRow(
    this.label,
    this.value,
    this.v,
    this.min,
    this.max,
    this.onChange,
  );
  final String label;
  final String value;
  final double v;
  final double min;
  final double max;
  final ValueChanged<double> onChange;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
      Slider(
        value: v.clamp(min, max),
        min: min,
        max: max,
        activeColor: C.lime,
        inactiveColor: C.faint,
        onChanged: onChange,
      ),
    ],
  );
}

class _NumberRow extends StatelessWidget {
  const _NumberRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

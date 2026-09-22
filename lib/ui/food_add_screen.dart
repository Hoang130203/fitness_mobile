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

/// `+ → Food`. Tabs: Recent / Meals / Foods. Pick an entry → portion sheet → add.
class FoodAddScreen extends ConsumerStatefulWidget {
  const FoodAddScreen({super.key});

  @override
  ConsumerState<FoodAddScreen> createState() => _FoodAddScreenState();
}

class _FoodAddScreenState extends ConsumerState<FoodAddScreen> {
  int _tab = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repoTickProvider);
    final recents = ref.watch(recentEntriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add food'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            _Segmented(tab: _tab, onChange: (t) => setState(() => _tab = t)),
            const SizedBox(height: 14),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search foods',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 10),
            if (_tab == 0) _RecentTab(entries: recents, query: _query),
            if (_tab == 1) _MealsTab(meals: repo.meals, query: _query),
            if (_tab == 2) _FoodsTab(foods: repo.foods, query: _query),
            const SizedBox(height: 20),
            SlimButton(
              'Create meal',
              icon: Icons.lunch_dining,
              onTap: () => _createMeal(context),
            ),
            const SizedBox(height: 10),
            SlimButton(
              'Create food',
              icon: Icons.restaurant,
              onTap: () => _createFood(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createFood(BuildContext context) async {
    final food = await showAppSheet<Food>(context, const _FoodForm());
    if (food == null) return;
    await ref.read(repositoryProvider).saveFood(food);
    if (context.mounted) await _openPortion(context, _Entry(food: food));
  }

  Future<void> _createMeal(BuildContext context) async {
    final meal = await showAppSheet<Meal>(context, const _MealForm());
    if (meal == null) return;
    await ref.read(repositoryProvider).saveMeal(meal);
    if (context.mounted) await _openPortion(context, _Entry(meal: meal));
  }
}

class _Entry {
  const _Entry({this.meal, this.food});
  final Meal? meal;
  final Food? food;
  String get name => meal?.name ?? food!.name;
  double get calories => meal?.calories ?? food!.calories;
  double get protein => meal?.protein ?? food!.protein;
  double get carbs => meal?.carbs ?? food!.carbs;
  double get fat => meal?.fat ?? food!.fat;
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.tab, required this.onChange});
  final int tab;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    const labels = ['Recent', 'Meals', 'Foods'];
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChange(i),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: i == tab ? C.raised : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: i == tab ? C.lime : C.faint),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: i == tab ? C.lime : C.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.name,
    required this.calories,
    this.subtitle,
    required this.onTap,
    this.onLongPress,
  });
  final String name;
  final double calories;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${kcalNum(calories)} kcal',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

class _RecentTab extends ConsumerWidget {
  const _RecentTab({required this.entries, required this.query});
  final List<QuickEntry> entries;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = entries
        .where((e) => query.isEmpty || e.name.toLowerCase().contains(query))
        .take(12)
        .toList();
    if (list.isEmpty) {
      return const EmptyHint('Recent foods you log will show up here');
    }
    return Column(
      children: list
          .map(
            (e) => _EntryTile(
              name: e.name,
              calories: e.calories,
              onTap: () =>
                  _openPortion(context, _Entry(meal: e.meal, food: e.food)),
            ),
          )
          .toList(),
    );
  }
}

class _MealsTab extends ConsumerWidget {
  const _MealsTab({required this.meals, required this.query});
  final List<Meal> meals;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = meals
        .where((m) => query.isEmpty || m.name.toLowerCase().contains(query))
        .toList();
    if (list.isEmpty) {
      return const EmptyHint(
        'No saved meals yet — create one below or long-press a log',
      );
    }
    return Column(
      children: list
          .map(
            (m) => _EntryTile(
              name: m.name,
              calories: m.calories,
              subtitle: m.useCount > 0 ? 'used ${m.useCount}×' : null,
              onTap: () => _openPortion(context, _Entry(meal: m)),
              onLongPress: () => _confirmDelete(
                context,
                ref,
                'Delete "${m.name}"?',
                () => ref.read(repositoryProvider).deleteMeal(m.id),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FoodsTab extends ConsumerWidget {
  const _FoodsTab({required this.foods, required this.query});
  final List<Food> foods;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = foods
        .where((f) => query.isEmpty || f.name.toLowerCase().contains(query))
        .toList();
    if (list.isEmpty) return const EmptyHint('No foods match');
    return Column(
      children: list
          .map(
            (f) => _EntryTile(
              name: f.name,
              calories: f.calories,
              subtitle:
                  '${f.servingAmount.toStringAsFixed(0)} ${f.servingUnit}',
              onTap: () => _openPortion(context, _Entry(food: f)),
              onLongPress: f.isBuiltIn
                  ? null
                  : () => _confirmDelete(
                      context,
                      ref,
                      'Delete "${f.name}"?',
                      () => ref.read(repositoryProvider).deleteFood(f.id),
                    ),
            ),
          )
          .toList(),
    );
  }
}

void _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  String text,
  Future<void> Function() onOk,
) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await onOk();
          },
          child: const Text('Delete', style: TextStyle(color: C.red)),
        ),
      ],
    ),
  );
}

/// Portion sheet: Small 0.75× / Normal 1× / Large 1.25× / custom slider + meal type.
Future<void> _openPortion(BuildContext context, _Entry e) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _PortionSheet(entry: e),
  );
}

class _PortionSheet extends ConsumerStatefulWidget {
  const _PortionSheet({required this.entry});
  final _Entry entry;

  @override
  ConsumerState<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends ConsumerState<_PortionSheet> {
  double _mult = 1;
  MealType _meal =
      MealType.values[DateTime.now().hour < 10
          ? 0
          : DateTime.now().hour < 15
          ? 1
          : DateTime.now().hour < 21
          ? 2
          : 3];

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final scaled = applyPortion(
      calories: e.calories,
      protein: e.protein,
      carbs: e.carbs,
      fat: e.fat,
      multiplier: _mult,
    );
    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 6,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(e.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            kcal(scaled.calories),
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Macro('Protein', scaled.protein),
              _Macro('Carbs', scaled.carbs),
              _Macro('Fat', scaled.fat),
            ],
          ),
          const SizedBox(height: 18),
          Text('Portion', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          OptionChips<double>(
            values: const [0.75, 1, 1.25],
            labelOf: (v) => switch (v) {
              0.75 => 'Small',
              1 => 'Normal',
              _ => 'Large',
            },
            subOf: (v) => '${v}×',
            selected: _mult,
            onSelect: (v) => setState(() => _mult = v),
          ),
          Slider(
            value: _mult,
            min: 0.5,
            max: 2,
            divisions: 30,
            activeColor: C.lime,
            inactiveColor: C.faint,
            onChanged: (v) =>
                setState(() => _mult = double.parse(v.toStringAsFixed(2))),
          ),
          Text('${_mult}×', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          OptionChips<MealType>(
            values: MealType.values,
            labelOf: mealLabel,
            selected: _meal,
            onSelect: (v) => setState(() => _meal = v),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              final repo = ref.read(repositoryProvider);
              final day = dayKey(DateTime.now());
              if (e.meal != null) {
                await repo.logMeal(
                  e.meal!,
                  day: day,
                  mealType: _meal,
                  multiplier: _mult,
                );
              } else {
                await repo.logFood(
                  e.food!,
                  day: day,
                  mealType: _meal,
                  multiplier: _mult,
                );
              }
              if (context.mounted) {
                Navigator.pop(context); // close sheet
                context.pop(); // close Add food
              }
            },
            child: const Text('Add to today'),
          ),
        ],
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro(this.label, this.value);
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        grams(value),
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

/// Minimal custom-food form: name + calories required, macros optional.
class _FoodForm extends StatefulWidget {
  const _FoodForm();

  @override
  State<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends State<_FoodForm> {
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _p = TextEditingController();
  final _c = TextEditingController();
  final _f = TextEditingController();
  final _serving = TextEditingController(text: '1');
  final _unit = TextEditingController(text: 'serving');

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('New food', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
      TextField(
        controller: _name,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _kcal,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calories'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _serving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Serving'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _unit,
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: _num(_p, 'Protein g')),
          const SizedBox(width: 8),
          Expanded(child: _num(_c, 'Carbs g')),
          const SizedBox(width: 8),
          Expanded(child: _num(_f, 'Fat g')),
        ],
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () {
          final kc = double.tryParse(_kcal.text);
          if (_name.text.trim().isEmpty || kc == null) return;
          Navigator.pop(
            context,
            Food(
              id: newId(),
              name: _name.text.trim(),
              calories: kc,
              protein: double.tryParse(_p.text) ?? 0,
              carbs: double.tryParse(_c.text) ?? 0,
              fat: double.tryParse(_f.text) ?? 0,
              servingAmount: double.tryParse(_serving.text) ?? 1,
              servingUnit: _unit.text.trim().isEmpty
                  ? 'serving'
                  : _unit.text.trim(),
            ),
          );
        },
        child: const Text('Save food'),
      ),
    ],
  );

  Widget _num(TextEditingController c, String label) => TextField(
    controller: c,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label),
  );
}

/// Meal = name + optional meal type + macro totals (entered or summed by user).
class _MealForm extends StatefulWidget {
  const _MealForm();

  @override
  State<_MealForm> createState() => _MealFormState();
}

class _MealFormState extends State<_MealForm> {
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _p = TextEditingController();
  final _c = TextEditingController();
  final _f = TextEditingController();
  MealType _type = MealType.lunch;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('New meal', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
      TextField(
        controller: _name,
        decoration: const InputDecoration(labelText: 'Name (e.g. Cơm nhà)'),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _kcal,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Total calories'),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: _num(_p, 'Protein g')),
          const SizedBox(width: 8),
          Expanded(child: _num(_c, 'Carbs g')),
          const SizedBox(width: 8),
          Expanded(child: _num(_f, 'Fat g')),
        ],
      ),
      const SizedBox(height: 12),
      OptionChips<MealType>(
        values: MealType.values,
        labelOf: mealLabel,
        selected: _type,
        onSelect: (v) => setState(() => _type = v),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () {
          final kc = double.tryParse(_kcal.text);
          if (_name.text.trim().isEmpty || kc == null) return;
          Navigator.pop(
            context,
            Meal(
              id: newId(),
              name: _name.text.trim(),
              mealType: _type,
              items: const [],
              calories: kc,
              protein: double.tryParse(_p.text) ?? 0,
              carbs: double.tryParse(_c.text) ?? 0,
              fat: double.tryParse(_f.text) ?? 0,
            ),
          );
        },
        child: const Text('Save meal'),
      ),
    ],
  );

  Widget _num(TextEditingController c, String label) => TextField(
    controller: c,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label),
  );
}

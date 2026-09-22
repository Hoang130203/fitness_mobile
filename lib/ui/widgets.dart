import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/theme.dart';
import '../core/calculations.dart';

final _num = NumberFormat('#,###');

String kcal(double v) => '${_num.format(v.round())} kcal';
String kcalNum(double v) => _num.format(v.round());
String grams(double v) => '${_num.format(v.round())} g';
String kg(double v) => '${v.toStringAsFixed(1)} kg';

String mealLabel(MealType t) => switch (t) {
  MealType.breakfast => 'Breakfast',
  MealType.lunch => 'Lunch',
  MealType.dinner => 'Dinner',
  MealType.snack => 'Snack',
};

String intensityLabel(Intensity i) => switch (i) {
  Intensity.light => 'Light',
  Intensity.moderate => 'Moderate',
  Intensity.hard => 'Hard',
};

class Section extends StatelessWidget {
  const Section(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.suffix,
    this.color,
  });
  final String value;
  final String label;
  final String? suffix;
  final Color? color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: color ?? C.text, fontSize: 24),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 3),
                  child: Text(
                    suffix!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

/// Row of selectable chips (portion / intensity pickers).
class OptionChips<T> extends StatelessWidget {
  const OptionChips({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onSelect,
    this.subOf,
  });
  final List<T> values;
  final String Function(T) labelOf;
  final String? Function(T)? subOf;
  final T selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) => Row(
    children: values
        .map(
          (v) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelect(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: v == selected ? C.lime : C.raised,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        labelOf(v),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: v == selected ? C.bg : C.text,
                        ),
                      ),
                      if (subOf?.call(v) != null)
                        Text(
                          subOf!(v)!,
                          style: TextStyle(
                            fontSize: 11,
                            color: v == selected
                                ? C.bg.withValues(alpha: 0.7)
                                : C.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .toList(),
  );
}

class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Center(
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    ),
  );
}

class SlimButton extends StatelessWidget {
  const SlimButton(this.label, {super.key, this.icon, required this.onTap});
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Ink(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: C.raised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? Icons.add, size: 18, color: C.lime),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

Future<T?> showAppSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: child,
      ),
    );

void hapticSnack(
  BuildContext context,
  String text, {
  String? action,
  VoidCallback? onAction,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        action: action == null
            ? null
            : SnackBarAction(label: action, onPressed: onAction ?? () {}),
      ),
    );
}

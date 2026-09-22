import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../data/repository.dart';

/// `+ → Weight`: big stepper + manual entry + delta from previous.
class WeightSheetScreen extends ConsumerStatefulWidget {
  const WeightSheetScreen({super.key});

  @override
  ConsumerState<WeightSheetScreen> createState() => _WeightSheetState();
}

class _WeightSheetState extends ConsumerState<WeightSheetScreen> {
  double? _value;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repoTickProvider);
    final previous = repo.latestWeight?.weightKg ?? repo.profile?.weightKg;
    final current = _value ?? previous ?? 70;
    return Scaffold(
      backgroundColor: C.bg.withValues(alpha: 0.5),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: C.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Weight', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepBtn(
                    icon: Icons.remove,
                    onTap: () => _bump(-0.1, current),
                  ),
                  InkWell(
                    onTap: () async {
                      final v = await _enterManually(current);
                      if (v != null) setState(() => _value = v);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Text(
                        current.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(fontSize: 56),
                      ),
                    ),
                  ),
                  _StepBtn(icon: Icons.add, onTap: () => _bump(0.1, current)),
                ],
              ),
              Text('kg', style: Theme.of(context).textTheme.bodySmall),
              if (previous != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${current - previous >= 0 ? '+' : ''}${(current - previous).toStringAsFixed(1)} kg from last entry (${previous.toStringAsFixed(1)} kg)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await repo.saveWeight(
                          WeightLog(
                            id: newId(),
                            timestamp: DateTime.now(),
                            weightKg: current,
                          ),
                        );
                        if (context.mounted) context.pop();
                      },
                      child: const Text('Save'),
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

  void _bump(double d, double current) =>
      setState(() => _value = double.parse((current + d).toStringAsFixed(1)));

  Future<double?> _enterManually(double current) => showDialog<double>(
    context: context,
    builder: (ctx) {
      final c = TextEditingController(text: current.toStringAsFixed(1));
      return AlertDialog(
        title: const Text('Enter weight'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'kg'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(c.text)),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Ink(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: C.raised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: C.lime),
    ),
  );
}

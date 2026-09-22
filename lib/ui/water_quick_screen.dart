import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import 'widgets.dart';

/// `+ → Water`: one-tap quick amounts + today's total.
class WaterQuickScreen extends ConsumerWidget {
  const WaterQuickScreen({super.key});

  static const amounts = [150, 250, 330, 500];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(todaySummaryProvider);
    final repo = ref.read(repositoryProvider);
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
              const Icon(Icons.water_drop_rounded, color: C.blue, size: 32),
              const SizedBox(height: 8),
              Text(
                '${(s.waterMl / 1000).toStringAsFixed(1)} / ${(s.targetWater / 1000).toStringAsFixed(1)} L',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              Text('today', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              Row(
                children: amounts
                    .map(
                      (a) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              await repo.addWater(a);
                              if (context.mounted) {
                                hapticSnack(context, '+$a ml');
                                context.pop();
                              }
                            },
                            child: Ink(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: C.raised,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '+$a',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: C.blue,
                                    ),
                                  ),
                                  Text(
                                    'ml',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final v = await _customAmount(context);
                    if (v != null && v > 0) {
                      await repo.addWater(v);
                      if (context.mounted) context.pop();
                    }
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Custom amount'),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<int?> _customAmount(BuildContext context) => showDialog<int>(
    context: context,
    builder: (ctx) {
      final c = TextEditingController();
      return AlertDialog(
        title: const Text('Amount (ml)'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'ml'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(c.text)),
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}

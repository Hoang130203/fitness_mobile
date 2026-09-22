import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/food_add_screen.dart';
import '../ui/me_screen.dart';
import '../ui/onboarding_screen.dart';
import '../ui/progress_screen.dart';
import '../ui/today_screen.dart';
import '../ui/water_quick_screen.dart';
import '../ui/weight_sheet_screen.dart';
import '../ui/workout_add_screen.dart';
import 'providers.dart';
import 'theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final repo = ref.watch(repositoryProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final onboarded = repo.settings.onboarded;
      final onboarding = state.matchedLocation == '/onboarding';
      if (!onboarded && !onboarding) return '/onboarding';
      if (onboarded && onboarding) return '/';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
          GoRoute(
            path: '/progress',
            builder: (_, __) => const ProgressScreen(),
          ),
          GoRoute(path: '/me', builder: (_, __) => const MeScreen()),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/food/add', builder: (_, __) => const FoodAddScreen()),
      GoRoute(
        path: '/workout/add',
        builder: (_, __) => const WorkoutAddScreen(),
      ),
      GoRoute(
        path: '/weight/add',
        builder: (_, __) => const WeightSheetScreen(),
      ),
      GoRoute(
        path: '/water/quick',
        builder: (_, __) => const WaterQuickScreen(),
      ),
    ],
  );
});

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  int _indexOf(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/progress')) return 1;
    if (loc.startsWith('/me')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexOf(context);
    return Scaffold(
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _QuickFab(),
      bottomNavigationBar: BottomAppBar(
        color: C.surface,
        height: 68,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _TabItem(
              icon: Icons.today_rounded,
              label: 'Today',
              selected: index == 0,
              onTap: () => context.go('/'),
            ),
            _TabItem(
              icon: Icons.insights_rounded,
              label: 'Progress',
              selected: index == 1,
              onTap: () => context.go('/progress'),
            ),
            const Spacer(flex: 2),
            _TabItem(
              icon: Icons.person_outline_rounded,
              label: 'Me',
              selected: index == 2,
              onTap: () => context.go('/me'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: 3,
    child: InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: selected ? C.lime : C.muted),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? C.lime : C.muted,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Center `+` button. Tap → quick-add sheet. Long press → radial menu.
class _QuickFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress: () => _showRadial(context),
    child: FloatingActionButton(
      shape: const CircleBorder(),
      backgroundColor: C.lime,
      foregroundColor: C.bg,
      elevation: 4,
      onPressed: () => _showQuickAdd(context),
      child: const Icon(Icons.add, size: 30),
    ),
  );

  static void _go(BuildContext context, String path) {
    Navigator.of(context).pop();
    context.push(path);
  }

  static void _showQuickAdd(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QuickTile(
              Icons.restaurant_rounded,
              'Food',
              () => _go(ctx, '/food/add'),
            ),
            _QuickTile(
              Icons.fitness_center_rounded,
              'Workout',
              () => _go(ctx, '/workout/add'),
            ),
            _QuickTile(
              Icons.monitor_weight_outlined,
              'Weight',
              () => _go(ctx, '/weight/add'),
            ),
            _QuickTile(
              Icons.water_drop_outlined,
              'Water',
              () => _go(ctx, '/water/quick'),
            ),
          ],
        ),
      ),
    );
  }

  /// Radial cross menu on long-press: Food top, Water left, Workout right, Weight bottom.
  static void _showRadial(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Material(
        color: Colors.transparent,
        child: Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _RadialItem(
                  top: 0,
                  left: 84,
                  icon: Icons.restaurant_rounded,
                  label: 'Food',
                  onTap: () => _go(ctx, '/food/add'),
                ),
                _RadialItem(
                  top: 100,
                  left: 0,
                  icon: Icons.water_drop_outlined,
                  label: 'Water',
                  onTap: () => _go(ctx, '/water/quick'),
                ),
                _RadialItem(
                  top: 100,
                  left: 168,
                  icon: Icons.fitness_center_rounded,
                  label: 'Workout',
                  onTap: () => _go(ctx, '/workout/add'),
                ),
                _RadialItem(
                  top: 184,
                  left: 84,
                  icon: Icons.monitor_weight_outlined,
                  label: 'Weight',
                  onTap: () => _go(ctx, '/weight/add'),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(
                      color: C.raised,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: C.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadialItem extends StatelessWidget {
  const _RadialItem({
    required this.top,
    required this.left,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final double top;
  final double left;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Positioned(
    top: top,
    left: left,
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: C.raised,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: C.lime, size: 26),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: C.text)),
        ],
      ),
    ),
  );
}

class _QuickTile extends StatelessWidget {
  const _QuickTile(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
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
          color: C.raised,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: C.lime, size: 24),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: C.muted),
          ],
        ),
      ),
    ),
  );
}

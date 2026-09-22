# FitLog MVP — Implementation Plan

Spec: offline-first "daily fitness journal + calorie tracker", 3 tabs (Today / Progress / Me),
single `+` entry point (Food / Workout / Weight / Water), saved meals with portion multipliers,
rule-based progress, home-screen widgets, local backup. No account, no network, no AI.

Execution ruling: this harness has no `run_subagent` tool, so tasks are executed inline
(superpowers:executing-plans) and end-to-end verification is delegated to the testing agent.

## Stack

- Flutter 3.47 / Dart 3.13, targets android + ios + web (web used for verification/demo).
- State: `flutter_riverpod`. Routing: `go_router` (deep links `/food/add`, `/workout/add`,
  `/weight/add`, `/water/quick`). Storage: `hive_ce` (works on web via IndexedDB, mobile via files).
- Charts: `fl_chart`. Widgets: `home_widget` (Dart side writes summary; Android AppWidget provider).
- Notifications: `flutter_local_notifications` (opt-in reminders).

## File structure

```
lib/
  main.dart                       bootstrap Hive, ProviderScope, router
  app/theme.dart                  dark theme (#0C0F0E bg, lime primary), typography
  app/router.dart                 GoRouter + deep links
  app/shell.dart                  3-tab scaffold + FAB + radial long-press menu
  core/calculations.dart          pure math: BMR, TDEE, calorie goal, protein target, MET,
                                  portion, moving average, weekly change, status, plateau, ranking
  core/formatters.dart            kcal/kg/date formatting
  data/models.dart                UserProfile, Goal, Food, Meal, MealItem, FoodLog, WorkoutLog,
                                  WeightLog, WaterLog, AppSettings (+ json)
  data/seed_foods.dart            offline base food DB
  data/repository.dart            Hive boxes, CRUD, queries by date
  data/backup.dart                export/import JSON (.fitbackup) + CSV
  state/providers.dart            repository provider, profile/goal/settings, day summary,
                                  ranking, progress stats
  features/onboarding/onboarding_screen.dart
  features/today/today_screen.dart            header, calorie ring, quick stats, timeline
  features/today/calorie_ring.dart
  features/food/add_food_screen.dart          Recent / Meals / Foods tabs
  features/food/meal_detail_sheet.dart        portion selector + Add to today
  features/food/create_food_screen.dart
  features/food/create_meal_screen.dart
  features/workout/add_workout_screen.dart    type grid + presets
  features/workout/cardio_screen.dart         run/walk/cycle: distance+duration -> MET kcal
  features/workout/simple_workout_screen.dart duration+intensity (default gym)
  features/workout/strength_screen.dart       sets/reps, same as last time
  features/weight/weight_sheet.dart
  features/water/water_sheet.dart
  features/progress/progress_screen.dart      range tabs, weight chart (trend + dots), cards, status
  features/me/me_screen.dart                  goal/body/activity/settings
  features/me/edit_profile_screen.dart
  features/me/settings_screen.dart            units, exercise-adjust toggle, reminders, backup
  widgets/widget_sync.dart                    home_widget data push
test/
  core/calculations_test.dart
  data/repository_test.dart
  features/*_test.dart                        widget tests
```

## Tasks

1. Core calculations with unit tests (TDD): `bmr`, `tdee`, `calorieTarget` (floor 1200/1500),
   `proteinTarget`, `cardioKcal(met, kg, seconds)`, `simpleWorkoutKcal(intensity, kg, minutes)`,
   `applyPortion`, `movingAverage7`, `weeklyChangeKgPerWeek`, `progressStatus`,
   `isPlateau`, `recentScore(frequency, recency, sameMealTime)`.
2. Models + repository + seed foods; repository test: add food log, query day totals, snapshot
   macros survive food edit.
3. Theme, shell, router, FAB + radial menu.
4. Today screen.
5. Add Food flow (3-tap saved meal; portion Small/Normal/Large/Custom; Create food needs only
   name+kcal; Same as yesterday; Copy yesterday; Undo snackbar).
6. Workout flow.
7. Weight / Water sheets (stepper, previous, delta; +250ml tap, long-press sizes).
8. Progress screen (7D/30D/3M/1Y, trend line, dots, status text, plateau notice, cards).
9. Onboarding (goal → target → pace → body → activity), Me, settings, backup/export.
10. Widget sync + Android widget + notifications (opt-in).
11. Widget tests, `flutter analyze`, `flutter test`, `flutter build web`, testing-agent e2e.
12. Serve build via cloudflared tunnel, screenshots, PR.

## Review focus

- Portion math and macro snapshot in FoodLog (edits to Food must not alter history).
- Remaining kcal with/without exercise adjustment.
- 7-day moving average with < 7 samples.
- Status thresholds at boundaries (−0.1, −0.75).
- Deep link routes open the target sheet directly, not Home.

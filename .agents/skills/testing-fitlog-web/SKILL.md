---
name: testing-fitlog-web
description: How to E2E-test the FitLog Flutter web app on this Windows box (serve build/web, canvas-rendering quirks, gesture simulation, expected no-ops)
---

# Testing FitLog (Flutter web) end-to-end

## Serve the app
- Prebuilt bundle lives in `build/web` (built with `flutter build web`). Serve it statically — no `flutter run` needed:
  `python -m http.server 8080 -d build/web` (python is at `/c/devin/python/python`; no `python3`).
- Flutter is at `C:\flutter\bin\flutter` (3.47.5 stable). No Android SDK / no Chrome-for-flutter on the box — use the installed desktop Chrome for UI testing.
- Routes are hash-based: `http://localhost:8080/#/` (Today), `/#/onboarding`, `/#/progress`, `/#/me`, `/#/food/add`, `/#/workout/add`, `/#/weight/add`, `/#/water/quick`.
- To get a fresh first-run (onboarding redirect), use a fresh Chrome profile or `Me → Erase all data` (or DevTools → clear IndexedDB `fitlog_*`).

## Rendering / assertions
- The app renders via Flutter canvas — `read_dom` shows only `<flutter-view>` and offscreen `<flt-text-editing-host>` inputs (the latter still reveal field text values). **Screenshot + zoom is the source of truth** for all assertions.
- Snackbars are transient (~4 s): screenshot immediately after the action.
- Expected math for verifying numbers (lib/core/calculations.dart): BMR male = `10·W + 6.25·H − 5·age + 5`; TDEE = `BMR·1.55` (moderate); lose −0.5 kg/wk ⇒ target = `round10(TDEE − 550)`; protein Active = `round(1.6·W)`; Run kcal = `speedMET·W·hours` (5 km/31 min → 9.68 km/h → MET 9.8); gym = `intensityMET·W·min/60` (light 3.5 / moderate 5 / hard 7).

## Simulating gestures with the computer tool
- **Long-press** (FAB radial menu, food tile save-as-meal): `mouse_move` to target → `left_mouse_down` → `wait 1` → `left_mouse_up`. `left_mouse_down` takes NO coordinate — move first.
- **Swipe/Dismissible**: `left_click_drag` must cover >40 % of row width or the tile snaps back with no effect. 350 px on a 1024 px window was too short; use ~550–600 px.
- **Sliders**: `left_click_drag` on the track works and updates the value live.

## Known platform no-ops (flag, don't fail)
- `Export backup (.json)` / `Export CSV` use `share_plus`/`path_provider` — silently no-op on desktop Chrome: no file, no snackbar, no console crash. Reminder toggles no-op (NotificationService has no web impl).
- App looks correct on first load; IndexedDB persistence is real (Hive `fitlog_*` boxes) — verify with F5 reload.

## Devin Secrets Needed
- None — app is fully offline/local, no accounts, no backend.
